import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'common.dart';
import 'main.dart' show kBg;

class CustomerSignupPage extends StatefulWidget {
  const CustomerSignupPage({super.key});

  @override
  State<CustomerSignupPage> createState() => _CustomerSignupPageState();
}

class _CustomerSignupPageState extends State<CustomerSignupPage> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool busy = false;
  bool hide = true;

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final name = nameC.text.trim();
    final phone = phoneC.text.trim();
    final email = emailC.text.trim();
    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      msg(context, 'أكمل كل الحقول');
      return;
    }
    if (passC.text.length < 6) {
      msg(context, 'كلمة المرور 6 أحرف على الأقل');
      return;
    }
    setState(() => busy = true);
    try {
      final res = await sb.auth.signUp(
        email: email,
        password: passC.text,
        data: {'role': 'customer', 'full_name': name, 'phone': phone},
      );
      if (!mounted) return;
      if (res.session == null) {
        msg(context, 'تم إنشاء الحساب. تحقق من بريدك ثم سجّل الدخول');
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) msg(context, 'تعذر إنشاء الحساب: ${e.message}');
    } catch (_) {
      if (mounted) msg(context, 'تحقق من الإنترنت وحاول مرة أخرى');
    }
    if (mounted) setState(() => busy = false);
  }

  Widget field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool pass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: pass && hide,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: pass
              ? IconButton(
                  icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => hide = !hide),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('حساب عميل جديد'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          field(nameC, 'الاسم الكامل', Icons.person),
          field(phoneC, 'رقم الهاتف', Icons.phone, type: TextInputType.phone),
          field(emailC, 'البريد الإلكتروني', Icons.email,
              type: TextInputType.emailAddress),
          field(passC, 'كلمة المرور', Icons.lock, pass: true),
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? 'جارٍ الإنشاء...' : 'إنشاء الحساب'),
            ),
          ),
        ],
      ),
    );
  }
}
