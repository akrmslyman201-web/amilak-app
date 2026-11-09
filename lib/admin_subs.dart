import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kCard;

class SubsTab extends StatefulWidget {
  const SubsTab({super.key});

  @override
  State<SubsTab> createState() => _SubsTabState();
}

class _SubsTabState extends State<SubsTab> {
  String filter = 'pending';
  bool loading = true;
  List<Map<String, dynamic>> subs = [];
  Map<String, String> names = {};

  String t(dynamic v) => v == null ? '' : v.toString();
  String ds(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final s = await sb
          .from('subscriptions')
          .select()
          .eq('status', filter)
          .order('created_at', ascending: false);
      subs = List<Map<String, dynamic>>.from(s);
    } catch (_) {
      subs = [];
      if (mounted) msg(context, 'تعذر تحميل الاشتراكات');
    }
    try {
      final w = await sb.from('workers').select();
      names = {
        for (final e in List<Map<String, dynamic>>.from(w))
          t(e['id']): t(e['full_name'] ?? e['name'])
      };
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> showReceipt(String path) async {
    try {
      final url = await sb.storage.from('receipts').createSignedUrl(path, 600);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(child: Image.network(url)),
        ),
      );
    } catch (_) {
      if (mounted) msg(context, 'تعذر فتح الصورة');
    }
  }

  Future<void> approve(Map<String, dynamic> s) async {
    try {
      final now = DateTime.now();
      var start = DateTime(now.year, now.month, now.day);
      final prev = await sb
          .from('subscriptions')
          .select('ends_at')
          .eq('worker_id', s['worker_id'])
          .eq('status', 'confirmed')
          .order('ends_at', ascending: false)
          .limit(1);
      if (prev.isNotEmpty) {
        final e = DateTime.tryParse(t(prev.first['ends_at']));
        if (e != null && e.isAfter(start)) start = e;
      }
      final end = start.add(const Duration(days: 30));
      await sb.from('subscriptions').update({
        'status': 'confirmed',
        'starts_at': ds(start),
        'ends_at': ds(end),
        'reject_reason': null,
      }).eq('id', s['id']);
      if (mounted) msg(context, 'تم القبول: ساري حتى ${ds(end)}');
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر القبول');
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
          decoration: const InputDecoration(hintText: 'مثال: الصورة غير واضحة'),
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
    if (ok != true) return;
    try {
      await sb.from('subscriptions').update({
        'status': 'rejected',
        'reject_reason': c.text.trim(),
      }).eq('id', s['id']);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الرفض');
    }
  }

  Widget chip(String label, String v) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: filter == v,
          onSelected: (_) {
            setState(() => filter = v);
            load();
          },
        ),
      );

  Widget card(Map<String, dynamic> s) {
    final name = names[t(s['worker_id'])] ?? '';
    final receipt = t(s['receipt_url']);
    final created = t(s['created_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.isEmpty ? 'عامل' : name,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${t(s['amount'])} جنيه'
              '${created.length >= 10 ? '  •  ${created.substring(0, 10)}' : ''}'),
          if (filter == 'confirmed')
            Text('${t(s['starts_at'])} ← ${t(s['ends_at'])}',
                style: const TextStyle(color: Colors.greenAccent)),
          if (filter == 'rejected' && t(s['reject_reason']).isNotEmpty)
            Text('السبب: ${t(s['reject_reason'])}',
                style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 10),
          Row(children: [
            if (receipt.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => showReceipt(receipt),
                icon: const Icon(Icons.image, size: 18),
                label: const Text('عرض الإشعار'),
              ),
          ]),
          if (filter == 'pending') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                    onPressed: () => approve(s), child: const Text('قبول')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                    onPressed: () => reject(s), child: const Text('رفض')),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              chip('قيد المراجعة', 'pending'),
              chip('مؤكدة', 'confirmed'),
              chip('مرفوضة', 'rejected'),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: subs.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 80),
                          Center(
                              child: Text('لا توجد اشتراكات هنا',
                                  style: TextStyle(color: Colors.white60))),
                        ])
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: [for (final s in subs) card(s)],
                        ),
                ),
        ),
      ],
    );
  }
}
