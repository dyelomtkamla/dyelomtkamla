using System.ComponentModel.DataAnnotations;

namespace LuluaServices.Models;

public enum BookingStatus
{
    New = 0,
    Confirmed = 1,
    Completed = 2,
    Cancelled = 3,
}

public static class BookingStatusText
{
    public static string Arabic(this BookingStatus s) => s switch
    {
        BookingStatus.New => "جديد",
        BookingStatus.Confirmed => "مؤكد",
        BookingStatus.Completed => "مكتمل",
        BookingStatus.Cancelled => "ملغي",
        _ => s.ToString(),
    };
}

public class Booking
{
    public int Id { get; set; }

    [MaxLength(100)] public string Name { get; set; } = "";
    [MaxLength(20)] public string Phone { get; set; } = "";
    [MaxLength(40)] public string SectionSlug { get; set; } = "";
    [MaxLength(100)] public string Area { get; set; } = "";
    public DateOnly? PreferredDate { get; set; }
    [MaxLength(1000)] public string? Notes { get; set; }

    public BookingStatus Status { get; set; } = BookingStatus.New;
    [MaxLength(1000)] public string? AdminNotes { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
}

/// <summary>What a customer submits from the booking form.</summary>
public class BookingInput
{
    [Required(ErrorMessage = "فضلاً اكتب اسمك")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "الاسم يجب أن يكون بين 2 و100 حرف")]
    [Display(Name = "الاسم")]
    public string Name { get; set; } = "";

    [Required(ErrorMessage = "فضلاً اكتب رقم الجوال")]
    [RegularExpression(@"^\+?[0-9 ]{9,16}$", ErrorMessage = "رقم الجوال غير صحيح")]
    [Display(Name = "رقم الجوال")]
    public string Phone { get; set; } = "";

    [Required(ErrorMessage = "فضلاً اختر القسم")]
    [Display(Name = "القسم")]
    public string Section { get; set; } = "";

    [Required(ErrorMessage = "فضلاً اكتب الحي أو المدينة")]
    [StringLength(100, ErrorMessage = "النص طويل جداً")]
    [Display(Name = "الحي / المدينة")]
    public string Area { get; set; } = "";

    [DataType(DataType.Date)]
    [Display(Name = "الموعد المفضّل")]
    public DateOnly? PreferredDate { get; set; }

    [StringLength(1000, ErrorMessage = "التفاصيل يجب ألا تتجاوز 1000 حرف")]
    [Display(Name = "تفاصيل الطلب")]
    public string? Notes { get; set; }

    /// <summary>Honeypot: hidden from people, filled in by spam bots.</summary>
    public string? Website { get; set; }
}
