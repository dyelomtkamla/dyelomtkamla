import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../widgets/events_list.dart';
import 'event_form_screen.dart';
import 'members_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.me});
  final AppUser me;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _upcoming = EventService.instance.upcoming();
  final _past = EventService.instance.past();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EventsList(
        stream: _upcoming,
        me: widget.me,
        emptyText: 'لا توجد مناسبات قادمة.\nاضغط "مناسبة جديدة" لإضافة فرح أو خطوبة أو عزاء.',
      ),
      EventsList(stream: _past, me: widget.me, emptyText: 'لا توجد مناسبات سابقة.'),
      MembersScreen(me: widget.me),
    ];
    const titles = ['مناسبات العائلة', 'المناسبات السابقة', 'أفراد العائلة'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('تسجيل الخروج؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('خروج')),
                  ],
                ),
              );
              if (ok == true) await AuthService.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: _tab == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EventFormScreen(me: widget.me))),
              icon: const Icon(Icons.add),
              label: const Text('مناسبة جديدة'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'القادمة'),
          NavigationDestination(icon: Icon(Icons.history), label: 'السابقة'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'العائلة'),
        ],
      ),
    );
  }
}
