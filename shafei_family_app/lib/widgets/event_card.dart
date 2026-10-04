import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/family_event.dart';
import '../screens/event_details_screen.dart';

String formatEventDate(DateTime d) => DateFormat('EEEE d MMMM y • h:mm a', 'ar').format(d);

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.me});

  final FamilyEvent event;
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = event.type;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: event.id, me: me))),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: t.color, width: 6)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: t.color.withValues(alpha: 0.15),
                child: Icon(t.icon, color: t.color, semanticLabel: t.label),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.label,
                        style: theme.textTheme.labelMedium?.copyWith(color: t.color)),
                    Text(event.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(formatEventDate(event.date), style: theme.textTheme.bodySmall),
                    if (event.location.isNotEmpty)
                      Text('📍 ${event.location}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (event.attendees.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.people, size: 16),
                  label: Text('${event.attendees.length}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
