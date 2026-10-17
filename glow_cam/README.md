# GlowCam — جلو كام ✨

تطبيق سيلفي احترافي لأندرويد وآيفون (Flutter): كاميرا أمامية بفلاتر مباشرة، فصل الخلفية
بالذكاء الاصطناعي على الجهاز، تجميل البشرة، وفلاتر "Pro" مدفوعة بنظام اشتراك داخل التطبيق.

## المميزات

| القسم | ما يقدمه |
|------|---------|
| الكاميرا | كاميرا أمامية/خلفية، فلاش، معاينة الفلتر مباشرة قبل التصوير، فتح صورة من المعرض |
| الفلاتر | 14 فلتر: طبيعي، ذهبي، ناعم، حيوي، أبيض وأسود + فلاتر Pro: كريمي، وردي، سينمائي، فينتاج، ثلجي، نيون، إشراقة، استوديو، غروب — مع شريط شدة |
| الخلفية | فصل الشخص عن الخلفية (Google ML Kit Selfie Segmentation، بدون إنترنت): بورتريه (تغبيش)، أبيض، أسود + Pro: استوديو، غروب، محيط، لافندر، روز، ذهبية، خلفية من صورك |
| تجميل | نعومة البشرة، توهج (Glow)، إطار داكن (Vignette) |
| ضبط | الإضاءة، التباين، التشبع، الدفء |
| حفظ ومشاركة | حفظ بدقة كاملة (حتى 2048px) في ألبوم GlowCam، ومشاركة مباشرة لسناب/إنستغرام/واتساب |
| مقارنة | اضغط مطولاً على الصورة لعرض الأصل |
| Pro | جرّب الفلاتر المدفوعة مجاناً — عند الحفظ تظهر شاشة الاشتراك (شهري/سنوي) |

الواجهة عربية بالكامل (RTL) وبثيم داكن.

## هيكل المشروع

```
lib/
  main.dart, app.dart
  core/            color_matrix.dart (رياضيات الألوان), theme.dart
  features/
    camera/        camera_screen.dart — الشاشة الرئيسية
    editor/        editor_screen.dart, editor_controller.dart,
                   photo_painter.dart (المحرك: نفس الرسم للمعاينة والتصدير),
                   photo_loader.dart (تدوير EXIF + عكس السيلفي + تصغير)
    filters/       filter_preset.dart — تعريف الفلاتر
    background/    background_option.dart, segmentation_service.dart
    pro/           pro_service.dart (المشتريات), paywall_screen.dart
    export/        export_service.dart (حفظ/مشاركة)
test/              اختبارات الوحدات والرسم
```

إضافة فلتر جديد = إضافة عنصر واحد في `filterPresets` داخل `filter_preset.dart`.

## التشغيل

المتطلبات: Flutter 3.3x+ ، Android Studio (لأندرويد)، Xcode 16+ على ماك (لآيفون).

```bash
cd glow_cam
flutter pub get
flutter test               # الاختبارات
flutter run                # على جهاز حقيقي (الكاميرا لا تعمل على المحاكي)
```

ملاحظات:
- **iOS**: الحد الأدنى iOS 15.5. ML Kit لا يعمل على محاكي Apple Silicon — جرّب على آيفون حقيقي.
  أول مرة: `cd ios && pod install`.
- **Android**: الحد الأدنى Android 7.0 (API 24).
- في وضع التطوير (debug) يوجد زر "تفعيل تجريبي" في شاشة Pro لتجربة كل المميزات بدون شراء.

## تفعيل الاشتراك المدفوع

1. أنشئ اشتراكين بالمعرفات `glowcam_pro_monthly` و `glowcam_pro_yearly`:
   - Google Play Console ← Monetize ← Subscriptions
   - App Store Connect ← Subscriptions (ضمن Subscription Group واحد)
2. ارفع نسخة على Internal testing / TestFlight حتى تظهر المنتجات.
3. **للإنتاج**: تحقق من الإيصالات على السيرفر (مثلاً API بـ ASP.NET Core يستدعي
   Google Play Developer API و App Store Server API) بدل الاعتماد على العلامة المحلية فقط.

## النشر

```bash
# Android (.aab لمتجر Google Play)
flutter build appbundle --release

# iOS
flutter build ipa --release
```

- غيّر `applicationId` / Bundle ID (`com.glowcam.glow_cam`) لمعرّفك الخاص.
- أنشئ مفتاح توقيع Android وأضفه في `android/key.properties`.
- أضف أيقونة التطبيق (مثلاً بحزمة `flutter_launcher_icons`).
- املأ نموذج Data safety (Play) و Privacy labels (Apple): الصور تُعالج على الجهاز فقط ولا تُرفع لأي سيرفر.

### ASO — كلمات مقترحة لصفحة المتجر
**العنوان:** GlowCam: كاميرا سيلفي وفلاتر
**الوصف المختصر:** فلاتر سيلفي احترافية، تغيير الخلفية، وتجميل البشرة بلمسة واحدة.
**كلمات مفتاحية:** كاميرا سيلفي، فلاتر، تغيير الخلفية، إزالة الخلفية، تجميل، بورتريه، selfie camera, beauty filter, background changer
