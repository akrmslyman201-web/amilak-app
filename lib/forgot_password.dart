import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'common.dart';
import 'main.dart' show kBg, kGreen;
import 'pw_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailC = TextEditingController();
  final codeC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();
  bool sent = false;
  bool busy = false;

  String digits(String s) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    var o = s.trim();
    for (var i = 0; i < ar.length; i++) {
      o = o.replaceAll(ar[i], '$i');
    }
    return o;
  }

  Future<void> sendCode() async {
    final email = emailC.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      msg(context, 'اكتب بريدك الإلكتروني الصحيح');
      return;
    }
    setState(() => busy = true);
    try {
      await sb.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() => sent = true);
        msg(context, 'أرسلنا رمزاً إلى بريدك، وتحقق أيضاً من البريد المزعج');
      }
    } on AuthException catch (e) {
      if (mounted) msg(context, 'تعذر الإرسال: ${e.message}');
    } catch (_) {
      if (mounted) msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> reset() async {
    final code = digits(codeC.text);
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(code)) {
      msg(context, 'اكتب الرمز الذي وصلك على البريد');
      return;
    }
    if (passC.text.length < 6) {
      msg(context, 'كلمة المرور لا تقل عن 6 أحرف');
      return;
    }
    if (passC.text != pass2C.text) {
      msg(context, 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() => busy = true);
    try {
      await sb.auth.verifyOTP(
        email: emailC.text.trim(),
        token: code,
        type: OtpType.recovery,
      );
      await sb.auth.updateUser(UserAttributes(password: passC.text));
      if (mounted) {
        msg(context, 'تم تغيير كلمة المرور');
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
      return;
    } on AuthException catch (e) {
      if (mounted) msg(context, 'تعذر التغيير: ${e.message}');
    } catch (_) {
      if (mounted) msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        backgroundColor: kBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            sent
                ? 'اكتب الرمز الذي وصل إلى بريدك، ثم كلمة المرور الجديدة.'
                : 'اكتب بريدك الإلكتروني وسنرسل لك رمزاً لتغيير كلمة المرور.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          tf(emailC, 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              ltr: true,
              type: TextInputType.emailAddress),
          if (sent) ...[
            tf(codeC, 'الرمز',
                icon: Icons.pin_outlined,
                ltr: true,
                type: TextInputType.number),
            PasswordField(controller: passC, label: 'كلمة المرور الجديدة'),
            PasswordField(controller: pass2C, label: 'أعد كتابة كلمة المرور'),
          ],
          FilledButton(
            onPressed: busy ? null : (sent ? reset : sendCode),
            style: FilledButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: kBg,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(busy
                ? 'لحظة...'
                : sent
                    ? 'تغيير كلمة المرور'
                    : 'إرسال الرمز'),
          ),
          if (sent)
            TextButton(
              onPressed: busy ? null : sendCode,
              child: const Text('إعادة إرسال الرمز'),
            ),
        ],
      ),
    );
  }
}
