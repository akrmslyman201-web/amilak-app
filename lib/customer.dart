import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common.dart';
import 'main.dart' show kBg, kCard;
import 'request_page.dart';

class CustomerHome extends StatefulWidget {
  final String name;
  const CustomerHome({super.key, this.name = ''});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> workers = [];
  List<String> professions = [];
  Map<String, List<String>> statesMap = {};
  Map<String, double> avg = {};
  Map<String, int> cnt = {};
  Map<String, String> profNames = {};
  Map<String, String> stateNames = {};

  String q = '';
  String prof = '';
  String? state;
  String? city;
  bool onlyAvail = false;

  String t(dynamic v) => v == null ? '' : v.toString();
  String wName(Map<String, dynamic> w) => t(w['full_name'] ?? w['name']);
  String wProf(Map<String, dynamic> w) {
    final n = t(w['profession'] ?? w['profession_name']);
    return n.isNotEmpty ? n : (profNames[t(w['profession_id'])] ?? '');
  }

  String wState(Map<String, dynamic> w) {
    final n = t(w['state']);
    return n.isNotEmpty ? n : (stateNames[t(w['state_id'])] ?? '');
  }

  String av(Map<String, dynamic> w) =>
      t(w['availability']).isEmpty ? 'available' : t(w['availability']);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final ws = await sb
          .from('workers')
          .select()
          .eq('verification_status', 'approved');
      workers = List<Map<String, dynamic>>.from(ws);
            try {
        final vis = await sb.rpc('visible_worker_ids');
        final ids = List<dynamic>.from(vis).map((e) => e.toString()).toSet();
        workers = workers.where((w) => ids.contains(t(w['id']))).toList();
      } catch (_) {}
    } catch (_) {
      error = 'تعذر تحميل الحرفيين، تأكد من الإنترنت';
    }
    try {
      final ps = await sb.from('professions').select().eq('active', true);
      final pl = List<Map<String, dynamic>>.from(ps);
      profNames = {for (final e in pl) t(e['id']): t(e['name'])};
      professions =
          pl.map((e) => t(e['name'])).where((e) => e.isNotEmpty).toList();
    } catch (_) {}
    try {
      final ss = await sb.from('states').select().eq('active', true);
      final m = <String, List<String>>{};
      for (final s in List<Map<String, dynamic>>.from(ss)) {
        final c = s['cities'];
        var list = <String>[];
        if (c is List) {
          list = c
              .map((e) => e is Map ? t(e['name']) : t(e))
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (c is String) {
          list = c
              .split(RegExp(r'[,،]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        m[t(s['name'])] = list;
        stateNames[t(s['id'])] = t(s['name']);
      }
      statesMap = m;
    } catch (_) {}
    try {
      final rs = await sb.from('ratings').select();
      final sum = <String, double>{};
      final n = <String, int>{};
      for (final r in List<Map<String, dynamic>>.from(rs)) {
        final id = t(r['worker_id']);
        sum[id] = (sum[id] ?? 0) + ((r['stars'] as num?) ?? 0).toDouble();
        n[id] = (n[id] ?? 0) + 1;
      }
      avg = {for (final k in sum.keys) k: sum[k]! / n[k]!};
      cnt = n;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> get shown {
    final list = workers.where((w) {
      if (onlyAvail && av(w) != 'available') return false;
      if (prof.isNotEmpty && wProf(w) != prof) return false;
      if (state != null && wState(w) != state) return false;
      if (city != null && t(w['city']) != city) return false;
      final s = q.trim();
      if (s.isNotEmpty && !('${wName(w)} ${wProf(w)}').contains(s)) {
        return false;
      }
      return true;
    }).toList();
    int rank(Map<String, dynamic> w) {
      final a = av(w);
      return a == 'available' ? 0 : (a == 'busy' ? 1 : 2);
    }

    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (avg[t(b['id'])] ?? 0).compareTo(avg[t(a['id'])] ?? 0);
    });
    return list;
  }

  String intl(String n) {
    var d = n.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) {
      d = d.substring(2);
    } else if (d.startsWith('0')) {
      d = '249${d.substring(1)}';
    }
    return d;
  }

  Future<void> open(String url) async {
    try {
      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) msg(context, 'تعذر فتح التطبيق');
    } catch (_) {
      if (mounted) msg(context, 'تعذر فتح التطبيق');
    }
  }

  void clearFilters() {
    setState(() {
      q = '';
      prof = '';
      state = null;
      city = null;
      onlyAvail = false;
    });
  }

  Widget dot(String a) {
    final c = a == 'available'
        ? Colors.greenAccent
        : (a == 'busy' ? Colors.orangeAccent : Colors.grey);
    final label = a == 'available'
        ? 'متاح الآن'
        : (a == 'busy' ? 'مشغول' : 'غير متاح');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, size: 10, color: c),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: c, fontSize: 12)),
    ]);
  }

  Widget card(Map<String, dynamic> w) {
    final id = t(w['id']);
    final photo = t(w['photo_url']);
    final place = [wState(w), t(w['city'])]
        .where((e) => e.isNotEmpty)
        .join('، ');
    FilledButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RequestPage(
        workerId: id,
        name: wName(w),
        job: wProf(w),
        place: place,
      ),
    ),
  ),
  icon: const Icon(Icons.send_outlined),
  label: const Text('اطلب الخدمة'),
),
    final bio = t(w['bio']);
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
          Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
              child: photo.isEmpty
                  ? const Icon(Icons.person, color: Colors.black45, size: 34)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wName(w),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  if (wProf(w).isNotEmpty)
                    Text(wProf(w),
                        style: const TextStyle(
                            color: Colors.tealAccent, fontSize: 14)),
                  if (place.isNotEmpty)
                    Text(place,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            dot(av(w)),
            const Spacer(),
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text((cnt[id] ?? 0) == 0
                ? 'جديد'
                : '${(avg[id] ?? 0).toStringAsFixed(1)} (${cnt[id]})'),
          ]),
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: phone.isEmpty ? null : () => open('tel:$phone'),
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: wa.isEmpty
                      ? null
                      : () => open('https://wa.me/${intl(wa)}'),
                  icon: const Icon(Icons.chat, color: Colors.greenAccent),
                  label: const Text('واتساب'),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = shown;
    final cities = state == null ? <String>[] : (statesMap[state] ?? []);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('عاملك علينا'),
        backgroundColor: kBg,
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () => sb.auth.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text('أقرب حرفي إليك',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => q = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو المهنة',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: const Text('الكل'),
                            selected: prof.isEmpty,
                            onSelected: (_) => setState(() => prof = ''),
                          ),
                        ),
                        for (final p in professions)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(p),
                              selected: prof == p,
                              onSelected: (_) => setState(() => prof = p),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'الولاية', isDense: true),
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, child: Text('كل الولايات')),
                          for (final s in statesMap.keys)
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => setState(() {
                          state = v;
                          city = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: city,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'المدينة', isDense: true),
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, child: Text('كل المدن')),
                          for (final c in cities)
                            DropdownMenuItem<String>(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => setState(() => city = v),
                      ),
                    ),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('المتاحون الآن فقط'),
                    value: onlyAvail,
                    onChanged: (v) => setState(() => onlyAvail = v),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  if (error == null && list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(children: [
                        const Text('لا يوجد حرفيون بهذه المواصفات',
                            style: TextStyle(color: Colors.white60)),
                        const SizedBox(height: 10),
                        OutlinedButton(
                            onPressed: clearFilters,
                            child: const Text('إزالة الفلاتر')),
                      ]),
                    ),
                  for (final w in list) card(w),
                ],
              ),
            ),
    );
  }
}
