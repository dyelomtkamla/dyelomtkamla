using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using LuluaServices.Services;

namespace LuluaServices.Tests;

public class PublicSiteTests(AppFactory factory) : IClassFixture<AppFactory>
{
    public static TheoryData<string> Slugs()
    {
        var data = new TheoryData<string>();
        foreach (var s in ServiceCatalog.All) data.Add(s.Slug);
        return data;
    }

    [Fact]
    public async Task Home_has_seo_tags_structured_data_and_links_to_every_department()
    {
        var html = await factory.Browser().GetStringAsync("/");

        Assert.Contains("<title>مؤسسة لؤلؤة المستقل للخدمات المنزلية |", html);
        Assert.Contains($"<link rel=\"canonical\" href=\"{AppFactory.BaseUrl}/\" />", html);
        Assert.Contains("<meta name=\"description\"", html);
        Assert.Contains($"{AppFactory.BaseUrl}/img/og.png", html);
        var types = JsonLdTypes(html);
        Assert.Contains("HomeAndConstructionBusiness", types);
        Assert.Contains("FAQPage", types);
        foreach (var s in ServiceCatalog.All)
            Assert.Contains($"href=\"/{s.Slug}\"", html);
    }

    [Theory]
    [MemberData(nameof(Slugs))]
    public async Task Each_department_has_its_own_indexable_page(string slug)
    {
        var section = ServiceCatalog.Find(slug)!;
        var html = await factory.Browser().GetStringAsync("/" + slug);

        Assert.Contains($"<h1>{section.Name}</h1>", html);
        Assert.Contains($"<link rel=\"canonical\" href=\"{AppFactory.BaseUrl}/{slug}\" />", html);
        Assert.Contains("index, follow", html);
        Assert.Equal(new[] { "Service", "BreadcrumbList", "FAQPage" }, JsonLdTypes(html));
        // The booking form comes pre-set to this department.
        Assert.Matches($"<option value=\"{slug}\" selected=\"selected\">", html);
    }

    [Fact]
    public async Task Mixed_case_department_url_redirects_to_the_canonical_one()
    {
        var res = await factory.Browser().GetAsync("/Cleaning");
        Assert.Equal(HttpStatusCode.MovedPermanently, res.StatusCode);
        Assert.Equal("/cleaning", res.Headers.Location!.OriginalString);
    }

    [Fact]
    public async Task Unknown_page_returns_404_and_is_not_indexed()
    {
        var res = await factory.Browser().GetAsync("/no-such-service");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
        var html = await res.Content.ReadAsStringAsync();
        Assert.Contains("الصفحة غير موجودة", html);
        Assert.Contains("noindex", html);
    }

    [Fact]
    public async Task Sitemap_lists_home_and_all_departments()
    {
        var xml = await factory.Browser().GetStringAsync("/sitemap.xml");
        var locs = Regex.Matches(xml, "<loc>(.*?)</loc>").Select(m => m.Groups[1].Value).ToList();
        Assert.Equal(1 + ServiceCatalog.All.Count, locs.Count);
        Assert.Contains($"{AppFactory.BaseUrl}/", locs);
        Assert.Contains($"{AppFactory.BaseUrl}/decor-painting", locs);
    }

    [Fact]
    public async Task Robots_blocks_dashboard_and_points_to_sitemap()
    {
        var txt = await factory.Browser().GetStringAsync("/robots.txt");
        Assert.Contains("Disallow: /admin", txt);
        Assert.Contains($"Sitemap: {AppFactory.BaseUrl}/sitemap.xml", txt);
    }

    [Fact]
    public async Task Responses_carry_security_headers()
    {
        var res = await factory.Browser().GetAsync("/");
        Assert.Equal("nosniff", res.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("DENY", res.Headers.GetValues("X-Frame-Options").Single());
        Assert.Contains("script-src 'self'", res.Headers.GetValues("Content-Security-Policy").Single());
    }

    private static string[] JsonLdTypes(string html) =>
        Regex.Matches(html, "<script type=\"application/ld\\+json\">(.*?)</script>", RegexOptions.Singleline)
            .Select(m => JsonDocument.Parse(m.Groups[1].Value).RootElement.GetProperty("@type").GetString()!)
            .ToArray();
}
