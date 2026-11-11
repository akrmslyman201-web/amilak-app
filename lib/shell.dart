import 'package:flutter/material.dart';

import 'become_worker.dart';
import 'customer.dart';
import 'main.dart' show kBg;
import 'sub_banner.dart';
import 'worker.dart';
import 'worker_requests.dart';

class WorkerShell extends StatefulWidget {
  final String name;
  const WorkerShell({super.key, required this.name});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: tab,
              children: [
                WorkerHome(name: widget.name),
                CustomerHome(name: widget.name),
                const WorkerRequestsTab(),
              ],
            ),
          ),
          SubBanner(onRenew: () => setState(() => tab = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: kBg,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.badge_outlined), label: 'حسابي'),
          NavigationDestination(icon: Icon(Icons.search), label: 'تصفح كعميل'),
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined), label: 'الطلبات'),
        ],
      ),
    );
  }
}

class CustomerShell extends StatefulWidget {
  final String name;
  const CustomerShell({super.key, required this.name});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int tab = 0;
  bool becameWorker = false;

  @override
  Widget build(BuildContext context) {
    if (becameWorker) return WorkerShell(name: widget.name);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          CustomerHome(name: widget.name),
          BecomeWorkerPage(onDone: () => setState(() => becameWorker = true)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: kBg,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'تصفح'),
          NavigationDestination(
              icon: Icon(Icons.handyman_outlined), label: 'كن حرفياً'),
        ],
      ),
    );
  }
}
