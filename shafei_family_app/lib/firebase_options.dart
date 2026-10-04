// إعدادات ربط التطبيق بمشروع Firebase: shafei-family-cb881
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
    apiKey: 'AIzaSyA2cuf2RkH8xE_GtF3x4N8DAGIwJk4DOwg',
    appId: '1:518435684255:android:48ab19e3d74d21068047aa',
    messagingSenderId: '518435684255',
    projectId: 'shafei-family-cb881',
    storageBucket: 'shafei-family-cb881.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgsns5bdFz8kMgym6qWBBKv3hIIsWvqa0',
    appId: '1:518435684255:ios:55c773bbde2dd7608047aa',
    messagingSenderId: '518435684255',
    projectId: 'shafei-family-cb881',
    storageBucket: 'shafei-family-cb881.firebasestorage.app',
    iosBundleId: 'com.alshafei.shafeiFamily',
  );
}
