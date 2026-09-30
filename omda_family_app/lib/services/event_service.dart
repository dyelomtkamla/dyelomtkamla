import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_event.dart';

class EventService {
  EventService._();
  static final instance = EventService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('events');

  List<FamilyEvent> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => FamilyEvent.fromMap(d.id, d.data())).toList();

  /// المناسبات القادمة (ومناسبات اليوم).
  Stream<List<FamilyEvent>> upcoming() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .snapshots()
        .map(_map);
  }

  Stream<List<FamilyEvent>> past() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _col
        .where('date', isLessThan: Timestamp.fromDate(startOfToday))
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map(_map);
  }

  Stream<FamilyEvent?> watch(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? FamilyEvent.fromMap(d.id, d.data()!) : null);

  Future<void> create(FamilyEvent e) => _col.add({
        ...e.toMap(),
        'attendees': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> update(FamilyEvent e) => _col.doc(e.id).update(e.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> setAttending(String id, String uid, bool attending) =>
      _col.doc(id).update({
        'attendees': attending
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
      });
}
