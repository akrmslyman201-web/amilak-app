import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kBorder, kCard, kGreen;

class WorkerRequestsTab extends StatefulWidget {
  const WorkerRequestsTab({super.key});

  @override
  State<WorkerRequestsTab> createState() => _WorkerRequestsTabState();
}

class _WorkerRequestsTabState extends State<WorkerRequestsTab> {
  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final r = await sb.rpc('request_inbox');
      items = List<Map<String, dynamic>>.from(r as List);
    } catch (e) {
      items = [];
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> respond(String id, bool accept) async {
    try {
      await sb.rpc('respond_request', params: {'rid': id, 'accept': accept});
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
    }
  }

  Widget card(Map<String, dynamic> r) {
    final st = (r['req_status'] ?? '').toString();
    final accepted = st == 'accepted';
    final pending = st == 'pending';
    final date = (r['req_created'] ?? '').toString();
    final note = (r['req_note'] ?? '').toString();
    final color = accepted
        ? const Color(0xFF12A36B)
        : pending
            ? const Color(0xFFE08A00)
            : Colors.redAccent;
    final label = accepted
        ? 'مقبول'
        : pending
            ? 'بانتظار ردك'
            : 'مرفوض';
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
          Row(
            children: [
              Expanded(
                child: Text('${r['cust_name'] ?? 'عميل'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          if (date.length >= 10)
            Text(date.substring(0, 10),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('الوصف: $note'),
            ),
          if (accepted && r['cust_phone'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('هاتف العميل: ${r['cust_phone']}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      color: kGreen, fontWeight: FontWeight.bold)),
            ),
          if (pending)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                        onPressed: () => respond(r['req_id'].toString(), true),
                        child: const Text('قبول')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => respond(r['req_id'].toString(), false),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ),
            ),
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
              const Expanded(
                child: Text('طلبات العملاء',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text('لا توجد طلبات بعد'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [for (final r in items) card(r)],
                    ),
        ),
      ],
    );
  }
}
