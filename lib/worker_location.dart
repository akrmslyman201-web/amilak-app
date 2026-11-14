import 'package:flutter/material.dart';

import 'common.dart';
import 'geo.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;

class WorkerLocationTab extends StatefulWidget {
  const WorkerLocationTab({super.key});

  @override
  State<WorkerLocationTab> createState() => _WorkerLocationTabState();
}

class _WorkerLocationTabState extends State<WorkerLocationTab> {
  bool loading = true;
  bool busy = false;
  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final w = await sb
          .from('workers')
          .select('lat, lng')
          .eq('id', sb.auth.currentUser!.id)
          .maybeSingle();
      lat = (w?['lat'] as num?)?.toDouble();
      lng = (w?['lng'] as num?)?.toDouble();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    setState(() => busy = true);
    final p = await getPosition(context);
    if (p != null) {
      final la = (p.latitude * 100).round() / 100;
      final ln = (p.longitude * 100).round() / 100;
      try {
        await sb
            .from('workers')
            .update({'lat': la, 'lng': ln}).eq('id', sb.auth.currentUser!.id);
        lat = la;
        lng = ln;
        if (mounted) msg(context, 'تم حفظ موقع عملك');
      } catch (_) {
        if (mounted) msg(context, 'تعذر الحفظ، حاول مرة أخرى');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final has = lat != null && lng != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Icon(has ? Icons.location_on : Icons.location_off_outlined,
            size: 64, color: has ? kGreen : Colors.white54),
        const SizedBox(height: 12),
        Center(
          child: Text(has ? 'تم تحديد موقع عملك' : 'لم تحدد موقع عملك بعد',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kCard,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(20)),
          child: const Text(
            'قف في مكان عملك ثم اضغط الزر. يُحفظ موقعك بدقة تقريبية (حوالي كيلومتر) حتى لا يظهر مكان بيتك بالضبط، ويساعد العملاء القريبين منك على إيجادك.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : save,
          icon: const Icon(Icons.my_location),
          label: Text(busy
              ? 'جاري التحديد...'
              : (has ? 'تحديث موقعي' : 'حدد موقعي الآن')),
          style: FilledButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: kBg,
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ],
    );
  }
}
