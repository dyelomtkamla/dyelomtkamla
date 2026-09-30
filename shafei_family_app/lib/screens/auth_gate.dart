import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'pending_screen.dart';

/// يقرر أي شاشة تظهر: الدخول، انتظار الموافقة، أو الرئيسية.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _Splash();
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _ProfileGate(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.uid});
  final String uid;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Stream<AppUser?> _profile = AuthService.instance.profile(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _profile,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _Splash();
        final me = snap.data;
        if (snap.hasError || me == null || !me.approved) {
          return PendingScreen(me: me, failed: snap.hasError);
        }
        return HomeScreen(me: me);
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
