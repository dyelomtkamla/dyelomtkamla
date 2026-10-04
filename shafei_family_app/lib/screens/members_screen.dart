import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/member_service.dart';

/// أفراد العائلة + طلبات الانضمام (تظهر للمسؤول فقط).
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.me});
  final AppUser me;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _members = MemberService.instance.members();
  late final _pending = widget.me.isAdmin ? MemberService.instance.pending() : null;

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      _snack(done);
    } catch (_) {
      _snack('تعذر تنفيذ العملية');
    }
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (_pending != null)
          StreamBuilder<List<AppUser>>(
            stream: _pending,
            builder: (context, snap) {
              final list = snap.data ?? const [];
              if (list.isEmpty) return const SliverToBoxAdapter();
              return SliverList.list(children: [
                _header(context, 'طلبات انضمام (${list.length})'),
                for (final u in list)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_add)),
                      title: Text(u.name),
                      subtitle: Text('${u.branch}\n${u.phone}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'قبول',
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _run(() => MemberService.instance.approve(u.uid),
                                'تم قبول ${u.name}'),
                          ),
                          IconButton(
                            tooltip: 'رفض',
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _run(() => MemberService.instance.reject(u.uid),
                                'تم رفض الطلب'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ]);
            },
          ),
        StreamBuilder<List<AppUser>>(
          stream: _members,
          builder: (context, snap) {
            if (snap.hasError) {
              return const SliverFillRemaining(
                  child: Center(child: Text('تعذر تحميل أفراد العائلة')));
            }
            if (!snap.hasData) {
              return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()));
            }
            final list = snap.data!;
            return SliverList.list(children: [
              _header(context, 'أفراد العائلة (${list.length})'),
              for (final u in list)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(u.name.isEmpty ? '؟' : u.name.characters.first),
                  ),
                  title: Text(u.name + (u.uid == widget.me.uid ? ' (أنت)' : '')),
                  subtitle: Text([u.branch, u.phone].where((s) => s.isNotEmpty).join(' • ')),
                  trailing: u.isAdmin
                      ? const Chip(label: Text('مسؤول'), visualDensity: VisualDensity.compact)
                      : widget.me.isAdmin
                          ? PopupMenuButton<String>(
                              tooltip: 'خيارات',
                              onSelected: (_) => _run(
                                  () => MemberService.instance.setAdmin(u.uid, true),
                                  '${u.name} أصبح مسؤولاً'),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'admin', child: Text('تعيين كمسؤول')),
                              ],
                            )
                          : null,
                ),
              const SizedBox(height: 24),
            ]);
          },
        ),
      ],
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
