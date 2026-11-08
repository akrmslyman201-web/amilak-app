import 'package:flutter/material.dart';

import 'auth.dart';
import 'customer_signup.dart';
import 'main.dart' show kBg, kGreen;
import 'signup.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget bigButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String sub,
    required Widget page,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.handyman, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text('عاملك علينا',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('أقرب حرفي إليك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 36),
              bigButton(
                context,
                icon: Icons.search,
                title: 'أنا عميل',
                sub: 'أبحث عن حرفي أو عامل',
                page: const CustomerSignupPage(),
                color: kGreen,
              ),
              const SizedBox(height: 16),
              bigButton(
                context,
                icon: Icons.handyman,
                title: 'أنا عامل',
                sub: 'أريد عرض خدماتي والحصول على عملاء',
                page: const SignupPage(),
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text('لدي حساب؟ تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
