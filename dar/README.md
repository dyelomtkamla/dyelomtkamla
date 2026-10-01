# دار (Dar): صفحة الهبوط وقائمة الانتظار

تطبيق لإدارة البيت والعاملة المنزلية بالذكاء الاصطناعي: مترجم صوتي فوري بين الأسرة والعاملة، وتنظيم المهام والوصفات والمقاضي، وتنبيهات الإقامة والعقد. السوق الأول هو الخليج (السعودية والإمارات أولاً).

المجلد ده فيه **صفحة الهبوط** مبنية بـ ASP.NET Core 8 (Razor Pages)، وهدفها نختبر الفكرة ونجمع مستخدمين قبل ما نبني التطبيق.

## المحتوى
- صفحة عربي (`/`) وصفحة إنجليزي (`/en`)، بنفس المحتوى، ونفس الكلام موجود في ملف واحد هو `Content/SiteText.cs`.
- نموذج تسجيل في قائمة الانتظار، محفوظ في SQLite، وعليه حماية CSRF وحد أقصى 5 تسجيلات كل 10 دقايق لكل IP.
- **SEO:** عنوان ووصف وكلمات مفتاحية لكل لغة، وcanonical وhreflang (ar / en / x-default)، وOpen Graph وTwitter Card بصورة `img/og.png`، وJSON-LD (Organization وWebSite وMobileApplication وFAQPage)، و`/sitemap.xml` و`/robots.txt` بيتعملوا تلقائياً، وصفحات 404 عليها noindex.
- **أداء وأمان:** ضغط Brotli/Gzip، وcache للملفات الثابتة، وهيدرز أمان (CSP وX-Frame-Options وغيرها)، والعربي بيطلع في الـ HTML زي ما هو من غير ما يتحول لرموز.
- صفحة خصوصية (`/privacy` و`/en/privacy`).

## التشغيل
```bash
cd dar/Dar.Web
dotnet run
# افتح http://localhost:5010
```

## الإعدادات (appsettings.json أو متغيرات البيئة)
| المفتاح | الوظيفة |
|---|---|
| `Site__BaseUrl` | الدومين النهائي، مثلاً `https://dar.app`. بيتستخدم في canonical وsitemap وOG |
| `ConnectionStrings__Dar` | مسار قاعدة SQLite (الافتراضي `dar.db`) |
| `Admin__Key` | مفتاح تحميل قائمة الانتظار CSV |

تحميل قائمة المسجلين:
```bash
curl -H "X-Admin-Key: <المفتاح>" https://<الدومين>/admin/waitlist.csv -o waitlist.csv
```
لو المفتاح فاضي، الرابط بيرجع 404.

## بعد النشر
1. اضبط `Site__BaseUrl` على الدومين الحقيقي.
2. سجّل الموقع في Google Search Console وBing Webmaster، وارفع `sitemap.xml`.
3. ركّز على كلمات بحث زي: "ترجمة للخادمة"، "مترجم فلبيني عربي"، "تجديد إقامة العاملة"، "وصفات للعاملة المنزلية".
