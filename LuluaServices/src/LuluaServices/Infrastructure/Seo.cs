using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Unicode;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Html;
using Microsoft.AspNetCore.Mvc.ViewFeatures;

namespace LuluaServices.Infrastructure;

/// <summary>Per-page SEO data rendered by _Layout: title, description, canonical, theme and JSON-LD.</summary>
public class SeoMeta
{
    public required string Title { get; init; }
    public required string Description { get; init; }

    /// <summary>Path of the canonical URL, e.g. "/cleaning".</summary>
    public string Path { get; init; } = "/";
    public string ThemeColor { get; init; } = "#0b3b4f";
    public bool NoIndex { get; init; }
    public List<object> JsonLd { get; init; } = new();
}

public static class Seo
{
    private const string Key = "__seo";

    public static void SetSeo(this ViewDataDictionary viewData, SeoMeta meta) => viewData[Key] = meta;

    public static SeoMeta GetSeo(this ViewDataDictionary viewData) =>
        viewData[Key] as SeoMeta ?? new SeoMeta { Title = "لؤلؤة المستقل", Description = "", NoIndex = true };

    // Keeps Arabic readable while still escaping <, >, & so the JSON can't break out of <script>.
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        Encoder = JavaScriptEncoder.Create(UnicodeRanges.All),
    };

    public static IHtmlContent JsonLdTag(object data) =>
        new HtmlString("<script type=\"application/ld+json\">" + JsonSerializer.Serialize(data, JsonOpts) + "</script>");

    public static object Business(BusinessOptions b) => new Dictionary<string, object>
    {
        ["@context"] = "https://schema.org",
        ["@type"] = "HomeAndConstructionBusiness",
        ["@id"] = b.Url("/#business"),
        ["name"] = b.Name,
        ["alternateName"] = b.ShortName,
        ["url"] = b.Url(),
        ["logo"] = b.Url("/img/icon-512.png"),
        ["image"] = b.Url("/img/og.png"),
        ["telephone"] = "+" + b.WhatsApp,
        ["areaServed"] = new Dictionary<string, object> { ["@type"] = "Country", ["name"] = b.Area },
        ["openingHours"] = b.OpeningHoursSchema,
        ["hasOfferCatalog"] = new Dictionary<string, object>
        {
            ["@type"] = "OfferCatalog",
            ["name"] = "الخدمات المنزلية",
            ["itemListElement"] = ServiceCatalog.All.Select(s => new Dictionary<string, object>
            {
                ["@type"] = "OfferCatalog",
                ["name"] = s.Name,
                ["url"] = b.Url("/" + s.Slug),
                ["itemListElement"] = s.Services.Select(x => Offer(x.Name, null)).ToList(),
            }).ToList(),
        },
    };

    public static object WebSite(BusinessOptions b) => new Dictionary<string, object>
    {
        ["@context"] = "https://schema.org",
        ["@type"] = "WebSite",
        ["name"] = b.Name,
        ["url"] = b.Url(),
        ["inLanguage"] = "ar",
    };

    public static object Service(BusinessOptions b, ServiceSection s) => new Dictionary<string, object>
    {
        ["@context"] = "https://schema.org",
        ["@type"] = "Service",
        ["name"] = s.Name,
        ["serviceType"] = s.Name,
        ["description"] = s.Description,
        ["url"] = b.Url("/" + s.Slug),
        ["areaServed"] = b.Area,
        ["provider"] = new Dictionary<string, object>
        {
            ["@id"] = b.Url("/#business"), ["@type"] = "HomeAndConstructionBusiness", ["name"] = b.Name,
        },
        ["hasOfferCatalog"] = new Dictionary<string, object>
        {
            ["@type"] = "OfferCatalog",
            ["name"] = s.Name,
            ["itemListElement"] = s.Services.Select(x => Offer(x.Name, x.Description)).ToList(),
        },
    };

    public static object Breadcrumbs(BusinessOptions b, ServiceSection s) => new Dictionary<string, object>
    {
        ["@context"] = "https://schema.org",
        ["@type"] = "BreadcrumbList",
        ["itemListElement"] = new object[]
        {
            new Dictionary<string, object> { ["@type"] = "ListItem", ["position"] = 1, ["name"] = b.ShortName, ["item"] = b.Url() },
            new Dictionary<string, object> { ["@type"] = "ListItem", ["position"] = 2, ["name"] = s.Name, ["item"] = b.Url("/" + s.Slug) },
        },
    };

    public static object FaqPage(IEnumerable<Faq> faqs) => new Dictionary<string, object>
    {
        ["@context"] = "https://schema.org",
        ["@type"] = "FAQPage",
        ["mainEntity"] = faqs.Select(f => new Dictionary<string, object>
        {
            ["@type"] = "Question",
            ["name"] = f.Question,
            ["acceptedAnswer"] = new Dictionary<string, object> { ["@type"] = "Answer", ["text"] = f.Answer },
        }).ToList(),
    };

    private static Dictionary<string, object> Offer(string name, string? description)
    {
        var service = new Dictionary<string, object> { ["@type"] = "Service", ["name"] = name };
        if (description is not null) service["description"] = description;
        return new Dictionary<string, object> { ["@type"] = "Offer", ["itemOffered"] = service };
    }
}
