import 'package:flutter/material.dart';

class SubsTab extends StatelessWidget {
  const SubsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'قائمة الاشتراكات: قيد الإعداد',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
