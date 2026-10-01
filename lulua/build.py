#!/usr/bin/env python3
"""Generates the static, SEO-friendly pages of the Lulua Al-Mustaqil home-services app.

Edit CONFIG / SECTIONS below, then run:  python3 lulua/build.py
Every department gets its own crawlable page (clean URL, own title/description,
Service + FAQPage + BreadcrumbList structured data) plus a shared sitemap.xml.
"""
import json
import os
from html import escape

ROOT = os.path.dirname(os.path.abspath(__file__))

CONFIG = {
    "name": "مؤسسة لؤلؤة المستقل للخدمات المنزلية",
    "short": "لؤلؤة المستقل",
    "base_url": "https://dyelomtkamla.github.io/dyelomtkamla/lulua/",
    # Replace with the real numbers (international format without + for WhatsApp).
    "whatsapp": "966500000000",
    "phone": "0500000000",
    "area": "المملكة العربية السعودية",
    "hours": "يومياً من 8 صباحاً حتى 11 مساءً",
}

ICONS = {
    "pest": '<path d="M12 8a3 3 0 0 1 3 3v4a3 3 0 0 1-6 0v-4a3 3 0 0 1 3-3z"/><path d="M10 6.5 8.5 4M14 6.5 15.5 4M9 11H5M15 11h4M9 15H5.5M15 15h3.5M10 19l-2 2M14 19l2 2M12 8v10"/>',
    "clean": '<path d="M9 3h5v4H9z"/><path d="M8 7h7l1 4v9a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1v-9z"/><path d="M14 3h3l2 2M19 11l1-1M19 14h2M19 17l1 1"/>',
    "repair": '<path d="M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.6 2.6-2.4-.6-.6-2.4z"/>',
    "shield": '<path d="M12 3 4 6v6c0 4.5 3.4 8.2 8 9 4.6-.8 8-4.5 8-9V6z"/><path d="M8 12h8M8 15.5h8M8 8.5h8"/>',
    "truck": '<path d="M2 6h12v10H2zM14 9h4l3 3.5V16h-7z"/><circle cx="6" cy="17.5" r="1.8"/><circle cx="17" cy="17.5" r="1.8"/>',
    "pool": '<path d="M2 17c1.5 1.3 3 1.3 4.5 0s3-1.3 4.5 0 3 1.3 4.5 0 3-1.3 4.5 0M2 21c1.5 1.3 3 1.3 4.5 0s3-1.3 4.5 0 3 1.3 4.5 0 3-1.3 4.5 0"/><path d="M8 14V5a2 2 0 0 1 4 0M16 14V5a2 2 0 0 0-4 0M8 8h8M8 11h8"/>',
    "build": '<path d="M3 21h18M5 21V9l7-5 7 5v12"/><path d="M9 21v-6h6v6M9 11h.01M15 11h.01"/>',
    "paint": '<path d="M4 4h13v5H4z"/><path d="M17 6.5h3V12h-8v3"/><path d="M10.5 15h3v6h-3z"/>',
    "check": '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    "home": '<path d="M3 11 12 4l9 7"/><path d="M5 10v10h14V10"/>',
    "grid": '<path d="M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z"/>',
    "calendar": '<path d="M4 6h16v14H4zM4 10h16M8 3v5M16 3v5"/>',
    "phone": '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
    "back": '<path d="m9 6 6 6-6 6"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "star": '<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z"/>',
    "badge": '<circle cx="12" cy="9" r="6"/><path d="m8.5 14-1.5 7 5-3 5 3-1.5-7"/>',
    "tag": '<path d="M3 12V4h8l10 10-8 8z"/><circle cx="7.5" cy="8" r="1.5"/>',
    "install": '<path d="M12 3v12M7 10l5 5 5-5M5 21h14"/>',
}

WA_SVG = '<svg viewBox="0 0 32 32" aria-hidden="true"><path fill="currentColor" d="M16 3a13 13 0 0 0-11.2 19.6L3 29l6.6-1.7A13 13 0 1 0 16 3zm0 23.6a10.6 10.6 0 0 1-5.4-1.5l-.4-.2-3.9 1 1-3.8-.2-.4A10.6 10.6 0 1 1 16 26.6zm5.8-7.9c-.3-.2-1.9-.9-2.2-1s-.5-.2-.7.2-.8 1-1 1.2-.4.2-.7.1a8.7 8.7 0 0 1-4.3-3.8c-.3-.6.3-.5 1-1.7.1-.2 0-.4 0-.5l-1-2.4c-.3-.6-.5-.5-.7-.5h-.6a1.2 1.2 0 0 0-.9.4 3.6 3.6 0 0 0-1.1 2.7 6.3 6.3 0 0 0 1.3 3.3 14.4 14.4 0 0 0 5.5 4.9c2 .9 2.8.9 3.8.8a3.3 3.3 0 0 0 2.1-1.5 2.7 2.7 0 0 0 .2-1.5c-.1-.1-.3-.2-.7-.3z"/></svg>'

SECTIONS = [
    {
        "slug": "pest-control", "icon": "pest", "color": "#2f8f5b",
        "name": "مكافحة الحشرات",
        "title": "شركة مكافحة حشرات | رش مبيدات وإبادة الصراصير والنمل الأبيض",
        "tagline": "بيت نظيف وآمن خالٍ من الحشرات والقوارض",
        "desc": "خدمات مكافحة حشرات احترافية للمنازل والفلل والشقق والمطاعم: رش مبيدات آمنة ومعتمدة، إبادة الصراصير وبق الفراش والنمل الأبيض والقوارض مع ضمان.",
        "intro": "يقدّم قسم مكافحة الحشرات في مؤسسة لؤلؤة المستقل حلولاً متكاملة للتخلص من الحشرات الزاحفة والطائرة والقوارض، باستخدام مبيدات معتمدة من الجهات المختصة وآمنة على الأطفال والحيوانات الأليفة. نبدأ بمعاينة الموقع وتحديد مصدر الإصابة، ثم نختار طريقة المعالجة المناسبة (رش، جل، طعوم، تبخير) مع زيارة متابعة للتأكد من النتيجة.",
        "services": [
            ("مكافحة الصراصير", "معالجة بالجل والرش للمطابخ ودورات المياه وفتحات الصرف."),
            ("إبادة بق الفراش", "معالجة المراتب والأسرّة والأثاث بتقنيات تقضي على البيض والحشرة."),
            ("مكافحة النمل الأبيض", "حقن التربة وحماية الأخشاب والأساسات قبل البناء وبعده."),
            ("مكافحة القوارض", "طعوم ومصائد آمنة وسد منافذ دخول الفئران والجرذان."),
            ("رش الناموس والذباب", "رش ضبابي للحدائق والأحواش والمساحات الخارجية."),
            ("تعقيم وتطهير", "تعقيم شامل للمنازل والمكاتب ضد البكتيريا والفيروسات."),
        ],
        "features": ["مبيدات معتمدة وآمنة", "ضمان مكتوب على الخدمة", "زيارة متابعة مجانية", "فنيون مدرّبون"],
        "faq": [
            ("هل المبيدات آمنة على الأطفال؟", "نعم، نستخدم مبيدات معتمدة منخفضة السمية، ونرشدك إلى مدة التهوية المناسبة قبل العودة للمكان."),
            ("كم يستمر مفعول الرش؟", "يختلف حسب نوع الحشرة والمبيد، وغالباً من 3 إلى 6 أشهر مع الالتزام بتعليمات ما بعد الرش."),
            ("هل يوجد ضمان؟", "نعم، نقدّم ضماناً مكتوباً يشمل زيارة متابعة في حال ظهور الحشرات خلال فترة الضمان."),
        ],
    },
    {
        "slug": "cleaning", "icon": "clean", "color": "#1aa0a8",
        "name": "خدمات التنظيف",
        "title": "شركة تنظيف منازل وفلل | تنظيف كنب وسجاد وخزانات",
        "tagline": "نظافة تلمع مثل اللؤلؤ",
        "desc": "شركة تنظيف شامل للمنازل والفلل والشقق: تنظيف كنب وسجاد وموكيت بالبخار، تنظيف وتعقيم خزانات المياه، جلي وتلميع رخام، وتنظيف ما بعد التشطيب.",
        "intro": "فريق التنظيف في لؤلؤة المستقل مجهّز بأحدث المعدات ومواد التنظيف الآمنة لتقديم نظافة عميقة لكل ركن في منزلك. سواء كنت تستعد لمناسبة أو تنتقل إلى بيت جديد أو تحتاج تنظيفاً دورياً، نوفّر عمالة مدرّبة وأسعاراً واضحة قبل البدء.",
        "services": [
            ("تنظيف شامل للمنازل والفلل", "تنظيف الغرف والمطابخ ودورات المياه والنوافذ والواجهات."),
            ("تنظيف الكنب والسجاد", "غسيل بالبخار وإزالة البقع والروائح مع تجفيف سريع."),
            ("تنظيف وتعقيم الخزانات", "تنظيف خزانات المياه العلوية والأرضية وعزلها وتعقيمها."),
            ("جلي وتلميع الرخام", "جلي وتلميع الرخام والبلاط وإعادة اللمعان للأرضيات."),
            ("تنظيف ما بعد التشطيب", "إزالة بقايا الدهان والأسمنت وتجهيز المكان للسكن."),
            ("تنظيف المكيفات", "غسيل المكيفات السبليت والشباك وتعقيمها لهواء أنقى."),
        ],
        "features": ["معدات بخار حديثة", "مواد تنظيف آمنة", "عمالة مدرّبة وموثوقة", "مواعيد مرنة"],
        "faq": [
            ("هل تحضرون المعدات ومواد التنظيف؟", "نعم، يحضر الفريق جميع المعدات والمواد اللازمة، ولا تحتاج لتوفير أي شيء."),
            ("كم يستغرق تنظيف الفيلا؟", "حسب المساحة والحالة، وغالباً من يوم إلى يومين لتنظيف شامل."),
            ("هل يمكن حجز تنظيف دوري؟", "نعم، نوفّر عقود تنظيف أسبوعية أو شهرية بأسعار مميزة."),
        ],
    },
    {
        "slug": "maintenance", "icon": "repair", "color": "#d07a1f",
        "name": "خدمات الصيانة",
        "title": "صيانة منازل شاملة | سباكة وكهرباء وتكييف ونجارة",
        "tagline": "فني محترف لكل عطل في بيتك",
        "desc": "صيانة منزلية شاملة: سباك، كهربائي، صيانة وتركيب مكيفات، نجارة وتركيب أبواب، كشف تسربات المياه بالأجهزة الحديثة، وصيانة دورية للمنازل والعمائر.",
        "intro": "قسم الصيانة في مؤسسة لؤلؤة المستقل يجمع لك الفنيين المتخصصين في مكان واحد. نصلك بسرعة لتشخيص العطل وإصلاحه بقطع غيار أصلية، ونوفر عقود صيانة دورية للفلل والعمائر والمجمعات السكنية.",
        "services": [
            ("أعمال السباكة", "إصلاح التسربات وتركيب الأدوات الصحية والسخانات وتسليك المجاري."),
            ("أعمال الكهرباء", "تمديدات وإصلاح أعطال وتركيب إنارة ولوحات توزيع."),
            ("صيانة المكيفات", "تركيب وفك ونقل وتعبئة فريون وإصلاح أعطال المكيفات."),
            ("كشف تسربات المياه", "كشف التسربات بالأجهزة الإلكترونية دون تكسير."),
            ("النجارة", "تركيب وصيانة الأبواب والمطابخ وغرف النوم والخزائن."),
            ("عقود صيانة دورية", "صيانة وقائية مجدولة للفلل والعمائر والمجمعات."),
        ],
        "features": ["وصول سريع", "قطع غيار أصلية", "ضمان على الإصلاح", "تسعير قبل البدء"],
        "faq": [
            ("هل يوجد ضمان على الإصلاح؟", "نعم، نضمن أعمال الصيانة وقطع الغيار المركّبة لفترة يتم تحديدها في الفاتورة."),
            ("هل تكشفون التسربات بدون تكسير؟", "نعم، نستخدم أجهزة كشف حراري وصوتي لتحديد موقع التسرب بدقة قبل أي تكسير."),
            ("هل لديكم عقود صيانة سنوية؟", "نعم، نوفّر عقوداً سنوية تشمل زيارات دورية وأولوية في الطوارئ."),
        ],
    },
    {
        "slug": "insulation", "icon": "shield", "color": "#3f6ad8",
        "name": "خدمات العزل",
        "title": "شركة عزل أسطح وخزانات | عزل مائي وحراري وفوم",
        "tagline": "حماية بيتك من الحرارة والرطوبة والتسربات",
        "desc": "عزل أسطح مائي وحراري، عزل فوم بولي يوريثان، عزل خزانات المياه بالإيبوكسي، عزل الحمامات والمطابخ، وعزل الأساسات والجدران بضمان طويل.",
        "intro": "يقدّم قسم العزل حلولاً تحمي منزلك من تسربات المياه وارتفاع درجات الحرارة، مما يطيل عمر المبنى ويخفض فاتورة الكهرباء. نستخدم مواد عزل عالية الجودة ونطبّقها وفق المواصفات الفنية مع اختبار الغمر بالمياه قبل التسليم.",
        "services": [
            ("عزل الأسطح المائي", "رولات بيتومين وأنظمة سائلة مع اختبار غمر قبل التسليم."),
            ("العزل الحراري", "ألواح وفوم لعزل الأسطح والجدران وتقليل استهلاك التكييف."),
            ("عزل الفوم", "رش فوم بولي يوريثان عازل حرارياً ومائياً في طبقة واحدة."),
            ("عزل الخزانات", "عزل خزانات المياه بالإيبوكسي الآمن على مياه الشرب."),
            ("عزل الحمامات والمطابخ", "عزل الأرضيات قبل التبليط لمنع التسربات للأدوار السفلية."),
            ("عزل الأساسات والجدران", "حماية الخرسانة من الرطوبة والأملاح."),
        ],
        "features": ["مواد عالية الجودة", "اختبار غمر قبل التسليم", "ضمان طويل", "توفير في الكهرباء"],
        "faq": [
            ("ما الفرق بين العزل المائي والحراري؟", "العزل المائي يمنع تسرب المياه، والحراري يقلل انتقال الحرارة. ويمكن الجمع بينهما بعزل الفوم."),
            ("كم مدة ضمان العزل؟", "تختلف حسب نوع المادة، ونحدد مدة الضمان كتابياً في العقد."),
            ("هل عزل الخزانات آمن على مياه الشرب؟", "نعم، نستخدم إيبوكسي مخصصاً للتلامس مع مياه الشرب."),
        ],
    },
    {
        "slug": "moving-storage", "icon": "truck", "color": "#8a5cd0",
        "name": "نقل وتخزين الأثاث",
        "title": "شركة نقل عفش وتخزين أثاث | فك وتركيب وتغليف",
        "tagline": "ننقل أثاثك بأمان من الباب إلى الباب",
        "desc": "نقل عفش وأثاث داخل المدينة وبين المدن مع الفك والتركيب والتغليف الاحترافي، ومستودعات تخزين أثاث آمنة ونظيفة بأسعار مناسبة.",
        "intro": "قسم نقل وتخزين الأثاث في لؤلؤة المستقل يتولى المهمة كاملة: فك الأثاث وتغليفه بمواد حماية، تحميله في سيارات مغلقة مجهزة، ثم تركيبه في موقعك الجديد. ونوفّر مستودعات تخزين مؤمّنة ومحمية من الرطوبة والحشرات لفترات قصيرة أو طويلة.",
        "services": [
            ("نقل العفش داخل المدينة", "نقل سريع ومنظم للشقق والفلل والمكاتب."),
            ("نقل بين المدن", "سيارات مغلقة مجهزة لنقل الأثاث لمسافات طويلة."),
            ("فك وتركيب الأثاث", "نجارون لفك وتركيب غرف النوم والمطابخ والستائر."),
            ("تغليف احترافي", "تغليف بالكرتون والفقاعات والبطانيات لحماية القطع."),
            ("تخزين الأثاث", "مستودعات نظيفة ومؤمّنة ومعالجة ضد الحشرات والرطوبة."),
            ("رافعات أثاث", "رافعات للأدوار العليا لنقل القطع الكبيرة بأمان."),
        ],
        "features": ["سيارات مغلقة", "تغليف احترافي", "مستودعات مؤمّنة", "التزام بالمواعيد"],
        "faq": [
            ("هل تشمل الخدمة الفك والتركيب؟", "نعم، يمكن طلب الخدمة كاملة من الفك والتغليف حتى التركيب في الموقع الجديد."),
            ("هل المستودعات آمنة؟", "مستودعاتنا مغلقة ومراقبة ومعالجة دورياً ضد الحشرات والرطوبة."),
            ("كيف يتم احتساب السعر؟", "حسب حجم الأثاث والمسافة والدور، ونقدّم سعراً واضحاً بعد المعاينة أو الصور."),
        ],
    },
    {
        "slug": "pools", "icon": "pool", "color": "#0f86c9",
        "name": "خدمات المسابح",
        "title": "إنشاء وصيانة المسابح | تنظيف مسابح وتركيب فلاتر ومضخات",
        "tagline": "مسبح نظيف وصافٍ طوال العام",
        "desc": "إنشاء مسابح خرسانية وفايبر، تنظيف وصيانة دورية للمسابح، معالجة كيميائية للمياه، تركيب وصيانة الفلاتر والمضخات والإنارة، وتبليط وعزل المسابح.",
        "intro": "يقدّم قسم المسابح في مؤسسة لؤلؤة المستقل خدمات متكاملة من التصميم والإنشاء إلى الصيانة الدورية. نهتم بجودة المياه وسلامة المعدات ونظافة الأحواض، لتستمتع بمسبحك بأمان طوال العام.",
        "services": [
            ("إنشاء المسابح", "تصميم وتنفيذ مسابح خرسانية وفايبر بمقاسات مختلفة."),
            ("تنظيف المسابح", "شفط القاع وتنظيف الجدران والخط المائي والفلاتر."),
            ("معالجة المياه", "ضبط الكلور ودرجة الحموضة ومعالجة الطحالب والعكارة."),
            ("الفلاتر والمضخات", "تركيب وصيانة واستبدال الفلاتر والمضخات وغرف التشغيل."),
            ("تبليط وعزل المسابح", "عزل الأحواض وتركيب البلاط والموزاييك."),
            ("إنارة وشلالات", "تركيب إنارة تحت الماء وشلالات ونوافير ديكورية."),
        ],
        "features": ["عقود صيانة دورية", "مواد معالجة آمنة", "فنيون متخصصون", "تصاميم عصرية"],
        "faq": [
            ("كم مرة يحتاج المسبح للتنظيف؟", "ننصح بتنظيف أسبوعي في الصيف وكل أسبوعين في الشتاء مع فحص المياه."),
            ("لماذا يتحول ماء المسبح للأخضر؟", "بسبب الطحالب نتيجة نقص الكلور أو ضعف الفلترة، ونعالجه بالصدمة الكيميائية والتنظيف."),
            ("هل تنفذون مسابح جديدة؟", "نعم، من التصميم وحتى التشغيل والتسليم."),
        ],
    },
    {
        "slug": "contracting", "icon": "build", "color": "#6b7280",
        "name": "المقاولات العامة",
        "title": "مقاولات عامة | بناء عظم وتشطيب وترميم ملاحق",
        "tagline": "من الأساس حتى التسليم",
        "desc": "مقاولات عامة: بناء عظم، تشطيب تسليم مفتاح، ترميم المباني القديمة، بناء ملاحق ومجالس، أعمال بلاط ورخام وجبس، وأسوار ومظلات.",
        "intro": "قسم المقاولات العامة في لؤلؤة المستقل ينفّذ مشاريعك السكنية والتجارية بإشراف هندسي والتزام بالجدول الزمني. نقدّم مقايسات واضحة وعقوداً مفصلة، ونتابع كل مرحلة من الحفر والأساسات حتى التشطيب والتسليم.",
        "services": [
            ("بناء العظم", "أساسات وهيكل خرساني ومباني بلوك وفق المخططات."),
            ("تشطيب تسليم مفتاح", "لياسة وبلاط وكهرباء وسباكة ودهانات حتى التسليم."),
            ("ترميم المباني", "معالجة التشققات وتقوية الخرسانة وتجديد المباني القديمة."),
            ("ملاحق ومجالس", "بناء ملاحق وغرف سطح ومجالس خارجية."),
            ("بلاط ورخام", "تركيب البلاط والبورسلان والرخام للأرضيات والجدران."),
            ("أسوار ومظلات", "بناء الأسوار وتركيب المظلات والسواتر وبيوت الشعر."),
        ],
        "features": ["إشراف هندسي", "عقود ومقايسات واضحة", "التزام بالجدول الزمني", "مواد مطابقة للمواصفات"],
        "faq": [
            ("هل تقدمون عرض سعر مفصلاً؟", "نعم، بعد المعاينة نقدّم مقايسة مفصلة بالبنود والكميات والمدة."),
            ("هل يوجد إشراف هندسي؟", "نعم، تتم متابعة المشروع بإشراف فني وهندسي في كل مرحلة."),
            ("هل تنفذون الترميم فقط؟", "نعم، ننفذ أعمال الترميم الجزئية والكاملة حسب حاجتك."),
        ],
    },
    {
        "slug": "decor-painting", "icon": "paint", "color": "#c8507a",
        "name": "الديكورات والدهانات",
        "title": "دهانات وديكورات داخلية | ورق جدران وجبس بورد وبديل خشب",
        "tagline": "لمسة أنيقة تليق ببيتك",
        "desc": "قسم خاص للديكورات والدهانات: دهانات داخلية وخارجية، ورق جدران، جبس بورد وأسقف معلقة، بديل الخشب والرخام، ديكورات حديثة وكلاسيكية، ودهانات إيبوكسي.",
        "intro": "القسم الخاص للديكورات والدهانات في مؤسسة لؤلؤة المستقل يحوّل مساحاتك إلى تصاميم عصرية تعكس ذوقك. نساعدك في اختيار الألوان والخامات، ونقدّم تصوراً للتصميم قبل التنفيذ، مع دهانات من أفضل الماركات وتشطيب دقيق.",
        "services": [
            ("دهانات داخلية", "دهانات بلاستيك ومخملية وتأثيرات حديثة بألوان مختارة."),
            ("دهانات خارجية", "دهانات واجهات مقاومة للعوامل الجوية وأشعة الشمس."),
            ("ورق الجدران", "تركيب ورق جدران وثري دي بتصاميم متنوعة."),
            ("جبس بورد وأسقف", "أسقف معلقة وإضاءات مخفية وكرانيش وبرامج ديكور."),
            ("بديل الخشب والرخام", "تكسيات جدران عصرية بديل الخشب والرخام والشيبورد."),
            ("دهانات إيبوكسي", "أرضيات إيبوكسي للمواقف والمستودعات والصالات."),
        ],
        "features": ["تصميم قبل التنفيذ", "ماركات دهان موثوقة", "تشطيب دقيق", "ألوان عصرية"],
        "faq": [
            ("هل تساعدون في اختيار الألوان؟", "نعم، يقدّم فريق الديكور استشارة لاختيار الألوان والخامات المناسبة للمساحة والإضاءة."),
            ("هل الدهان برائحة قوية؟", "نستخدم دهانات منخفضة الروائح وصديقة للبيئة عند الطلب."),
            ("كم يستغرق دهان شقة؟", "غالباً من 3 إلى 5 أيام حسب المساحة وعدد الطبقات والمعالجات."),
        ],
    },
]


def icon(name, cls="ic"):
    return f'<svg class="{cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{ICONS[name]}</svg>'


def wa_link(text):
    from urllib.parse import quote
    return f"https://wa.me/{CONFIG['whatsapp']}?text={quote(text)}"


def ld(obj):
    return '<script type="application/ld+json">' + json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "</script>"


def business_ld():
    b = CONFIG["base_url"]
    return {
        "@context": "https://schema.org",
        "@type": "HomeAndConstructionBusiness",
        "@id": b + "#business",
        "name": CONFIG["name"],
        "alternateName": CONFIG["short"],
        "url": b,
        "logo": b + "img/icon-512.png",
        "image": b + "img/og.png",
        "telephone": "+" + CONFIG["whatsapp"],
        "areaServed": {"@type": "Country", "name": CONFIG["area"]},
        "openingHours": "Mo-Su 08:00-23:00",
        "hasOfferCatalog": {
            "@type": "OfferCatalog",
            "name": "الخدمات المنزلية",
            "itemListElement": [
                {"@type": "OfferCatalog", "name": s["name"], "url": b + s["slug"] + "/",
                 "itemListElement": [{"@type": "Offer", "itemOffered": {"@type": "Service", "name": n}} for n, _ in s["services"]]}
                for s in SECTIONS
            ],
        },
    }


def faq_ld(faqs):
    return {
        "@context": "https://schema.org", "@type": "FAQPage",
        "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faqs],
    }


def head(*, title, desc, canonical, prefix, extra_ld, theme="#0b3b4f"):
    c = CONFIG
    return f"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
<title>{escape(title)}</title>
<meta name="description" content="{escape(desc)}"/>
<meta name="robots" content="index, follow, max-image-preview:large"/>
<meta name="theme-color" content="{theme}"/>
<link rel="canonical" href="{canonical}"/>
<link rel="alternate" hreflang="ar" href="{canonical}"/>

<meta property="og:type" content="website"/>
<meta property="og:locale" content="ar_SA"/>
<meta property="og:site_name" content="{escape(c['name'])}"/>
<meta property="og:title" content="{escape(title)}"/>
<meta property="og:description" content="{escape(desc)}"/>
<meta property="og:url" content="{canonical}"/>
<meta property="og:image" content="{c['base_url']}img/og.png"/>
<meta property="og:image:width" content="1200"/>
<meta property="og:image:height" content="630"/>
<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:title" content="{escape(title)}"/>
<meta name="twitter:description" content="{escape(desc)}"/>
<meta name="twitter:image" content="{c['base_url']}img/og.png"/>

<link rel="manifest" href="{prefix}manifest.webmanifest"/>
<link rel="icon" type="image/svg+xml" href="{prefix}img/logo.svg"/>
<link rel="icon" type="image/png" sizes="32x32" href="{prefix}img/favicon-32.png"/>
<link rel="apple-touch-icon" href="{prefix}img/apple-touch-icon.png"/>
<meta name="apple-mobile-web-app-capable" content="yes"/>
<meta name="mobile-web-app-capable" content="yes"/>
<meta name="apple-mobile-web-app-title" content="{escape(c['short'])}"/>
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>

<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
<link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet"/>
<link rel="stylesheet" href="{prefix}assets/style.css"/>
{''.join(ld(x) for x in extra_ld)}
</head>
"""


def topbar(prefix, back=False):
    left = (f'<a class="iconbtn" href="{prefix}" aria-label="رجوع للرئيسية">{icon("back")}</a>' if back
            else f'<button class="iconbtn" id="installBtn" hidden aria-label="تثبيت التطبيق">{icon("install")}</button>')
    return f"""<header class="topbar">
  <div class="wrap topbar-in">
    {left}
    <a class="brand" href="{prefix}">
      <img src="{prefix}img/logo.svg" width="38" height="38" alt="شعار {escape(CONFIG['short'])}"/>
      <span><b>{escape(CONFIG['short'])}</b><small>للخدمات المنزلية</small></span>
    </a>
    <a class="iconbtn" href="tel:{CONFIG['phone']}" aria-label="اتصال">{icon("phone")}</a>
  </div>
</header>
"""


def booking_form(prefix, selected=None):
    opts = "".join(
        f'<option value="{escape(s["name"])}"{" selected" if s["slug"] == selected else ""}>{escape(s["name"])}</option>'
        for s in SECTIONS)
    return f"""<section class="card book" id="book" aria-labelledby="book-h">
  <h2 id="book-h">{icon("calendar")} احجز خدمتك الآن</h2>
  <p class="muted">املأ البيانات وسيصلنا طلبك مباشرة عبر واتساب، ونتواصل معك لتأكيد الموعد والسعر.</p>
  <form id="bookForm" data-wa="{CONFIG['whatsapp']}" novalidate>
    <label>الاسم<input name="name" required autocomplete="name" placeholder="اسمك الكريم"/></label>
    <label>رقم الجوال<input name="phone" required type="tel" inputmode="tel" autocomplete="tel" placeholder="05xxxxxxxx"/></label>
    <label>القسم<select name="section">{opts}</select></label>
    <label>الحي / المدينة<input name="area" required placeholder="مثال: حي النرجس"/></label>
    <label>الموعد المفضّل<input name="date" type="date"/></label>
    <label class="full">تفاصيل الطلب<textarea name="notes" rows="3" placeholder="صف الخدمة المطلوبة باختصار"></textarea></label>
    <p class="form-err full" id="formErr" role="alert" hidden>فضلاً أكمل الاسم ورقم الجوال والحي.</p>
    <button class="btn btn-wa full" type="submit">{WA_SVG} إرسال الطلب عبر واتساب</button>
  </form>
</section>
"""


def footer(prefix, active):
    c = CONFIG
    links = "".join(f'<li><a href="{prefix}{s["slug"]}/">{escape(s["name"])}</a></li>' for s in SECTIONS)
    nav = [("home", prefix, "الرئيسية", "home"), ("grid", prefix + "#services", "الأقسام", "services"),
           ("calendar", "#book", "احجز", "book"), ("phone", f"tel:{c['phone']}", "اتصال", "call")]
    tabs = "".join(
        f'<a href="{h}" class="{"on" if k == active else ""}">{icon(i)}<span>{t}</span></a>' for i, h, t, k in nav)
    return f"""<footer class="footer">
  <div class="wrap">
    <div class="foot-brand"><img src="{prefix}img/logo.svg" width="44" height="44" alt="" loading="lazy"/><div><b>{escape(c['name'])}</b><small>{escape(c['hours'])}</small></div></div>
    <nav aria-label="أقسام المؤسسة"><ul class="foot-links">{links}</ul></nav>
    <p class="copy">© <span id="yr">2026</span> {escape(c['name'])}. جميع الحقوق محفوظة.</p>
  </div>
</footer>
<a class="fab-wa" href="{wa_link('السلام عليكم، أرغب في الاستفسار عن خدماتكم')}" target="_blank" rel="noopener" aria-label="تواصل عبر واتساب">{WA_SVG}</a>
<nav class="tabbar" aria-label="التنقل السريع">{tabs}</nav>
<script src="{prefix}assets/app.js" defer></script>
</body>
</html>
"""


def section_card(s, prefix, h="h3"):
    return f"""<a class="svc" href="{prefix}{s['slug']}/" style="--c:{s['color']}" data-search="{escape(s['name'] + ' ' + ' '.join(n for n, _ in s['services']))}">
  <span class="svc-ic">{icon(s['icon'])}</span>
  <{h}>{escape(s['name'])}</{h}>
  <p>{escape(s['tagline'])}</p>
</a>"""


def build_home():
    c, p = CONFIG, ""
    cards = "\n".join(section_card(s, p) for s in SECTIONS)
    why = [("badge", "فريق محترف", "فنيون مدرّبون وذوو خبرة في كل قسم."),
           ("tag", "أسعار واضحة", "عرض سعر قبل البدء بدون رسوم مخفية."),
           ("clock", "التزام بالمواعيد", "نصلك في الموعد المحدد دون تأخير."),
           ("star", "ضمان الجودة", "ضمان مكتوب على الأعمال المنفذة.")]
    why_html = "".join(f'<div class="why">{icon(i)}<h3>{t}</h3><p>{d}</p></div>' for i, t, d in why)
    steps = [("اختر القسم", "حدد الخدمة التي تحتاجها من أقسامنا الثمانية."),
             ("أرسل طلبك", "عبر نموذج الحجز أو واتساب أو الاتصال المباشر."),
             ("نؤكد الموعد", "نتواصل معك لتحديد الموعد والسعر."),
             ("ننفّذ بإتقان", "يصلك الفريق وينجز العمل بضمان.")]
    steps_html = "".join(f'<li><b>{escape(t)}</b><span>{escape(d)}</span></li>' for t, d in steps)
    faqs = [("ما الخدمات التي تقدمها مؤسسة لؤلؤة المستقل؟",
             "نقدّم ثمانية أقسام: مكافحة الحشرات، التنظيف، الصيانة، العزل، نقل وتخزين الأثاث، المسابح، المقاولات العامة، وقسم خاص للديكورات والدهانات."),
            ("كيف أحجز خدمة؟", "اختر القسم ثم املأ نموذج الحجز ليصلنا طلبك عبر واتساب، أو اتصل بنا مباشرة."),
            ("هل المعاينة مجانية؟", "نعم، نوفّر معاينة وتقدير تكلفة قبل البدء في معظم الخدمات."),
            ("ما أوقات العمل؟", c["hours"] + "، مع إمكانية تلبية الطلبات الطارئة.")]
    faq_html = "".join(f"<details><summary>{escape(q)}</summary><p>{escape(a)}</p></details>" for q, a in faqs)

    title = f"{c['name']} | مكافحة حشرات، تنظيف، صيانة، عزل، نقل أثاث، مسابح، مقاولات وديكور"
    desc = "مؤسسة لؤلؤة المستقل للخدمات المنزلية: مكافحة حشرات، تنظيف منازل، صيانة شاملة، عزل أسطح، نقل وتخزين أثاث، مسابح، مقاولات عامة، وديكورات ودهانات. احجز الآن عبر واتساب."
    website = {"@context": "https://schema.org", "@type": "WebSite", "name": c["name"], "url": c["base_url"], "inLanguage": "ar"}
    html = head(title=title, desc=desc, canonical=c["base_url"], prefix=p,
                extra_ld=[business_ld(), website, faq_ld(faqs)])
    html += "<body>\n" + topbar(p) + f"""<main class="wrap">
  <section class="hero">
    <div class="pearl" aria-hidden="true"></div>
    <h1>{escape(c['name'])}</h1>
    <p class="lead">كل ما يحتاجه بيتك في تطبيق واحد: ثمانية أقسام متخصصة بفريق محترف وضمان على الجودة.</p>
    <div class="hero-cta">
      <a class="btn btn-wa" href="#book">{WA_SVG} احجز الآن</a>
      <a class="btn btn-ghost" href="tel:{c['phone']}">{icon('phone')} اتصل بنا</a>
    </div>
  </section>

  <section id="services" aria-labelledby="svc-h">
    <div class="sec-head"><h2 id="svc-h">أقسامنا</h2><span class="muted">8 أقسام</span></div>
    <label class="search">{icon('grid')}<input id="svcSearch" type="search" placeholder="ابحث عن خدمة... مثل: صراصير، كنب، مكيف" aria-label="ابحث عن خدمة"/></label>
    <div class="svc-grid" id="svcGrid">
{cards}
    </div>
    <p class="muted empty" id="svcEmpty" hidden>لا توجد نتائج، جرّب كلمة أخرى أو تواصل معنا مباشرة.</p>
  </section>

  <section aria-labelledby="why-h">
    <h2 id="why-h" class="sec-title">لماذا لؤلؤة المستقل؟</h2>
    <div class="why-grid">{why_html}</div>
  </section>

  <section class="card" aria-labelledby="steps-h">
    <h2 id="steps-h">كيف تطلب الخدمة؟</h2>
    <ol class="steps">{steps_html}</ol>
  </section>

{booking_form(p)}
  <section class="card" aria-labelledby="faq-h">
    <h2 id="faq-h">الأسئلة الشائعة</h2>
    <div class="faq">{faq_html}</div>
  </section>
</main>
""" + footer(p, "home")
    write("index.html", html)


def build_section(s):
    c, p = CONFIG, "../"
    url = c["base_url"] + s["slug"] + "/"
    subs = "".join(f'<li>{icon("check")}<div><h3>{escape(n)}</h3><p>{escape(d)}</p></div></li>' for n, d in s["services"])
    feats = "".join(f"<span>{icon('check')}{escape(f)}</span>" for f in s["features"])
    faq_html = "".join(f"<details><summary>{escape(q)}</summary><p>{escape(a)}</p></details>" for q, a in s["faq"])
    others = "\n".join(section_card(o, p, "h3") for o in SECTIONS if o is not s)
    title = f"{s['title']} | {c['short']}"
    service = {
        "@context": "https://schema.org", "@type": "Service", "name": s["name"], "serviceType": s["name"],
        "description": s["desc"], "url": url, "areaServed": c["area"],
        "provider": {"@id": c["base_url"] + "#business", "@type": "HomeAndConstructionBusiness", "name": c["name"]},
        "hasOfferCatalog": {"@type": "OfferCatalog", "name": s["name"],
                            "itemListElement": [{"@type": "Offer", "itemOffered": {"@type": "Service", "name": n, "description": d}} for n, d in s["services"]]},
    }
    crumbs = {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": c["short"], "item": c["base_url"]},
        {"@type": "ListItem", "position": 2, "name": s["name"], "item": url}]}
    html = head(title=title, desc=s["desc"], canonical=url, prefix=p,
                extra_ld=[service, crumbs, faq_ld(s["faq"])], theme=s["color"])
    html += f'<body style="--c:{s["color"]}">\n' + topbar(p, back=True) + f"""<main class="wrap">
  <nav class="crumbs" aria-label="مسار التنقل"><a href="{p}">الرئيسية</a> <span>/</span> <span aria-current="page">{escape(s['name'])}</span></nav>
  <section class="hero hero-sec">
    <span class="hero-ic">{icon(s['icon'])}</span>
    <h1>{escape(s['name'])}</h1>
    <p class="lead">{escape(s['tagline'])}</p>
    <div class="chips">{feats}</div>
    <div class="hero-cta">
      <a class="btn btn-wa" href="{wa_link('السلام عليكم، أرغب في طلب خدمة: ' + s['name'])}" target="_blank" rel="noopener">{WA_SVG} اطلب عبر واتساب</a>
      <a class="btn btn-ghost" href="#book">{icon('calendar')} نموذج الحجز</a>
    </div>
  </section>

  <section class="card" aria-labelledby="about-h">
    <h2 id="about-h">{escape(s['name'])} مع {escape(c['short'])}</h2>
    <p>{escape(s['intro'])}</p>
  </section>

  <section class="card" aria-labelledby="list-h">
    <h2 id="list-h">خدمات قسم {escape(s['name'])}</h2>
    <ul class="sub-list">{subs}</ul>
  </section>

{booking_form(p, s['slug'])}
  <section class="card" aria-labelledby="faq-h">
    <h2 id="faq-h">أسئلة شائعة عن {escape(s['name'])}</h2>
    <div class="faq">{faq_html}</div>
  </section>

  <section aria-labelledby="more-h">
    <h2 id="more-h" class="sec-title">أقسام أخرى قد تهمك</h2>
    <div class="svc-grid">
{others}
    </div>
  </section>
</main>
""" + footer(p, "services")
    write(os.path.join(s["slug"], "index.html"), html)


def build_meta():
    c = CONFIG
    manifest = {
        "name": c["name"], "short_name": c["short"], "id": "./",
        "description": "اطلب خدمات مكافحة الحشرات والتنظيف والصيانة والعزل ونقل الأثاث والمسابح والمقاولات والديكور.",
        "lang": "ar", "dir": "rtl", "start_url": "./", "scope": "./", "display": "standalone",
        "orientation": "portrait", "background_color": "#f7f5f0", "theme_color": "#0b3b4f",
        "categories": ["lifestyle", "business"],
        "icons": [
            {"src": "img/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any"},
            {"src": "img/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any"},
            {"src": "img/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
        "shortcuts": [{"name": s["name"], "url": f"./{s['slug']}/"} for s in SECTIONS[:4]],
    }
    write("manifest.webmanifest", json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    urls = [c["base_url"]] + [c["base_url"] + s["slug"] + "/" for s in SECTIONS]
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    sitemap += "".join(f"  <url><loc>{u}</loc><changefreq>monthly</changefreq><priority>{'1.0' if i == 0 else '0.8'}</priority></url>\n"
                       for i, u in enumerate(urls))
    write("sitemap.xml", sitemap + "</urlset>\n")

    pages = ["./", "./index.html"] + [f"./{s['slug']}/" for s in SECTIONS]
    assets = ["./assets/style.css", "./assets/app.js", "./manifest.webmanifest", "./img/logo.svg",
              "./img/icon-192.png", "./img/icon-512.png", "./img/apple-touch-icon.png", "./img/favicon-32.png"]
    sw = open(os.path.join(ROOT, "sw.template.js"), encoding="utf-8").read()
    write("sw.js", sw.replace("/*ASSETS*/", json.dumps(pages + assets, indent=2)))


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


if __name__ == "__main__":
    build_home()
    for s in SECTIONS:
        build_section(s)
    build_meta()
    print("built", 1 + len(SECTIONS), "pages")
