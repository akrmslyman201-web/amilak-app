import 'package:flutter/material.dart';

import 'common.dart';
import 'main.dart' show kBg, kCard;
import 'request_page.dart';

class CustomerHome extends StatefulWidget {
  final String name;
  const CustomerHome({super.key, required this.name});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> workers = [];
  Map<String, String> profNames = {};
  Map<String, String> stateNames = {};
  Map<String, List<String>> statesMap = {};
  Map<String, double> avg = {};
  Map<String, int> cnt = {};

  String q = '';
  String prof = '';
  String? state;
  String? city;
  bool onlyAvail = false;

  String t(dynamic v) => v == null ? '' : v.toString();

  String wName(Map<String, dynamic> w) => t(w['full_name']).isNotEmpty
      ? t(w['full_name'])
      : 'حرفي';

  String wProf(Map<String, dynamic> w) {
    final n = t(w['profession']);
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
    } catch (_) {
      error = 'تعذر تحميل الحرفيين، تأكد من الإنترنت';
    }
    try {
      final ps = await sb.from('professions').select('id, name').eq('active', true);
      profNames = {for (final p in ps) t(p['id']): t(p['name'])};
    } catch (_) {}
    try {
      final ss = await sb.from('states').select('id, name, cities').eq('active', true);
      stateNames = {for (final s in ss) t(s['id']): t(s['name'])};
      statesMap = {
        for (final s in ss)
          t(s['name']): (s['cities'] as List? ?? []).map((e) => e.toString()).toList()
      };
    } catch (_) {}
    try {
      final rs = await sb.from('ratings').select('worker_id, stars');
      final sum = <String, double>{};
      final n = <String, int>{};
      for (final r in rs) {
        final id = t(r['worker_id']);
        sum[id] = (sum[id] ?? 0) + ((r['stars'] as num?)?.toDouble() ?? 0);
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
      if (s.isNotEmpty && !wName(w).contains(s) && !wProf(w).contains(s)) {
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 12)),
      ],
    );
  }

  Widget card(Map<String, dynamic> w) {
    final id = t(w['id']);
    final photo = t(w['photo_url']);
    final place = [wState(w), t(w['city'])].where((e) => e.isNotEmpty).join('، ');
    final bio = t(w['bio']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                child: photo.isEmpty
                    ? const Icon(Icons.person, color: Colors.black26)
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
                          style: const TextStyle(color: Color(0xFF6FCBB4))),
                    if (place.isNotEmpty)
                      Text(place, style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              dot(av(w)),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text((cnt[id] ?? 0) == 0
                  ? 'جديد'
                  : '${(avg[id] ?? 0).toStringAsFixed(1)}'),
            ],
          ),
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أقرب حرفي إليك، ${widget.name}'),
        backgroundColor: kBg,
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو المهنة',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('المتاحون الآن'),
                  selected: onlyAvail,
                  onSelected: (v) => setState(() => onlyAvail = v),
                ),
                ActionChip(label: const Text('مسح الفلاتر'), onPressed: clearFilters),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ))
            else if (error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
              )
            else ...[
              Text('${shown.length} حرفي',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('لا يوجد حرفيون بهذه الفلاتر')),
                ),
              for (final w in shown) card(w),
            ],
          ],
        ),
      ),
    );
  }
}
