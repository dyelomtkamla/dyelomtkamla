// إعدادات ربط التطبيق بمشروع Firebase: omda-family
// (مفاتيح Firebase دي معرّفات عامة، والحماية الحقيقية في firestore.rules)
// FIREBASE_NOT_CONFIGURED: القيم دي لسه هتتملى من google-services.json الخاص بمشروع omda-family.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('التطبيق مخصص للأندرويد والآيفون فقط');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('التطبيق مخصص للأندرويد والآيفون فقط');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'ANDROID_API_KEY',
    appId: 'ANDROID_APP_ID',
    messagingSenderId: 'PROJECT_NUMBER',
    projectId: 'omda-family',
    storageBucket: 'omda-family.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'IOS_API_KEY',
    appId: 'IOS_APP_ID',
    messagingSenderId: 'PROJECT_NUMBER',
    projectId: 'omda-family',
    storageBucket: 'omda-family.firebasestorage.app',
    iosBundleId: 'com.alomda.omdaFamily',
  );
}
