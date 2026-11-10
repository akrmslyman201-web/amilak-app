import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin.dart';
import 'common.dart';
import 'forgot_password.dart';
import 'main.dart' show Home, kBg, kGreen;
import 'pw_field.dart';
import 'shell.dart';
import 'signup.dart';
import 'welcome.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: sb.auth.onAuthStateChange,
      builder: (context, snap) {
        if (sb.auth.currentSession == null) return const WelcomePage();
        return const RoleRouter();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool busy = false;

  Future<void> login() async {
    final email = emailC.text.trim();
    if (email.isEmpty || passC.text.isEmpty) {
      msg(context, 'اكتب البريد وكلمة المرور');
      return;
    }
    setState(() => busy = true);
    try {
      await sb.auth.signInWithPassword(email: email, password: passC.text);
    } on AuthException catch (e) {
      if (mounted) {
        msg(
            context,
            e.message.toLowerCase().contains('invalid')
                ? 'البريد أو كلمة المرور غير صحيحة'
                : 'تعذر الدخول: ${e.message}');
      }
    } catch (_) {
      if (mounted) msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: kGreen, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.build, color: kBg, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
                child: Text('عاملك علينا',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            const Center(
                child: Text('أقرب حرفي إليك',
                    style: TextStyle(color: Colors.white60))),
            const SizedBox(height: 28),
            tf(emailC, 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                ltr: true,
                type: TextInputType.emailAddress),
            PasswordField(controller: passC),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage())),
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
            FilledButton(
              onPressed: busy ? null : login,
              style: FilledButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: kBg,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(busy ? 'جاري الدخول...' : 'تسجيل الدخول'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupPage())),
              child: const Text('حرفي جديد؟ أنشئ حسابك'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Home())),
              child: const Text('تصفح كزائر'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<Map<String, dynamic>> f;

  @override
  void initState() {
    super.initState();
    f = load();
  }

  Future<Map<String, dynamic>> load() async {
    final r = await sb
        .from('profiles')
        .select('role, full_name')
        .eq('id', sb.auth.currentUser!.id)
        .single();
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (s.hasError || s.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعذر تحميل الحساب'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      f = load();
                    }),
                    child: const Text('إعادة المحاولة'),
                  ),
                  TextButton(
                    onPressed: () => sb.auth.signOut(),
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          );
        }
        final role = s.data!['role'];
        final name = (s.data!['full_name'] ?? '').toString();
        if (role == 'worker') return WorkerShell(name: name);
        if (role == 'admin') return const AdminHome();
        return CustomerShell(name: name);
      },
    );
  }
}
