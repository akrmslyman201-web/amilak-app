import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;
import 'worker_sub.dart' show fmt;

class SubsTab extends StatefulWidget {
  const SubsTab({super.key});

  @override
  State<SubsTab> createState() => _SubsTabState();
}

class _SubsTabState extends State<SubsTab> {
  String status = 'pending';
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  Map<String, Map<String, dynamic>> people = {};

  static const labels = {
    'pending': 'بانتظار التأكيد',
    'confirmed': 'مؤكدة',
    'rejected': 'مرفوضة',
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await sb
          .from('subscriptions')
          .select()
          .eq('status', status)
          .eq('kind', 'paid')
          .order('created_at', ascending: false);
      items = List<Map<String, dynamic>>.from(r);
      final ids = items.map((s) => s['worker_id'] as String).toSet().toList();
      people = {};
      if (ids.isNotEmpty) {
        final p = await sb
            .from('profiles')
            .select('id, full_name, phone')
            .inFilter('id', ids);
        for (final x in p) {
          people[x['id'] as String] = Map<String, dynamic>.from(x);
        }
      }
    } catch (e) {
      items = [];
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> confirm(Map<String, dynamic> s) async {
    final wid = s['worker_id'] as String;
    String d(DateTime t) => t.toIso8601String().substring(0, 10);
    try {
      final today = DateTime.now();
      final act = await sb
          .from('subscriptions')
          .select('ends_at')
          .eq('worker_id', wid)
          .eq('status', 'confirmed')
          .gte('ends_at', d(today))
          .order('ends_at', ascending: false)
          .limit(1);
      final list = act as List;
      var start = DateTime(today.year, today.month, today.day);
      if (list.isNotEmpty) {
        start = DateTime.parse(list.first['ends_at'] as String)
            .add(const Duration(days: 1));
      }
      final end = start.add(const Duration(days: 30));
      await sb.from('subscriptions').update({
        'status': 'confirmed',
        'starts_at': d(start),
        'ends_at': d(end),
        'reject_reason': null,
      }).eq('id', s['id'] as String);
      if (mounted) msg(context, 'تم تأكيد الاشتراك حتى ${d(end)}');
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
    }
  }

  Future<void> reject(Map<String, dynamic> s) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: c,
          decoration:
              const InputDecoration(hintText: 'مثال: لم يصل التحويل'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('رفض')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reason = c.text.trim();
    if (reason.isEmpty) {
      msg(context, 'اكتب سبب الرفض');
      return;
    }
    try {
      await sb.from('subscriptions').update({
        'status': 'rejected',
        'reject_reason': reason,
      }).eq('id', s['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
    }
  }

  Widget card(Map<String, dynamic> s) {
    final p = people[s['worker_id']] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p['full_name'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${p['phone'] ?? ''}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          Text('المبلغ: ${s['amount']} جنيه'),
          Text('آخر 4 أرقام من الإشعار: ${s['notice_last4'] ?? ''}',
              style: const TextStyle(
                  color: kGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('تاريخ الإرسال: ${fmt(s['created_at'])}',
              style: const TextStyle(color: Colors.white60)),
          if (s['ends_at'] != null)
            Text('ساري حتى: ${fmt(s['ends_at'])}',
                style: const TextStyle(color: Colors.white60)),
          if (s['status'] == 'rejected' &&
              (s['reject_reason'] ?? '').toString().isNotEmpty)
            Text('السبب: ${s['reject_reason']}',
                style: const TextStyle(color: Colors.white60)),
          if (status == 'pending') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                    onPressed: () => confirm(s), child: const Text('تأكيد')),
                OutlinedButton(
                    onPressed: () => reject(s),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent),
                    child: const Text('رفض')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final e in labels.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: status == e.key,
                        showCheckmark: false,
                        selectedColor: kGreen,
                        labelStyle: TextStyle(
                            color: status == e.key ? kBg : Colors.white,
                            fontWeight: FontWeight.bold),
                        onSelected: (_) {
                          status = e.key;
                          load();
                        },
                      ),
                  ],
                ),
              ),
              IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text('لا توجد إشعارات في هذه القائمة'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [for (final s in items) card(s)],
                    ),
        ),
      ],
    );
  }
}
