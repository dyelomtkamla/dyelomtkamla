import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/event_type.dart';
import '../models/family_event.dart';
import 'event_card.dart';

/// قائمة مناسبات مع فلتر حسب النوع وحالات التحميل/الفراغ/الخطأ.
class EventsList extends StatefulWidget {
  const EventsList({
    super.key,
    required this.stream,
    required this.me,
    required this.emptyText,
  });

  final Stream<List<FamilyEvent>> stream;
  final AppUser me;
  final String emptyText;

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  EventType? _filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip(null, 'الكل', Icons.apps),
              for (final t in EventType.values) _chip(t, t.label, t.icon),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FamilyEvent>>(
            stream: widget.stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return const _Message(
                    icon: Icons.cloud_off, text: 'تعذر تحميل المناسبات، تأكد من الإنترنت.');
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final events = _filter == null
                  ? snap.data!
                  : snap.data!.where((e) => e.type == _filter).toList();
              if (events.isEmpty) {
                return _Message(icon: Icons.event_busy, text: widget.emptyText);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => EventCard(event: events[i], me: widget.me),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(EventType? type, String label, IconData icon) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          selected: _filter == type,
          onSelected: (_) => setState(() => _filter = type),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
