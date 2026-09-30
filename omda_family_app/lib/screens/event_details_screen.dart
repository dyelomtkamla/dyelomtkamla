import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/family_event.dart';
import '../services/event_service.dart';
import '../services/member_service.dart';
import '../widgets/event_card.dart';
import 'event_form_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.eventId, required this.me});

  final String eventId;
  final AppUser me;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final _event = EventService.instance.watch(widget.eventId);
  late final _members = MemberService.instance.members();
  bool _busy = false;

  Future<void> _toggleAttendance(FamilyEvent e) async {
    setState(() => _busy = true);
    try {
      await EventService.instance
          .setAttending(e.id, widget.me.uid, !e.isAttending(widget.me.uid));
    } catch (_) {
      _snack('تعذر التحديث، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FamilyEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف المناسبة؟'),
        content: Text('سيتم حذف "${e.title}" من عند كل العائلة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await EventService.instance.delete(e.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _snack('تعذر الحذف');
    }
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyEvent?>(
      stream: _event,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('تعذر تحميل المناسبة')));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final e = snap.data;
        if (e == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('هذه المناسبة لم تعد موجودة')));
        }
        final canManage = e.createdBy == widget.me.uid || widget.me.isAdmin;
        final attending = e.isAttending(widget.me.uid);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(e.type.label),
            actions: [
              if (canManage) ...[
                IconButton(
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EventFormScreen(me: widget.me, existing: e))),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(e),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: e.type.color.withValues(alpha: 0.15),
                  child: Icon(e.type.icon, size: 44, color: e.type.color),
                ),
              ),
              const SizedBox(height: 12),
              Text(e.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(formatEventDate(e.date)),
                    ),
                    if (e.location.isNotEmpty)
                      ListTile(leading: const Icon(Icons.place), title: Text(e.location)),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('أضافها: ${e.createdByName}'),
                    ),
                  ],
                ),
              ),
              if (e.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.description, style: theme.textTheme.bodyLarge),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!e.isPast)
                attending
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        onPressed: _busy ? null : () => _toggleAttendance(e),
                        icon: const Icon(Icons.close),
                        label: const Text('إلغاء الحضور'),
                      )
                    : FilledButton.icon(
                        onPressed: _busy ? null : () => _toggleAttendance(e),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('سأحضر إن شاء الله'),
                      ),
              const SizedBox(height: 24),
              Text('الحضور (${e.attendees.length})', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<List<AppUser>>(
                stream: _members,
                builder: (context, m) {
                  if (e.attendees.isEmpty) return const Text('لم يؤكد أحد حضوره بعد.');
                  if (!m.hasData) return const LinearProgressIndicator();
                  final names = {for (final u in m.data!) u.uid: u.name};
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final uid in e.attendees)
                        Chip(
                          avatar: const Icon(Icons.person, size: 18),
                          label: Text(names[uid] ?? 'فرد من العائلة'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
