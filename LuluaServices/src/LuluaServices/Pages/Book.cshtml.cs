using System.Text;
using LuluaServices.Data;
using LuluaServices.Infrastructure;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace LuluaServices.Pages;

[EnableRateLimiting("forms")]
public class BookModel(AppDbContext db, IOptions<BusinessOptions> options, ILogger<BookModel> logger) : PageModel
{
    [BindProperty]
    public BookingInput Input { get; set; } = new();

    public void OnGet(string? service)
    {
        Input.Section = ServiceCatalog.Find(service)?.Slug ?? ServiceCatalog.All[0].Slug;
        SetPageMeta();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        // Bots fill the hidden field: act as if it worked, store nothing.
        if (!string.IsNullOrWhiteSpace(Input.Website))
            return RedirectToPage("/Thanks");

        var section = ServiceCatalog.Find(Input.Section);
        if (section is null)
            ModelState.AddModelError("Input.Section", "فضلاً اختر قسماً صحيحاً");
        if (Input.PreferredDate is { } d && d < DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-1)))
            ModelState.AddModelError("Input.PreferredDate", "الموعد يجب أن يكون اليوم أو بعده");

        if (!ModelState.IsValid)
        {
            SetPageMeta();
            return Page();
        }

        var booking = new Booking
        {
            Name = Input.Name.Trim(),
            Phone = Input.Phone.Replace(" ", ""),
            SectionSlug = section!.Slug,
            Area = Input.Area.Trim(),
            PreferredDate = Input.PreferredDate,
            Notes = string.IsNullOrWhiteSpace(Input.Notes) ? null : Input.Notes.Trim(),
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync();
        logger.LogInformation("New booking {Id} for {Section}", booking.Id, booking.SectionSlug);

        var msg = new StringBuilder()
            .AppendLine($"طلب حجز رقم #{booking.Id} - {options.Value.ShortName}")
            .AppendLine("القسم: " + section.Name)
            .AppendLine("الاسم: " + booking.Name)
            .AppendLine("الجوال: " + booking.Phone)
            .Append("الحي / المدينة: " + booking.Area);
        if (booking.PreferredDate is { } date) msg.AppendLine().Append("الموعد المفضّل: " + date.ToString("yyyy-MM-dd"));

        TempData["BookingId"] = booking.Id;
        TempData["SectionName"] = section.Name;
        TempData["WhatsAppText"] = msg.ToString();
        return RedirectToPage("/Thanks");
    }

    private void SetPageMeta()
    {
        ViewData["Active"] = "book";
        ViewData["Back"] = true;
        ViewData.SetSeo(new SeoMeta
        {
            Title = $"احجز خدمة منزلية | {options.Value.ShortName}",
            Description = "احجز خدمات مكافحة الحشرات والتنظيف والصيانة والعزل ونقل الأثاث والمسابح والمقاولات والديكور من مؤسسة لؤلؤة المستقل.",
            Path = "/book",
        });
    }
}
