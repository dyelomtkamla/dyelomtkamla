namespace Dar.Web.Content;

public record Card(string Icon, string Title, string Body);
public record Faq(string Q, string A);
public record Option(string Value, string Label);

/// <summary>All copy for the landing page, one instance per language.</summary>
public record SiteText
{
    public required string Lang { get; init; }
    public required string Dir { get; init; }
    public required string Home { get; init; }
    public required string OtherLangLabel { get; init; }
    public required string OtherLangHome { get; init; }
    public required string Locale { get; init; }

    public required string Title { get; init; }
    public required string Description { get; init; }
    public required string Keywords { get; init; }

    public required string NavFeatures { get; init; }
    public required string NavWorkers { get; init; }
    public required string NavFaq { get; init; }
    public required string NavJoin { get; init; }

    public required string HeroBadge { get; init; }
    public required string HeroTitle { get; init; }
    public required string HeroAccent { get; init; }
    public required string HeroSub { get; init; }
    public required string HeroCta { get; init; }
    public required string HeroCta2 { get; init; }
    public required string StoreSoon { get; init; }

    public required string ChatFrom { get; init; }
    public required string ChatTo { get; init; }
    public required string ChatReply { get; init; }
    public required string ChatReplyTr { get; init; }
    public required string ChatTask { get; init; }

    public required string ProblemTitle { get; init; }
    public required Card[] Problems { get; init; }

    public required string FamilyTitle { get; init; }
    public required string FamilySub { get; init; }
    public required Card[] FamilyFeatures { get; init; }

    public required string WorkerTitle { get; init; }
    public required string WorkerSub { get; init; }
    public required Card[] WorkerFeatures { get; init; }

    public required string StepsTitle { get; init; }
    public required Card[] Steps { get; init; }

    public required string PledgeTitle { get; init; }
    public required string PledgeBody { get; init; }
    public required string[] PledgePoints { get; init; }

    public required string LanguagesTitle { get; init; }

    public required string FaqTitle { get; init; }
    public required Faq[] Faqs { get; init; }

    public required string JoinTitle { get; init; }
    public required string JoinSub { get; init; }
    public required string FieldName { get; init; }
    public required string FieldContact { get; init; }
    public required string FieldContactHint { get; init; }
    public required string FieldCountry { get; init; }
    public required string FieldRole { get; init; }
    public required Option[] Countries { get; init; }
    public required Option[] Roles { get; init; }
    public required string Submit { get; init; }
    public required string Joined { get; init; }
    public required string AlreadyJoined { get; init; }
    public required string Invalid { get; init; }

    public required string Footer { get; init; }
    public required string PrivacyLink { get; init; }
    public required string PrivacyPath { get; init; }

    public static readonly string[] SupportedLanguages =
    [
        "العربية", "English", "Tagalog", "हिन्दी", "বাংলা", "اردو",
        "አማርኛ", "Kiswahili", "Bahasa Indonesia", "සිංහල", "नेपाली", "മലയാളം",
    ];

    public static SiteText For(HttpRequest request) =>
        request.Path.StartsWithSegments("/en", StringComparison.OrdinalIgnoreCase) ? En : Ar;

    public static readonly SiteText Ar = new()
    {
        Lang = "ar", Dir = "rtl", Home = "/", OtherLangLabel = "English", OtherLangHome = "/en", Locale = "ar_SA",
        Title = "دار | تطبيق إدارة البيت والعاملة المنزلية بالذكاء الاصطناعي",
        Description = "دار يترجم بينك وبين العاملة المنزلية فوراً بالصوت، وينظم مهام البيت والوصفات والمقاضي، ويذكّرك بتجديد الإقامة والعقد. مصمم للسعودية والإمارات والخليج.",
        Keywords = "تطبيق العاملة المنزلية, ترجمة للخادمة, مترجم فلبيني عربي, تنظيم مهام البيت, تجديد إقامة العاملة, وصفات للعاملة, مساند, السعودية, الإمارات",

        NavFeatures = "المزايا", NavWorkers = "للعاملة", NavFaq = "الأسئلة", NavJoin = "سجّل الآن",

        HeroBadge = "قريباً على أندرويد وآيفون",
        HeroTitle = "بيتك منظّم،",
        HeroAccent = "وكلامك مفهوم بكل اللغات",
        HeroSub = "دار يترجم بينك وبين العاملة أو السائق فوراً بالصوت، ويرتّب مهام البيت والطبخ والمقاضي، ويذكّرك بالإقامة والعقد والراتب. كل هذا في تطبيق واحد.",
        HeroCta = "انضم لقائمة الانتظار",
        HeroCta2 = "شوف المزايا",
        StoreSoon = "قريباً",

        ChatFrom = "جهّزي غدا الأولاد الساعة ١، وقلّلي الملح 🙏",
        ChatTo = "Pakihanda ang tanghalian ng mga bata nang 1:00, at bawasan ang asin 🙏",
        ChatReply = "Opo ma'am, adobo po ba o kabsa?",
        ChatReplyTr = "حاضر مدام، أسوي أدوبو ولا كبسة؟",
        ChatTask = "✓ مهمة جديدة: غدا الأولاد، ١:٠٠ م",

        ProblemTitle = "مشاكل كل بيت في الخليج",
        Problems =
        [
            new("💬", "الكلام ما يوصل", "تقولين شيء وينفهم شيء ثاني. سوء فهم يومي يضيّع الوقت ويضايق الطرفين."),
            new("📋", "كل شيء بالذاكرة", "المهام والمقاضي ومواعيد الأولاد كلها شفهية، وأي تغيير يضيع."),
            new("📄", "أوراق ومواعيد", "انتهاء الإقامة، تجديد العقد، الإجازات، نهاية الخدمة. كل شيء متفرق ومتعب."),
        ],

        FamilyTitle = "كل اللي يحتاجه البيت",
        FamilySub = "اشتراك شهري بسيط للأسرة، وأول شهر مجاناً.",
        FamilyFeatures =
        [
            new("🎙️", "مترجم صوتي فوري", "تكلّمي بالعربي، وتوصلها رسالة صوتية ومكتوبة بلغتها. وردّها يوصلك بالعربي."),
            new("✅", "مهام البيت بالذكاء الاصطناعي", "اكتب «عزومة الخميس لـ ١٥ شخص» ويطلع لك جدول كامل بالمهام والأوقات."),
            new("🍲", "وصفات خليجية مترجمة", "كبسة، هريس، مجبوس، لقيمات. خطوة بخطوة بالصور بلغة العاملة."),
            new("🛒", "قائمة مقاضي ذكية", "القائمة تتحدث تلقائياً، وتنطلب بضغطة من تطبيقات التوصيل."),
            new("🔔", "تنبيهات الإقامة والعقد", "تذكير قبل انتهاء الإقامة والعقد والتأمين، وحساب نهاية الخدمة."),
            new("💳", "الراتب بدون تعب", "سجل رواتب وإجازات واضح، ودفع بالطرق الرسمية المعتمدة."),
        ],

        WorkerTitle = "وللعاملة والسائق: مجاناً",
        WorkerSub = "لما العاملة ترتاح، البيت كله يرتاح.",
        WorkerFeatures =
        [
            new("🌍", "تحويل الراتب لأهلها", "تحويل بسعر صرف أفضل ورسوم أقل، عن طريق شركاء مرخّصين."),
            new("🎓", "كورسات وشهادات", "طبخ، عناية بالأطفال، عربي مبسّط. شهادة ترفع قيمتها في سوق العمل."),
            new("🛡️", "حقوقها بلغتها", "دليل واضح للحقوق وأرقام الطوارئ والسفارة."),
            new("🐷", "ادخار بسيط", "تحوّش مبلغ صغير كل شهر لهدف تختاره."),
        ],

        StepsTitle = "تبدأ في ٣ خطوات",
        Steps =
        [
            new("١", "حمّل التطبيق", "سجّل حساب الأسرة برقم جوالك."),
            new("٢", "أضف العاملة", "ترسل لها دعوة، وتختار لغتها."),
            new("٣", "ابدأ", "تكلّم، أضف مهام، وخلّ دار يتكفّل بالباقي."),
        ],

        PledgeTitle = "تعهّد دار: احترام وخصوصية",
        PledgeBody = "دار أداة تفاهم وتنظيم، وليس أداة مراقبة. نؤمن أن البيت المرتاح يبدأ من الاحترام المتبادل.",
        PledgePoints =
        [
            "لا تتبّع موقع ولا تسجيل خفي، أبداً",
            "بياناتك مشفّرة ومحفوظة حسب أنظمة حماية البيانات في دول الخليج",
            "نكمّل الأنظمة الرسمية مثل مساند ولا نستبدلها",
        ],

        LanguagesTitle = "يتكلم لغة بيتك",

        FaqTitle = "أسئلة شائعة",
        Faqs =
        [
            new("متى ينزل التطبيق؟", "نطلق النسخة الأولى في الرياض ودبي قريباً. سجّل في قائمة الانتظار وتوصلك الدعوة أول واحد، مع شهر مجاني."),
            new("كم سعر الاشتراك؟", "التطبيق مجاني للعاملة دائماً. اشتراك الأسرة سيكون بسعر رمزي شهرياً، وأول شهر مجاني لمن في قائمة الانتظار."),
            new("هل يراقب التطبيق العاملة؟", "لا. دار لا يتتبع الموقع ولا يسجّل أي شيء بدون علم الطرفين. هدفنا التفاهم والتنظيم فقط."),
            new("أي لغات يدعم؟", "العربية والإنجليزية والتاجالوج والهندية والبنغالية والأوردو والأمهرية والسواحيلية والإندونيسية والسنهالية والنيبالية والمالايالامية، ونضيف المزيد."),
            new("هل يغني عن مساند أو منصات الوزارة؟", "لا. دار يكمّل المنصات الرسمية ويذكّرك بمواعيدها، لكن الإجراءات الرسمية تتم عبر الجهات المختصة."),
        ],

        JoinTitle = "كن من أول المستخدمين",
        JoinSub = "سجّل الآن واحصل على شهر مجاني وأولوية في الدعوات.",
        FieldName = "الاسم",
        FieldContact = "الجوال أو البريد",
        FieldContactHint = "+966 5X XXX XXXX",
        FieldCountry = "الدولة",
        FieldRole = "أنا",
        Countries =
        [
            new("SA", "السعودية"), new("AE", "الإمارات"), new("KW", "الكويت"), new("QA", "قطر"),
            new("BH", "البحرين"), new("OM", "عُمان"), new("XX", "دولة أخرى"),
        ],
        Roles = [new("family", "أسرة"), new("worker", "عاملة / سائق"), new("agency", "مكتب استقدام")],
        Submit = "سجّلني",
        Joined = "تم تسجيلك بنجاح 🎉 بنرسل لك الدعوة أول ما نطلق.",
        AlreadyJoined = "أنت مسجّل معنا من قبل 👌",
        Invalid = "تأكد من الاسم والجوال أو البريد.",

        Footer = "دار. صُنع للخليج، ولكل بيت في العالم.",
        PrivacyLink = "سياسة الخصوصية",
        PrivacyPath = "/privacy",
    };

    public static readonly SiteText En = new()
    {
        Lang = "en", Dir = "ltr", Home = "/en", OtherLangLabel = "العربية", OtherLangHome = "/", Locale = "en_US",
        Title = "Dar | AI home & domestic helper app with live voice translation",
        Description = "Dar translates instantly between you and your domestic helper by voice, organizes chores, recipes and groceries, and reminds you about visas and contracts. Built for Saudi Arabia, the UAE and the Gulf.",
        Keywords = "domestic helper app, maid translation app, Tagalog Arabic translator, household task manager, helper visa renewal, Saudi Arabia, UAE, GCC",

        NavFeatures = "Features", NavWorkers = "For helpers", NavFaq = "FAQ", NavJoin = "Join now",

        HeroBadge = "Coming soon to Android & iPhone",
        HeroTitle = "A well-run home,",
        HeroAccent = "understood in every language",
        HeroSub = "Dar translates instantly between you and your helper or driver by voice, plans chores, cooking and groceries, and keeps track of visas, contracts and salary. All in one app.",
        HeroCta = "Join the waitlist",
        HeroCta2 = "See features",
        StoreSoon = "Soon",

        ChatFrom = "Please make the kids' lunch at 1, and less salt 🙏",
        ChatTo = "Pakihanda ang tanghalian ng mga bata nang 1:00, at bawasan ang asin 🙏",
        ChatReply = "Opo ma'am, adobo po ba o kabsa?",
        ChatReplyTr = "Yes ma'am, adobo or kabsa?",
        ChatTask = "✓ New task: kids' lunch, 1:00 PM",

        ProblemTitle = "Every Gulf household knows this",
        Problems =
        [
            new("💬", "Lost in translation", "You say one thing, something else gets done. Daily misunderstandings waste time and frustrate everyone."),
            new("📋", "Everything is verbal", "Chores, groceries and school runs live in people's heads, so every change gets lost."),
            new("📄", "Paperwork and deadlines", "Visa expiry, contract renewal, leave, end-of-service. Scattered and stressful."),
        ],

        FamilyTitle = "Everything your home needs",
        FamilySub = "A simple monthly plan for families. First month free.",
        FamilyFeatures =
        [
            new("🎙️", "Live voice translator", "Speak your language; your helper hears and reads it in theirs, and their reply comes back in yours."),
            new("✅", "AI chore planner", "Type “dinner party Thursday for 15” and get a full plan with tasks and times."),
            new("🍲", "Translated Gulf recipes", "Kabsa, harees, machboos, luqaimat. Step by step with photos, in your helper's language."),
            new("🛒", "Smart grocery list", "Shared list that updates itself and orders in one tap from delivery apps."),
            new("🔔", "Visa & contract alerts", "Reminders before visa, contract and insurance expire, plus end-of-service calculation."),
            new("💳", "Payroll made easy", "Clear salary and leave records, paid through official approved channels."),
        ],

        WorkerTitle = "Free for helpers and drivers",
        WorkerSub = "A happy helper makes a happy home.",
        WorkerFeatures =
        [
            new("🌍", "Send money home", "Better exchange rates and lower fees through licensed partners."),
            new("🎓", "Courses & certificates", "Cooking, childcare, basic Arabic, with certificates that raise their value."),
            new("🛡️", "Know your rights", "Clear rights guide plus emergency and embassy contacts, in their language."),
            new("🐷", "Micro-savings", "Put aside a little every month toward a goal they choose."),
        ],

        StepsTitle = "Start in 3 steps",
        Steps =
        [
            new("1", "Download", "Create a family account with your phone number."),
            new("2", "Invite your helper", "Send an invite; they pick their language."),
            new("3", "Go", "Talk, add tasks, and let Dar handle the rest."),
        ],

        PledgeTitle = "The Dar pledge: respect and privacy",
        PledgeBody = "Dar is a tool for understanding and organization, never for surveillance. A happy home starts with mutual respect.",
        PledgePoints =
        [
            "No location tracking and no hidden recording. Ever.",
            "Encrypted data, handled under Gulf data protection laws",
            "We complement official platforms like Musaned, never replace them",
        ],

        LanguagesTitle = "Speaks your home's language",

        FaqTitle = "FAQ",
        Faqs =
        [
            new("When does the app launch?", "The first version launches in Riyadh and Dubai soon. Join the waitlist to be invited first, with a free month."),
            new("How much does it cost?", "Always free for helpers. Families pay a small monthly fee, and the first month is free for waitlist members."),
            new("Does the app monitor my helper?", "No. Dar never tracks location or records anything without both sides knowing. It's about understanding and organization only."),
            new("Which languages are supported?", "Arabic, English, Tagalog, Hindi, Bengali, Urdu, Amharic, Swahili, Indonesian, Sinhala, Nepali and Malayalam, with more coming."),
            new("Does it replace Musaned or ministry platforms?", "No. Dar complements official platforms and reminds you of deadlines; official procedures still go through the relevant authorities."),
        ],

        JoinTitle = "Be one of the first",
        JoinSub = "Join now for a free month and priority access.",
        FieldName = "Name",
        FieldContact = "Phone or email",
        FieldContactHint = "+971 5X XXX XXXX",
        FieldCountry = "Country",
        FieldRole = "I am",
        Countries =
        [
            new("SA", "Saudi Arabia"), new("AE", "UAE"), new("KW", "Kuwait"), new("QA", "Qatar"),
            new("BH", "Bahrain"), new("OM", "Oman"), new("XX", "Other"),
        ],
        Roles = [new("family", "A family"), new("worker", "A helper / driver"), new("agency", "A recruitment agency")],
        Submit = "Sign me up",
        Joined = "You're on the list 🎉 We'll send your invite at launch.",
        AlreadyJoined = "You're already on the list 👌",
        Invalid = "Please check your name and phone or email.",

        Footer = "Dar. Made for the Gulf, built for every home.",
        PrivacyLink = "Privacy policy",
        PrivacyPath = "/en/privacy",
    };
}
