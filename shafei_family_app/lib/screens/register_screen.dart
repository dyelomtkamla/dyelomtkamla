import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _branch = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _branch, _phone, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        branch: _branch.text,
      );
      // AuthGate سيعرض شاشة انتظار الموافقة تلقائياً.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AuthService.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل فرد جديد')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      maxLength: 60,
                      decoration: const InputDecoration(
                          labelText: 'الاسم بالكامل', prefixIcon: Icon(Icons.person)),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'اكتب اسمك بالكامل'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _branch,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'اسم الأب / فرع العائلة',
                        helperText: 'يساعد المسؤول في التعرف عليك',
                        prefixIcon: Icon(Icons.account_tree),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                          labelText: 'رقم الموبايل', prefixIcon: Icon(Icons.phone)),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'أدخل رقماً صحيحاً'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'أدخل بريداً صحيحاً' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock)),
                      validator: (v) => (v == null || v.length < 6)
                          ? '6 أحرف على الأقل'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) =>
                          v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('تسجيل'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
