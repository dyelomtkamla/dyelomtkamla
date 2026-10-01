using LuluaServices.Infrastructure;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Options;

namespace LuluaServices.Pages;

public class SectionModel(IOptions<BusinessOptions> options) : PageModel
{
    public BusinessOptions Business { get; } = options.Value;
    public ServiceSection Section { get; private set; } = null!;
    public BookingInput Booking { get; private set; } = new();

    public IActionResult OnGet(string slug)
    {
        var section = ServiceCatalog.Find(slug);
        if (section is null) return NotFound();

        // One canonical URL per department: redirect /Cleaning -> /cleaning.
        if (slug != section.Slug) return RedirectPermanent("/" + section.Slug);

        Section = section;
        Booking = new BookingInput { Section = section.Slug };
        ViewData["Active"] = "services";
        ViewData["Back"] = true;
        ViewData["BodyStyle"] = "--c:" + section.Color;
        ViewData.SetSeo(new SeoMeta
        {
            Title = $"{section.Title} | {Business.ShortName}",
            Description = section.Description,
            Path = "/" + section.Slug,
            ThemeColor = section.Color,
            JsonLd = { Seo.Service(Business, section), Seo.Breadcrumbs(Business, section), Seo.FaqPage(section.Faq) },
        });
        return Page();
    }
}
