import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kBorder, kCard;

Future<bool> confirmDialog(BuildContext context, String text) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(text),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد')),
      ],
    ),
  );
  return r == true;
}

Future<bool> formDialog(BuildContext context, String title,
    Map<String, TextEditingController> fields) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in fields.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(controller: e.value, decoration: dec(e.key)),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ')),
      ],
    ),
  );
  return r == true;
}

BoxDecoration rowBox() => BoxDecoration(
    color: kCard,
    border: Border.all(color: kBorder),
    borderRadius: BorderRadius.circular(16));

List<String> parseCities(String s) => s
    .split(RegExp(r'[,،]'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

class ProfessionsTab extends StatefulWidget {
  const ProfessionsTab({super.key});

  @override
  State<ProfessionsTab> createState() => _ProfessionsTabState();
}

class _ProfessionsTabState extends State<ProfessionsTab> {
  final addC = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await sb.from('professions').select().order('name');
      items = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final name = addC.text.trim();
    if (name.isEmpty) return;
    try {
      await sb.from('professions').insert({'name': name});
      addC.clear();
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الإضافة، ربما المهنة موجودة');
    }
  }

  Future<void> toggle(Map<String, dynamic> p, bool v) async {
    try {
      await sb
          .from('professions')
          .update({'active': v}).eq('id', p['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر التحديث');
    }
  }

  Future<void> rename(Map<String, dynamic> p) async {
    final c = TextEditingController(text: p['name'] as String);
    final ok = await formDialog(context, 'تعديل المهنة', {'الاسم': c});
    if (!ok || c.text.trim().isEmpty) return;
    try {
      await sb
          .from('professions')
          .update({'name': c.text.trim()}).eq('id', p['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر التعديل');
    }
  }

  Future<void> remove(Map<String, dynamic> p) async {
    if (!await confirmDialog(context, 'حذف مهنة ${p['name']}؟')) return;
    try {
      await sb.from('professions').delete().eq('id', p['id'] as String);
      await load();
    } catch (_) {
      if (mounted) {
        msg(context, 'لا يمكن حذف مهنة عليها حرفيون، أوقف المفتاح لإخفائها');
      }
    }
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
                  child: TextField(
                      controller: addC, decoration: dec('اسم مهنة جديدة'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('إضافة')),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final p in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: rowBox(),
                        child: Row(
                          children: [
                            Switch(
                                value: p['active'] == true,
                                onChanged: (v) => toggle(p, v)),
                            Expanded(
                                child: Text('${p['name']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            IconButton(
                                onPressed: () => rename(p),
                                icon: const Icon(Icons.edit_outlined)),
                            IconButton(
                                onPressed: () => remove(p),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class StatesTab extends StatefulWidget {
  const StatesTab({super.key});

  @override
  State<StatesTab> createState() => _StatesTabState();
}

class _StatesTabState extends State<StatesTab> {
  final nameC = TextEditingController();
  final citiesC = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await sb.from('states').select().order('name');
      items = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final name = nameC.text.trim();
    if (name.isEmpty) return;
    try {
      await sb
          .from('states')
          .insert({'name': name, 'cities': parseCities(citiesC.text)});
      nameC.clear();
      citiesC.clear();
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الإضافة، ربما الولاية موجودة');
    }
  }

  Future<void> toggle(Map<String, dynamic> s, bool v) async {
    try {
      await sb.from('states').update({'active': v}).eq('id', s['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر التحديث');
    }
  }

  Future<void> edit(Map<String, dynamic> s) async {
    final nc = TextEditingController(text: s['name'] as String);
    final cc = TextEditingController(
        text: (s['cities'] as List).map((e) => e.toString()).join('، '));
    final ok = await formDialog(context, 'تعديل الولاية',
        {'اسم الولاية': nc, 'المدن (افصلها بفاصلة)': cc});
    if (!ok || nc.text.trim().isEmpty) return;
    try {
      await sb.from('states').update({
        'name': nc.text.trim(),
        'cities': parseCities(cc.text),
      }).eq('id', s['id'] as String);
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر التعديل');
    }
  }

  Future<void> remove(Map<String, dynamic> s) async {
    if (!await confirmDialog(context, 'حذف ولاية ${s['name']}؟')) return;
    try {
      await sb.from('states').delete().eq('id', s['id'] as String);
      await load();
    } catch (_) {
      if (mounted) {
        msg(context, 'لا يمكن حذف ولاية عليها حرفيون، أوقف المفتاح لإخفائها');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(controller: nameC, decoration: dec('اسم ولاية جديدة')),
              const SizedBox(height: 8),
              TextField(
                  controller: citiesC,
                  decoration: dec('المدن (افصلها بفاصلة)')),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: add, child: const Text('إضافة ولاية')),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final s in items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: rowBox(),
                        child: Row(
                          children: [
                            Switch(
                                value: s['active'] == true,
                                onChanged: (v) => toggle(s, v)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s['name']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    (s['cities'] as List).isEmpty
                                        ? 'لا توجد مدن مضافة'
                                        : (s['cities'] as List).join('، '),
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                                onPressed: () => edit(s),
                                icon: const Icon(Icons.edit_outlined)),
                            IconButton(
                                onPressed: () => remove(s),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
