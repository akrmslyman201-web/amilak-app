import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kCard;

class WorkerExtras extends StatefulWidget {
  final Map<String, dynamic>? w;
  const WorkerExtras({super.key, required this.w});

  @override
  State<WorkerExtras> createState() => _WorkerExtrasState();
}

class _WorkerExtrasState extends State<WorkerExtras> {
  String status = 'available';
  List<Map<String, dynamic>> subs = [];
  List<Map<String, dynamic>> rates = [];

  String t(dynamic v) => v == null ? '' : v.toString();
  String d(dynamic v) {
    final s = t(v);
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  void initState() {
    super.initState();
    status = t(widget.w?['availability']).isEmpty
        ? 'available'
        : t(widget.w?['availability']);
    loadAll();
  }

  Future<void> loadAll() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final s = await sb
          .from('subscriptions')
          .select()
          .eq('worker_id', uid)
          .order('starts_at', ascending: false);
      subs = List<Map<String, dynamic>>.from(s);
    } catch (_) {}
    try {
      final r = await sb.from('ratings').select().eq('worker_id', uid);
      rates = List<Map<String, dynamic>>.from(r);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> setStatus(String v) async {
    final old = status;
    setState(() => status = v);
    try {
      await sb
          .from('workers')
          .update({'availability': v}).eq('id', sb.auth.currentUser!.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => status = old);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تغيير الحالة، حاول مرة أخرى')),
      );
    }
  }

  Widget box(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );

  Widget statusBtn(String label, String v, Color c) {
    final on = status == v;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: () => setStatus(v),
          style: OutlinedButton.styleFrom(
            backgroundColor: on ? c.withOpacity(0.25) : null,
            side: BorderSide(color: on ? c : Colors.white24),
          ),
          child: Text(label,
              style: TextStyle(color: on ? c : Colors.white70, fontSize: 13)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w ?? <String, dynamic>{};
    final prof = t(w['profession'] ?? w['profession_name']);
    final place = [t(w['state']), t(w['city'])]
        .where((e) => e.isNotEmpty)
        .join('، ');
    double avg = 0;
    if (rates.isNotEmpty) {
      avg = rates.fold<double>(
              0, (a, r) => a + ((r['stars'] as num?) ?? 0).toDouble()) /
          rates.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prof.isNotEmpty)
              Text(prof,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent)),
            if (place.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(place,
                    style: const TextStyle(color: Colors.white70)),
              ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${avg.toStringAsFixed(1)}  (${rates.length} تقييم)'),
            ]),
          ],
        )),
        box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حالتي الآن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('تظهر هذه الحالة للعملاء في نتائج البحث',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              statusBtn('متاح الآن', 'available', Colors.greenAccent),
              statusBtn('مشغول', 'busy', Colors.orangeAccent),
              statusBtn('غير متاح', 'unavailable', Colors.grey),
            ]),
          ],
        )),
        box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سجل الاشتراكات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (subs.isEmpty)
              const Text('لا توجد اشتراكات بعد',
                  style: TextStyle(color: Colors.white54)),
            for (final s in subs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${t(s['amount'])} جنيه'),
                subtitle: Text(
                    '${d(s['starts_at'])} ← ${d(s['ends_at'] ?? s['expires_at'])}'),
                trailing: Text(
                  t(s['status']) == 'confirmed' ? 'مؤكدة' : t(s['status']),
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ),
          ],
        )),
        box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تقييمات العملاء',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (rates.isEmpty)
              const Text('لا توجد تقييمات بعد',
                  style: TextStyle(color: Colors.white54)),
            for (final r in rates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('⭐ ${t(r['stars'])}'),
                subtitle: Text(t(r['comment'])),
              ),
          ],
        )),
      ],
    );
  }
}
