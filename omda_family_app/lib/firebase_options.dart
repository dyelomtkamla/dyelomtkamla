// إعدادات ربط التطبيق بمشروع Firebase: omda-family
// (مفاتيح Firebase دي معرّفات عامة، والحماية الحقيقية في firestore.rules)
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
    apiKey: 'AIzaSyCGEl_WqgvfbAYbkHztrCzSS5U7MdjuKQY',
    appId: '1:381960871316:android:052766b6ce16f603b4c381',
    messagingSenderId: '381960871316',
    projectId: 'omda-family',
    storageBucket: 'omda-family.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMQnQDJrX-6fkgbfGxoaZ_KW8aJ1RYpD0',
    appId: '1:381960871316:ios:e82f7fb1c3db45a8b4c381',
    messagingSenderId: '381960871316',
    projectId: 'omda-family',
    storageBucket: 'omda-family.firebasestorage.app',
    iosBundleId: 'com.alomda.omdaFamily',
  );
}
