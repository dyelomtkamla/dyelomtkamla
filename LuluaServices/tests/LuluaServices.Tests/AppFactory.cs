using System.Text.RegularExpressions;
using LuluaServices.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;

namespace LuluaServices.Tests;

/// <summary>Runs the real app in memory against a throwaway SQLite file.</summary>
public class AppFactory : WebApplicationFactory<Program>
{
    public const string BaseUrl = "https://lulua.test";
    public const string AdminPassword = "Test-Password-123";

    private readonly string _dbPath = Path.Combine(Path.GetTempPath(), $"lulua-test-{Guid.NewGuid():N}.db");

    protected virtual int FormsPerTenMinutes => 1000;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Default", $"Data Source={_dbPath}");
        builder.UseSetting("Business:BaseUrl", BaseUrl);
        builder.UseSetting("Business:WhatsApp", "966511111111");
        builder.UseSetting("Business:Phone", "0511111111");
        builder.UseSetting("Admin:Username", "admin");
        builder.UseSetting("Admin:PasswordHash", new PasswordHasher<AdminOptions>().HashPassword(new AdminOptions(), AdminPassword));
        builder.UseSetting("RateLimits:FormsPerTenMinutes", FormsPerTenMinutes.ToString());
    }

    public HttpClient Browser() => CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false, HandleCookies = true });

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
        if (File.Exists(_dbPath)) File.Delete(_dbPath);
    }

    public static string Token(string html) =>
        Regex.Match(html, "name=\"__RequestVerificationToken\" type=\"hidden\" value=\"([^\"]+)\"").Groups[1].Value;
}

public class StrictRateLimitFactory : AppFactory
{
    protected override int FormsPerTenMinutes => 2;
}
