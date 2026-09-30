import 'package:flutter/material.dart';

/// أنواع مناسبات العائلة.
enum EventType {
  wedding('wedding', 'فرح', Icons.celebration, Color(0xFFC2185B)),
  engagement('engagement', 'خطوبة', Icons.favorite, Color(0xFF8E24AA)),
  condolence('condolence', 'عزاء', Icons.volunteer_activism, Color(0xFF546E7A)),
  birth('birth', 'مولود / عقيقة', Icons.child_friendly, Color(0xFF0288D1)),
  other('other', 'مناسبة', Icons.event, Color(0xFF2E7D32));

  const EventType(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static EventType fromId(String? id) =>
      EventType.values.firstWhere((t) => t.id == id, orElse: () => EventType.other);
}
