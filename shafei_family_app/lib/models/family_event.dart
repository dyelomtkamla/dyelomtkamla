import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_type.dart';

class FamilyEvent {
  const FamilyEvent({
    this.id = '',
    required this.type,
    required this.title,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    this.description = '',
    this.location = '',
    this.attendees = const [],
  });

  final String id;
  final EventType type;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String createdBy;
  final String createdByName;
  final List<String> attendees;

  factory FamilyEvent.fromMap(String id, Map<String, dynamic> m) => FamilyEvent(
        id: id,
        type: EventType.fromId(m['type'] as String?),
        title: (m['title'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: (m['createdBy'] ?? '') as String,
        createdByName: (m['createdByName'] ?? '') as String,
        attendees: List<String>.from(m['attendees'] ?? const []),
      );

  /// الحقول القابلة للتعديل (الحضور يُدار منفصلاً).
  Map<String, dynamic> toMap() => {
        'type': type.id,
        'title': title,
        'description': description,
        'location': location,
        'date': Timestamp.fromDate(date),
        'createdBy': createdBy,
        'createdByName': createdByName,
      };

  bool isAttending(String uid) => attendees.contains(uid);
  bool get isPast => date.isBefore(DateTime.now());
}
