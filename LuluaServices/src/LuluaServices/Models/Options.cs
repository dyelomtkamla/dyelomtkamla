namespace LuluaServices.Models;

/// <summary>Business identity and contact details, bound from the "Business" config section.</summary>
public class BusinessOptions
{
    public string Name { get; set; } = "مؤسسة لؤلؤة المستقل للخدمات المنزلية";
    public string ShortName { get; set; } = "لؤلؤة المستقل";

    /// <summary>Public origin used for canonical URLs, sitemap and structured data (never taken from the request).</summary>
    public string BaseUrl { get; set; } = "https://localhost";

    /// <summary>WhatsApp number in international format without "+", e.g. 9665XXXXXXXX.</summary>
    public string WhatsApp { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Area { get; set; } = "المملكة العربية السعودية";
    public string Hours { get; set; } = "يومياً من 8 صباحاً حتى 11 مساءً";
    public string OpeningHoursSchema { get; set; } = "Mo-Su 08:00-23:00";

    public string Url(string path = "/") => BaseUrl.TrimEnd('/') + path;
    public string WhatsAppLink(string text) => $"https://wa.me/{WhatsApp}?text={Uri.EscapeDataString(text)}";
}

/// <summary>Dashboard login, bound from the "Admin" config section.</summary>
public class AdminOptions
{
    public string Username { get; set; } = "admin";

    /// <summary>ASP.NET Identity PBKDF2 hash. Generate with: dotnet run -- hash-password "your-password".</summary>
    public string PasswordHash { get; set; } = "";
}
