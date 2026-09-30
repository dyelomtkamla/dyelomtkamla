import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class MemberService {
  MemberService._();
  static final instance = MemberService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users');

  Stream<List<AppUser>> _byApproval(bool approved) => _col
      .where('approved', isEqualTo: approved)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  Stream<List<AppUser>> members() => _byApproval(true);
  Stream<List<AppUser>> pending() => _byApproval(false);

  Future<void> approve(String uid) => _col.doc(uid).update({'approved': true});
  Future<void> reject(String uid) => _col.doc(uid).delete();
  Future<void> setAdmin(String uid, bool value) =>
      _col.doc(uid).update({'isAdmin': value});
}
