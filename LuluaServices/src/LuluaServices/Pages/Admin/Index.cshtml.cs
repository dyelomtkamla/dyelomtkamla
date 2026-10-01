using System.Text;
using LuluaServices.Data;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace LuluaServices.Pages.Admin;

public class IndexModel(AppDbContext db) : PageModel
{
    public const int PageSize = 30;

    [BindProperty(SupportsGet = true)] public BookingStatus? Status { get; set; }
    [BindProperty(SupportsGet = true)] public string? Section { get; set; }
    [BindProperty(SupportsGet = true)] public string? Q { get; set; }
    [BindProperty(SupportsGet = true, Name = "p")] public int PageNumber { get; set; } = 1;

    public IReadOnlyList<Booking> Bookings { get; private set; } = Array.Empty<Booking>();
    public Dictionary<BookingStatus, int> Counts { get; private set; } = new();
    public int Total { get; private set; }
    public int FilteredTotal { get; private set; }
    public int PageCount => Math.Max(1, (int)Math.Ceiling(FilteredTotal / (double)PageSize));

    [TempData] public string? Flash { get; set; }

    public async Task OnGetAsync()
    {
        Counts = await db.Bookings.GroupBy(b => b.Status)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Key, x => x.Count);
        Total = Counts.Values.Sum();

        var query = Filtered();
        FilteredTotal = await query.CountAsync();
        PageNumber = Math.Clamp(PageNumber, 1, PageCount);
        Bookings = await query.OrderByDescending(b => b.CreatedAtUtc)
            .Skip((PageNumber - 1) * PageSize).Take(PageSize).ToListAsync();
    }

    public async Task<IActionResult> OnPostUpdateAsync(int id, BookingStatus newStatus, string? adminNotes)
    {
        var booking = await db.Bookings.FindAsync(id);
        if (booking is null) return NotFound();
        if (!Enum.IsDefined(newStatus)) return BadRequest();

        var notes = adminNotes?.Trim();
        booking.Status = newStatus;
        booking.AdminNotes = string.IsNullOrEmpty(notes) ? null : notes[..Math.Min(notes.Length, 1000)];
        booking.UpdatedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync();
        Flash = $"تم تحديث الطلب #{id}";
        return RedirectToPage(new { status = Status, section = Section, q = Q, p = PageNumber });
    }

    public async Task<IActionResult> OnPostDeleteAsync(int id)
    {
        var deleted = await db.Bookings.Where(b => b.Id == id).ExecuteDeleteAsync();
        Flash = deleted > 0 ? $"تم حذف الطلب #{id}" : "الطلب غير موجود";
        return RedirectToPage(new { status = Status, section = Section, q = Q, p = PageNumber });
    }

    /// <summary>CSV (UTF-8 with BOM so Excel shows Arabic correctly) of the currently filtered bookings.</summary>
    public async Task<IActionResult> OnGetExportAsync()
    {
        var rows = await Filtered().OrderByDescending(b => b.CreatedAtUtc).ToListAsync();
        var sb = new StringBuilder();
        sb.AppendLine("رقم الطلب,التاريخ,الاسم,الجوال,القسم,الحي / المدينة,الموعد المفضّل,التفاصيل,الحالة,ملاحظات الإدارة");
        foreach (var b in rows)
        {
            sb.AppendLine(string.Join(",", new[]
            {
                b.Id.ToString(), b.CreatedAtUtc.ToString("yyyy-MM-dd HH:mm"), b.Name, b.Phone, SectionName(b.SectionSlug),
                b.Area, b.PreferredDate?.ToString("yyyy-MM-dd") ?? "", b.Notes ?? "", b.Status.Arabic(), b.AdminNotes ?? "",
            }.Select(Csv)));
        }
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
        return File(bytes, "text/csv; charset=utf-8", $"lulua-bookings-{DateTime.UtcNow:yyyyMMdd}.csv");
    }

    /// <summary>Saudi time (UTC+3, no DST) for display; falls back if the OS has no time-zone data.</summary>
    public static TimeZoneInfo SaudiTime { get; } =
        TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Riyadh", out var tz) ? tz
        : TimeZoneInfo.CreateCustomTimeZone("Asia/Riyadh", TimeSpan.FromHours(3), "Riyadh", "Riyadh");

    public static string SectionName(string slug) => ServiceCatalog.Find(slug)?.Name ?? slug;

    private IQueryable<Booking> Filtered()
    {
        var query = db.Bookings.AsNoTracking().AsQueryable();
        if (Status is { } s) query = query.Where(b => b.Status == s);
        if (!string.IsNullOrWhiteSpace(Section)) query = query.Where(b => b.SectionSlug == Section);
        if (!string.IsNullOrWhiteSpace(Q))
        {
            var q = Q.Trim();
            query = int.TryParse(q.TrimStart('#'), out var id)
                ? query.Where(b => b.Id == id || b.Phone.Contains(q))
                : query.Where(b => b.Name.Contains(q) || b.Phone.Contains(q) || b.Area.Contains(q));
        }
        return query;
    }

    // Quote every cell and neutralise spreadsheet formulas (=, +, -, @) entered by customers.
    private static string Csv(string value)
    {
        if (value.Length > 0 && "=+-@\t\r".Contains(value[0])) value = "'" + value;
        return "\"" + value.Replace("\"", "\"\"") + "\"";
    }
}
