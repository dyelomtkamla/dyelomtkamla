using System.Text;
using System.Text.Encodings.Web;
using System.Text.Unicode;
using System.Threading.RateLimiting;
using LuluaServices.Data;
using LuluaServices.Infrastructure;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.WebEncoders;

// Helper for setting the dashboard password: dotnet run -- hash-password "my-password"
if (args.Length == 2 && args[0] == "hash-password")
{
    Console.WriteLine(new PasswordHasher<AdminOptions>().HashPassword(new AdminOptions(), args[1]));
    return;
}

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<BusinessOptions>(builder.Configuration.GetSection("Business"));
builder.Services.Configure<AdminOptions>(builder.Configuration.GetSection("Admin"));

var connectionString = builder.Configuration.GetConnectionString("Default") ?? "Data Source=App_Data/lulua.db";
builder.Services.AddDbContext<AppDbContext>(o => o.UseSqlite(connectionString));

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(o =>
    {
        o.LoginPath = "/admin/login";
        o.LogoutPath = "/admin/logout";
        o.AccessDeniedPath = "/admin/login";
        o.Cookie.Name = "lulua.admin";
        o.Cookie.HttpOnly = true;
        o.Cookie.SameSite = SameSiteMode.Strict;
        o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        o.ExpireTimeSpan = TimeSpan.FromHours(8);
        o.SlidingExpiration = true;
    });
builder.Services.AddAuthorization();

builder.Services.AddRazorPages(o =>
{
    o.Conventions.AuthorizeFolder("/Admin");
    o.Conventions.AllowAnonymousToPage("/Admin/Login");
});
builder.Services.Configure<RouteOptions>(o => o.LowercaseUrls = true);
// Emit Arabic as real characters instead of &#x...; entities (smaller pages, readable for crawlers).
// HTML-significant characters such as < > & " are still escaped.
builder.Services.Configure<WebEncoderOptions>(o => o.TextEncoderSettings = new TextEncoderSettings(UnicodeRanges.All));

var formsPerTenMinutes = builder.Configuration.GetValue("RateLimits:FormsPerTenMinutes", 8);
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.OnRejected = async (ctx, ct) =>
    {
        ctx.HttpContext.Response.ContentType = "text/plain; charset=utf-8";
        await ctx.HttpContext.Response.WriteAsync("عدد الطلبات كبير، فضلاً حاول بعد قليل أو تواصل معنا عبر واتساب.", ct);
    };
    // Only form submissions are limited; page views are not.
    o.AddPolicy("forms", ctx => HttpMethods.IsPost(ctx.Request.Method)
        ? RateLimitPartition.GetFixedWindowLimiter(
            (ctx.Request.Path.Value ?? "") + "|" + (ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown"),
            _ => new FixedWindowRateLimiterOptions { PermitLimit = formsPerTenMinutes, Window = TimeSpan.FromMinutes(10) })
        : RateLimitPartition.GetNoLimiter("get"));
});

builder.Services.AddResponseCompression(o =>
{
    o.EnableForHttps = true;
    o.Providers.Add<BrotliCompressionProvider>();
    o.Providers.Add<GzipCompressionProvider>();
    o.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[] { "image/svg+xml", "application/manifest+json" });
});

// Behind nginx/IIS/a load balancer, trust X-Forwarded-* so HTTPS and client IPs are correct.
// Opt-in, because trusting those headers without a proxy lets clients spoof their IP.
var behindProxy = builder.Configuration.GetValue<bool>("ReverseProxy:Enabled");
if (behindProxy)
{
    builder.Services.Configure<ForwardedHeadersOptions>(o =>
    {
        o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
        o.KnownNetworks.Clear();
        o.KnownProxies.Clear();
    });
}

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var dataSource = new Microsoft.Data.Sqlite.SqliteConnectionStringBuilder(db.Database.GetConnectionString()).DataSource;
    var dir = Path.GetDirectoryName(Path.GetFullPath(dataSource));
    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
    db.Database.EnsureCreated();
}

if (behindProxy) app.UseForwardedHeaders();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error");
    app.UseHsts();
}

app.UseStatusCodePagesWithReExecute("/not-found");
app.UseHttpsRedirection();
app.UseResponseCompression();
app.UseMiddleware<SecurityHeadersMiddleware>();

app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        var path = ctx.Context.Request.Path.Value ?? "";
        // The service worker must always be re-checked so updates reach installed apps.
        ctx.Context.Response.Headers.CacheControl = path.EndsWith("sw.js", StringComparison.Ordinal)
            ? "no-cache"
            : ctx.Context.Request.Query.ContainsKey("v") ? "public,max-age=31536000,immutable" : "public,max-age=604800";
    },
});

app.UseRouting();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapRazorPages();

app.MapGet("/sitemap.xml", (IOptions<BusinessOptions> opts) =>
{
    var b = opts.Value;
    var sb = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");
    sb.Append($"  <url><loc>{b.Url()}</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>\n");
    foreach (var s in ServiceCatalog.All)
        sb.Append($"  <url><loc>{b.Url("/" + s.Slug)}</loc><changefreq>monthly</changefreq><priority>0.8</priority></url>\n");
    sb.Append("</urlset>\n");
    return Results.Text(sb.ToString(), "application/xml; charset=utf-8");
});

app.MapGet("/robots.txt", (IOptions<BusinessOptions> opts) =>
    Results.Text($"User-agent: *\nAllow: /\nDisallow: /admin\nDisallow: /book/thanks\n\nSitemap: {opts.Value.Url("/sitemap.xml")}\n",
        "text/plain; charset=utf-8"));

app.Run();

public partial class Program;
