# تطبيق عائلة الشافعي 👨‍👩‍👧‍👦

تطبيق واحد يعمل على **أندرويد وآيفون** (Flutter + Firebase).
كل فرد في العائلة يسجل حسابه، ويقدر يضيف مناسبة (فرح، خطوبة، عزاء، مولود/عقيقة، أو أي مناسبة)
فتظهر عند كل العائلة ويصلهم إشعار على الموبايل.

## المميزات
- تسجيل حساب ودخول واستعادة كلمة المرور.
- **موافقة المسؤول**: أي حساب جديد لا يرى شيئاً حتى يوافق عليه مسؤول العائلة، فالتطبيق خاص بالعائلة فقط.
- إضافة مناسبة: النوع، العنوان، اليوم والساعة، المكان، والتفاصيل.
- قائمة المناسبات القادمة والسابقة، مع فلتر حسب النوع.
- زر **"سأحضر إن شاء الله"** وقائمة بأسماء الحضور.
- صاحب المناسبة أو المسؤول يقدر يعدلها أو يحذفها.
- إشعار لكل العائلة عند إضافة أي مناسبة جديدة.
- شاشة أفراد العائلة: المسؤول يقبل أو يرفض طلبات الانضمام، ويقدر يعيّن مسؤولين آخرين.
- الواجهة كلها بالعربي ومن اليمين لليسار، وتدعم الوضع الليلي.

## التشغيل لأول مرة
1. ثبّت [Flutter](https://docs.flutter.dev/get-started/install) وأداتي Firebase:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
2. أنشئ مشروعاً على [Firebase Console](https://console.firebase.google.com)، ثم فعّل:
   - **Authentication** ← Email/Password
   - **Firestore Database**
3. اربط التطبيق بالمشروع (هذا ينشئ الملف `lib/firebase_options.dart`):
   ```bash
   cd shafei_family_app
   firebase login
   flutterfire configure
   ```
4. انشر قواعد الحماية ودالة الإشعارات (دالة الإشعارات تحتاج خطة **Blaze**، وهي مجانية في حدود الاستخدام العادي):
   ```bash
   firebase use --add
   firebase deploy --only firestore:rules
   (cd functions && npm install) && firebase deploy --only functions
   ```
5. شغّل التطبيق:
   ```bash
   flutter pub get
   flutter run
   ```

## أول مسؤول للعائلة
سجّل حسابك من التطبيق، ثم من Firestore افتح `users/<رقم حسابك>`
وغيّر `approved` إلى `true` و `isAdmin` إلى `true`.
بعد ذلك توافق أنت على باقي أفراد العائلة من داخل التطبيق.

## الإشعارات على الآيفون
في Firebase Console ← Project Settings ← Cloud Messaging ارفع **APNs Key** من حساب Apple Developer،
وفي Xcode فعّل **Push Notifications** و **Background Modes ← Remote notifications**.

## النشر على المتاجر
- أندرويد: `flutter build appbundle` ثم ارفع ملف `.aab` على Google Play Console.
- آيفون: `flutter build ipa` ثم ارفعه على App Store Connect (جرّبه أولاً عبر TestFlight).

## هيكل المشروع
```
lib/
  main.dart                 تشغيل التطبيق + العربية
  models/                   المناسبة، نوع المناسبة، فرد العائلة
  services/                 الحسابات، المناسبات، الأفراد، الإشعارات
  screens/                  الدخول، التسجيل، الانتظار، الرئيسية، إضافة/تفاصيل مناسبة، العائلة
  widgets/                  كارت المناسبة، القائمة، الشعار
firestore.rules             الحماية: المناسبات لا يراها إلا أفراد العائلة المعتمدون
functions/index.js          إرسال إشعار عند إضافة مناسبة
```
