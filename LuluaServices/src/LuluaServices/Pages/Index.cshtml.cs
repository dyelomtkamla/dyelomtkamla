using LuluaServices.Infrastructure;
using LuluaServices.Models;
using LuluaServices.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Options;

namespace LuluaServices.Pages;

public class IndexModel(IOptions<BusinessOptions> options) : PageModel
{
    public BusinessOptions Business { get; } = options.Value;

    public IReadOnlyList<Faq> Faqs { get; } = new Faq[]
    {
        new("ما الخدمات التي تقدمها مؤسسة لؤلؤة المستقل؟",
            "نقدّم ثمانية أقسام: مكافحة الحشرات، التنظيف، الصيانة، العزل، نقل وتخزين الأثاث، المسابح، المقاولات العامة، وقسم خاص للديكورات والدهانات."),
        new("كيف أحجز خدمة؟", "اختر القسم ثم املأ نموذج الحجز ليصل طلبك إلى فريقنا مباشرة، أو تواصل معنا عبر واتساب أو الاتصال."),
        new("هل المعاينة مجانية؟", "نعم، نوفّر معاينة وتقدير تكلفة قبل البدء في معظم الخدمات."),
        new("ما أوقات العمل؟", "يومياً من 8 صباحاً حتى 11 مساءً، مع إمكانية تلبية الطلبات الطارئة."),
    };

    public BookingInput Booking { get; } = new() { Section = ServiceCatalog.All[0].Slug };

    public void OnGet()
    {
        ViewData["Active"] = "home";
        ViewData.SetSeo(new SeoMeta
        {
            Title = $"{Business.Name} | مكافحة حشرات، تنظيف، صيانة، عزل، نقل أثاث، مسابح، مقاولات وديكور",
            Description = "مؤسسة لؤلؤة المستقل للخدمات المنزلية: مكافحة حشرات، تنظيف منازل، صيانة شاملة، عزل أسطح، نقل وتخزين أثاث، مسابح، مقاولات عامة، وديكورات ودهانات. احجز الآن.",
            Path = "/",
            JsonLd = { Seo.Business(Business), Seo.WebSite(Business), Seo.FaqPage(Faqs) },
        });
    }
}
