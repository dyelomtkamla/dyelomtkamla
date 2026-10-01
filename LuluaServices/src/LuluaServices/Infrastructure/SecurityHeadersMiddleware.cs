namespace LuluaServices.Infrastructure;

/// <summary>Adds baseline security headers to every response, and keeps the dashboard out of search engines.</summary>
public class SecurityHeadersMiddleware(RequestDelegate next)
{
    private const string Csp =
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
        "font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; " +
        "manifest-src 'self'; worker-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'";

    public Task Invoke(HttpContext ctx)
    {
        var h = ctx.Response.Headers;
        h.XContentTypeOptions = "nosniff";
        h.XFrameOptions = "DENY";
        h["Referrer-Policy"] = "strict-origin-when-cross-origin";
        h["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
        h.ContentSecurityPolicy = Csp;
        if (ctx.Request.Path.StartsWithSegments("/admin"))
        {
            h["X-Robots-Tag"] = "noindex, nofollow";
            h.CacheControl = "no-store";
        }
        return next(ctx);
    }
}
