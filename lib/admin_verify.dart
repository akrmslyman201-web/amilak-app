import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;

class VerifyTab extends StatefulWidget {
  const VerifyTab({super.key});

  @override
  State<VerifyTab> createState() => _VerifyTabState();
}

class _VerifyTabState extends State<VerifyTab> {
  String status = 'pending';
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  Map<String, Map<String, dynamic>> people = {};
  Map<String, String> jobs = {};
  Map<String, String> states = {};

  static const labels = {
    'pending': 'قيد المراجعة',
    'approved': 'موثّقون',
    'rejected': 'مرفوضون',
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
          .from('workers')
          .select()
          .eq('verification_status', status)
          .not('id_doc_url', 'is', null)
          .order('created_at', ascending: false);
      items = List<Map<String, dynamic>>.from(r);
      final ids = items.map((w) => w['id'] as String).toList();
      people = {};
      if (ids.isNotEmpty) {
        final p = await sb
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', ids);
        for (final x in p) {
          people[x['id'] as String] = Map<String, dynamic>.from(x);
        }
        final c = await sb
            .from('worker_contacts')
            .select('worker_id, phone')
            .inFilter('worker_id', ids);
        for (final x in c) {
          people[x['worker_id'] as String] = {
            ...?people[x['worker_id'] as String],
            'phone': x['phone'],
          };
        }
      }
      final pj = await sb.from('professions').select('id, name');
      jobs = {for (final x in pj) x['id'] as String: x['name'] as String};
      final ss = await sb.from('states').select('id, name');
      states = {for (final x in ss) x['id'] as String: x['name'] as String};
    } catch (e) {
      items = [];
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> showDoc(Map<String, dynamic> w) async {
    try {
      final url = await sb.storage
          .from('id-docs')
          .createSignedUrl(w['id_doc_url'] as String, 300);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      );
    } catch (_) {
      if (mounted) msg(context, 'تعذر فتح المستند');
    }
  }

  Future<void> approve(Map<String, dynamic> w) async {
    final id = w['id'] as String;
    try {
      await sb.from('workers').update({
        'verified': true,
        'verification_status': 'approved',
        'reject_reason': null,
      }).eq('id', id);
      final has =
          await sb.from('subscriptions').select('id').eq('worker_id', id).limit(1);
      if ((has as List).isEmpty) {
        final now = DateTime.now();
        final end = now.add(const Duration(days: 60));
        String d(DateTime t) => t.toIso8601String().substring(0, 10);
        await sb.from('subscriptions').insert({
          'worker_id': id,
          'amount': 0,
          'status': 'confirmed',
          'kind': 'free',
          'starts_at': d(now),
          'ends_at': d(end),
        });
      }
      if (mounted) msg(context, 'تم توثيق الحساب وفتحه شهرين مجاناً');
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
    }
  }

  Future<void> reject(Map<String, dynamic> w) async {
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
    if (ok != true || !mounted) return;
    final reason = c.text.trim();
    if (reason.isEmpty) {
      msg(context, 'اكتب سبب الرفض');
      return;
    }
    try {
      await sb.from('workers').update({
        'verified': false,
        'verification_status': 'rejected',
        'reject_reason': reason,
      }).eq('id', w['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
    }
  }

  Widget card(Map<String, dynamic> w) {
    final id = w['id'] as String;
    final p = people[id] ?? {};
    final job = jobs[w['profession_id']] ?? '';
    final st = states[w['state_id']] ?? '';
    final city = (w['city'] ?? '').toString();
    final photo = w['photo_url'] as String?;
    final doc = docTypes[w['id_doc_type']] ?? '';
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
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: photo == null ? null : NetworkImage(photo),
                child: photo == null
                    ? const Icon(Icons.person, color: Colors.black26)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p['full_name'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(job,
                        style: const TextStyle(
                            color: kGreen, fontWeight: FontWeight.bold)),
                    Text('$city، $st',
                        style: const TextStyle(color: Colors.white60)),
                    Text('${p['phone'] ?? ''}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('المستند: $doc',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                  onPressed: () => showDoc(w),
                  child: const Text('عرض المستند')),
              if (status != 'approved')
                FilledButton(
                    onPressed: () => approve(w), child: const Text('قبول')),
              if (status == 'pending')
                OutlinedButton(
                    onPressed: () => reject(w),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent),
                    child: const Text('رفض')),
            ],
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
                  ? const Center(child: Text('لا توجد طلبات في هذه القائمة'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [for (final w in items) card(w)],
                    ),
        ),
      ],
    );
  }
}
