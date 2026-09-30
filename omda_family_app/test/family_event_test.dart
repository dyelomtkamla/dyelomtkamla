import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omda_family/models/event_type.dart';
import 'package:omda_family/models/family_event.dart';

void main() {
  test('EventType.fromId falls back to other', () {
    expect(EventType.fromId('wedding'), EventType.wedding);
    expect(EventType.fromId('condolence'), EventType.condolence);
    expect(EventType.fromId('unknown'), EventType.other);
    expect(EventType.fromId(null), EventType.other);
  });

  test('FamilyEvent round-trips through a Firestore map', () {
    final date = DateTime(2026, 10, 15, 20, 30);
    final event = FamilyEvent(
      type: EventType.engagement,
      title: 'خطوبة أحمد',
      location: 'بيت العائلة',
      date: date,
      createdBy: 'u1',
      createdByName: 'محمد',
    );
    final map = event.toMap();
    expect(map['type'], 'engagement');
    expect(map['date'], Timestamp.fromDate(date));
    expect(map.containsKey('attendees'), isFalse);

    final back = FamilyEvent.fromMap('e1', {...map, 'attendees': ['u1', 'u2']});
    expect(back.id, 'e1');
    expect(back.type, EventType.engagement);
    expect(back.title, 'خطوبة أحمد');
    expect(back.date, date);
    expect(back.isAttending('u2'), isTrue);
    expect(back.isAttending('u3'), isFalse);
  });
}
