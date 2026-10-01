# مؤسسة لؤلؤة المستقل للخدمات المنزلية — ASP.NET Core

تطبيق ويب (Razor Pages / .NET 8) قابل للتثبيت على الجوال، مع لوحة تحكم لإدارة طلبات الحجز.

## المميزات
- **8 أقسام، لكل قسم صفحة مستقلة** برابط واضح: `/pest-control`، `/cleaning`، `/maintenance`، `/insulation`، `/moving-storage`، `/pools`، `/contracting`، `/decor-painting`.
- **SEO**: عنوان ووصف لكل صفحة، رابط canonical، وسوم Open Graph، بيانات منظمة (HomeAndConstructionBusiness, Service, FAQPage, BreadcrumbList)، و`/sitemap.xml` و`/robots.txt` تلقائياً، والنص العربي يخرج كأحرف حقيقية وليس رموزاً مشفّرة.
- **نموذج حجز** يحفظ الطلب في قاعدة البيانات ويعطي العميل رقم طلب وزر متابعة عبر واتساب، مع حماية من السبام (حقل خفي + تحديد عدد المحاولات + رمز anti-forgery).
- **لوحة تحكم** `/admin`: إحصائيات، بحث وتصفية حسب القسم والحالة، تغيير الحالة (جديد / مؤكد / مكتمل / ملغي)، ملاحظات داخلية، تواصل مباشر مع العميل، حذف، وتصدير إلى Excel.
- **PWA**: أيقونات وmanifest، ويعمل بدون إنترنت بعد أول زيارة.

## التشغيل محلياً
```bash
cd LuluaServices
dotnet run --project src/LuluaServices --launch-profile http
```
ثم افتح http://localhost:5065 — لوحة التحكم: http://localhost:5065/admin
(بيانات الدخول في بيئة التطوير فقط: `admin` / `Lulua@Dev2026`).

## الإعدادات قبل النشر (`src/LuluaServices/appsettings.json`)
| الإعداد | الوصف |
|---|---|
| `Business:BaseUrl` | رابط الموقع الحقيقي، مثل `https://lulua.sa`. يُستخدم في canonical وsitemap. |
| `Business:WhatsApp` | رقم واتساب دولي بدون + مثل `9665XXXXXXXX`. |
| `Business:Phone` | رقم الاتصال مثل `05XXXXXXXX`. |
| `Admin:Username` / `Admin:PasswordHash` | دخول لوحة التحكم. أنشئ البصمة بالأمر أدناه. |
| `ConnectionStrings:Default` | مسار قاعدة بيانات SQLite (افتراضياً `App_Data/lulua.db`). |
| `ReverseProxy:Enabled` | اجعله `true` إذا كان التطبيق خلف nginx أو موزّع أحمال. |

إنشاء بصمة كلمة مرور لوحة التحكم:
```bash
dotnet run --project src/LuluaServices -- hash-password "كلمة-مرور-قوية"
```
يفضّل وضع القيم السرية في متغيرات البيئة بدلاً من الملف، مثل `Admin__PasswordHash=...`.

## النشر
```bash
dotnet publish src/LuluaServices -c Release -o publish
```
ارفع مجلد `publish` إلى أي استضافة تدعم ASP.NET Core 8 (Windows/IIS، أو Linux مع nginx، أو Azure App Service)، وتأكد أن مجلد `App_Data` قابل للكتابة.
بعد النشر أضف `https://موقعك/sitemap.xml` في Google Search Console.

## الاختبارات
```bash
dotnet test
```
