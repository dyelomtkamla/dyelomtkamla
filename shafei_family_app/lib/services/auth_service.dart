import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'notification_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Stream<AppUser?> profile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromMap(d.id, d.data()!) : null);

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String branch,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name.trim());
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'branch': branch.trim(),
      'approved': false,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await NotificationService.instance.unsubscribe();
    await _auth.signOut();
  }

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'البريد أو كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'هذا البريد مسجل بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
        case 'network-request-failed':
          return 'تأكد من اتصال الإنترنت';
        case 'too-many-requests':
          return 'محاولات كثيرة، حاول بعد قليل';
      }
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }
}
