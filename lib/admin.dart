import 'package:flutter/material.dart';

import 'admin_lists.dart';
import 'admin_subs.dart';
import 'admin_verify.dart';
import 'common.dart';
import 'main.dart' show kBg;

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int tab = 0;

  static const titles = [
    'توثيق الحرفيين',
    'الاشتراكات',
    'المهن',
    'الولايات والمدن',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        backgroundColor: kBg,
        actions: [
          IconButton(
              onPressed: () => sb.auth.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: const [
          VerifyTab(),
          SubsTab(),
          ProfessionsTab(),
          StatesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: kBg,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined), label: 'التوثيق'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'الاشتراكات'),
          NavigationDestination(
              icon: Icon(Icons.build_outlined), label: 'المهن'),
          NavigationDestination(
              icon: Icon(Icons.location_on_outlined), label: 'الولايات'),
        ],
      ),
    );
  }
}
