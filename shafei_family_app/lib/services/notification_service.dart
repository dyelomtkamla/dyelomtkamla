import 'package:firebase_messaging/firebase_messaging.dart';

/// كل أفراد العائلة المعتمدين يشتركون في موضوع "family"
/// فتصلهم إشعارات المناسبات الجديدة (راجع functions/index.js).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const topic = 'family';

  Future<void> subscribe() async {
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      await fm.subscribeToTopic(topic);
    } catch (_) {
      // الإشعارات ميزة إضافية؛ لا نوقف التطبيق إذا فشلت.
    }
  }

  Future<void> unsubscribe() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }
}
