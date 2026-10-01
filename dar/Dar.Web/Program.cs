using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Unicode;
using System.Threading.RateLimiting;
using Dar.Web.Data;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages(o =>
{
    o.Conventions.AddPageRoute("/Index", "/en");
    o.Conventions.AddPageRoute("/Privacy", "/en/privacy");
});
// Emit Arabic and other scripts as-is instead of &#x...; entities (smaller HTML, readable source).
builder.Services.AddSingleton(HtmlEncoder.Create(UnicodeRanges.All));
builder.Services.AddRouting(o => o.LowercaseUrls = true);
builder.Services.AddDbContext<DarDbContext>(o =>
    o.UseSqlite(builder.Configuration.GetConnectionString("Dar") ?? "Data Source=dar.db"));
builder.Services.AddResponseCompression(o =>
{
    o.EnableForHttps = true;
    o.Providers.Add<BrotliCompressionProvider>();
    o.Providers.Add<GzipCompressionProvider>();
});
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    // Razor Pages only accept the attribute per page, so GETs are let through here and only form posts are limited.
    o.AddPolicy("waitlist", ctx => HttpMethods.IsPost(ctx.Request.Method)
        ? RateLimitPartition.GetFixedWindowLimiter(
            ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(10) })
        : RateLimitPartition.GetNoLimiter("get"));
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    scope.ServiceProvider.GetRequiredService<DarDbContext>().Database.EnsureCreated();
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseStatusCodePagesWithReExecute("/Error", "?code={0}");
app.UseResponseCompression();

app.Use(async (ctx, next) =>
{
    var h = ctx.Response.Headers;
    h["X-Content-Type-Options"] = "nosniff";
    h["X-Frame-Options"] = "DENY";
    h["Referrer-Policy"] = "strict-origin-when-cross-origin";
    h["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
    h["Content-Security-Policy"] =
        "default-src 'self'; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; " +
        "img-src 'self' data:; script-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'";
    await next();
});

app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
        ctx.Context.Response.Headers.CacheControl = "public,max-age=604800"
});

app.UseRouting();
app.UseRateLimiter();

app.MapRazorPages();

string BaseUrl(HttpRequest r) =>
    (app.Configuration["Site:BaseUrl"] is { Length: > 0 } u ? u : $"{r.Scheme}://{r.Host}").TrimEnd('/');

app.MapGet("/robots.txt", (HttpRequest r) =>
    Results.Text($"User-agent: *\nAllow: /\nDisallow: /admin/\n\nSitemap: {BaseUrl(r)}/sitemap.xml\n", "text/plain"));

app.MapGet("/sitemap.xml", (HttpRequest r) =>
{
    var b = BaseUrl(r);
    var today = DateTime.UtcNow.ToString("yyyy-MM-dd");
    string Url(string ar, string en, string priority) => $"""
          <url>
            <loc>{b}{ar}</loc><lastmod>{today}</lastmod><priority>{priority}</priority>
            <xhtml:link rel="alternate" hreflang="ar" href="{b}{ar}"/>
            <xhtml:link rel="alternate" hreflang="en" href="{b}{en}"/>
            <xhtml:link rel="alternate" hreflang="x-default" href="{b}{ar}"/>
          </url>
          <url>
            <loc>{b}{en}</loc><lastmod>{today}</lastmod><priority>{priority}</priority>
            <xhtml:link rel="alternate" hreflang="ar" href="{b}{ar}"/>
            <xhtml:link rel="alternate" hreflang="en" href="{b}{en}"/>
            <xhtml:link rel="alternate" hreflang="x-default" href="{b}{ar}"/>
          </url>
        """;
    var xml = $"""
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
        {Url("/", "/en", "1.0")}
        {Url("/privacy", "/en/privacy", "0.3")}
        </urlset>
        """;
    return Results.Text(xml, "application/xml", Encoding.UTF8);
});

// CSV export of the waitlist, protected by the Admin:Key setting (send it in the X-Admin-Key header).
app.MapGet("/admin/waitlist.csv", async (HttpRequest r, DarDbContext db) =>
{
    var key = app.Configuration["Admin:Key"];
    var given = r.Headers["X-Admin-Key"].ToString();
    if (string.IsNullOrEmpty(key) ||
        !CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(key), Encoding.UTF8.GetBytes(given)))
        return Results.NotFound();

    static string Esc(string v) => "\"" + v.Replace("\"", "\"\"") + "\"";
    var sb = new StringBuilder("id,name,contact,country,role,locale,created_utc\n");
    foreach (var e in await db.Waitlist.AsNoTracking().OrderBy(x => x.Id).ToListAsync())
        sb.AppendLine(string.Join(',', e.Id, Esc(e.Name), Esc(e.Contact), e.Country, e.Role, e.Locale, e.CreatedAtUtc.ToString("yyyy-MM-dd HH:mm:ss") + "Z"));
    return Results.File(Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray(),
        "text/csv", "dar-waitlist.csv");
});

app.Run();
