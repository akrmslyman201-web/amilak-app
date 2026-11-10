import 'package:flutter/material.dart';

import 'common.dart';

class SubBanner extends StatefulWidget {
  final VoidCallback onRenew;
  const SubBanner({super.key, required this.onRenew});

  @override
  State<SubBanner> createState() => _SubBannerState();
}

class _SubBannerState extends State<SubBanner> {
  bool approved = false;
  bool loaded = false;
  DateTime? until;

  @override
  void initState() {
    super.initState();
    profileRefresh.addListener(load);
    load();
  }

  @override
  void dispose() {
    profileRefresh.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    try {
      final uid = sb.auth.currentUser!.id;
      final w = await sb
          .from('workers')
          .select('verification_status')
          .eq('id', uid)
          .maybeSingle();
      approved = w != null && w['verification_status'] == 'approved';
      DateTime? best;
      if (approved) {
        final subs = await sb
            .from('subscriptions')
            .select('ends_at')
            .eq('worker_id', uid)
            .eq('status', 'confirmed');
        for (final s in subs) {
          final e = s['ends_at'];
          if (e == null) continue;
          final d = DateTime.tryParse(e.toString());
          if (d != null && (best == null || d.isAfter(best))) best = d;
        }
      }
      until = best;
    } catch (_) {
      approved = false;
    }
    if (mounted) setState(() => loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || !approved) return const SizedBox.shrink();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var left = -1;
    if (until != null) {
      left = DateTime(until!.year, until!.month, until!.day)
          .difference(today)
          .inDays;
    }
    if (left > 7) return const SizedBox.shrink();
    final expired = left < 0;
    final color = expired ? const Color(0xFFB3261E) : const Color(0xFFE08A00);
    final text = expired
        ? 'انتهى اشتراكك وحسابك مخفي عن العملاء. جدّد الآن'
        : left == 0
            ? 'ينتهي اشتراكك اليوم'
            : 'ينتهي اشتراكك بعد $left يوم';
    return Material(
      color: color,
      child: InkWell(
        onTap: widget.onRenew,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Text('جدّد',
                  style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline)),
            ],
          ),
        ),
      ),
    );
  }
}
