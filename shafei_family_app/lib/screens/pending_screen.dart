import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// تظهر للحساب الجديد حتى يوافق عليه مسؤول العائلة.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, this.me, this.failed = false});

  final AppUser? me;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = failed
        ? 'تعذر تحميل بيانات حسابك'
        : me == null
            ? 'لم يكتمل تسجيل حسابك'
            : 'أهلاً ${me!.name}';
    final body = failed || me == null
        ? 'تأكد من الإنترنت ثم سجّل الدخول مرة أخرى، أو تواصل مع مسؤول العائلة.'
        : 'حسابك في انتظار موافقة مسؤول العائلة.\nستفتح لك المناسبات تلقائياً بمجرد الموافقة.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(body, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: AuthService.instance.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
