import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;

class RequestPage extends StatefulWidget {
  final String workerId;
  final String name;
  final String job;
  final String place;
  const RequestPage({
    super.key,
    required this.workerId,
    required this.name,
    required this.job,
    required this.place,
  });

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final noteC = TextEditingController();
  bool loading = true;
  bool busy = false;
  String? lastStatus;
  String? phone;
  String? whatsapp;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final uid = sb.auth.currentUser!.id;
      final r = await sb
          .from('requests')
          .select('status')
          .eq('customer_id', uid)
          .eq('worker_id', widget.workerId)
          .order('created_at', ascending: false)
          .limit(1);
      final list = r as List;
      lastStatus = list.isEmpty ? null : list.first['status'] as String?;
      phone = null;
      whatsapp = null;
      if (lastStatus == 'accepted') {
        final c = await sb.rpc('contact_of', params: {'w': widget.workerId});
        final cl = c as List;
        if (cl.isNotEmpty) {
          phone = cl.first['phone']?.toString();
          whatsapp = cl.first['whatsapp']?.toString();
        }
      }
    } catch (e) {
      if (mounted) msg(context, 'تعذر التحميل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> send() async {
    setState(() => busy = true);
    try {
      await sb.from('requests').insert({
        'customer_id': sb.auth.currentUser!.id,
        'worker_id': widget.workerId,
        'note': noteC.text.trim(),
        'status': 'pending',
      });
      if (mounted) msg(context, 'تم إرسال طلبك، ننتظر رد الحرفي');
      noteC.clear();
      await load();
    } catch (_) {
      if (mounted) {
        msg(context,
            'تعذر إرسال الطلب. ربما عندك 3 طلبات معلّقة، أو عندك طلب معلّق لهذا الحرفي');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> callOrWa(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) msg(context, 'تعذر فتح التطبيق');
    }
  }

  String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final pending = lastStatus == 'pending';
    final accepted = lastStatus == 'accepted';
    return Scaffold(
      appBar: AppBar(title: Text(widget.name), backgroundColor: kBg),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(widget.job,
                    style: const TextStyle(
                        color: kGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(widget.place,
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kCard,
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(20)),
                  child: accepted
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تم قبول طلبك. تواصل مع الحرفي:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (phone != null && phone!.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => callOrWa(
                                    'tel:+${digitsOnly(phone!)}'),
                                icon: const Icon(Icons.phone_outlined),
                                label: Text('اتصال ${phone!}'),
                              ),
                            const SizedBox(height: 8),
                            if (whatsapp != null && whatsapp!.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => callOrWa(
                                    'https://wa.me/${digitsOnly(whatsapp!)}'),
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('واتساب'),
                              ),
                          ],
                        )
                      : pending
                          ? const Text(
                              'طلبك بانتظار رد الحرفي. ستظهر أرقامه هنا بعد القبول.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('اكتب وصفاً مختصراً لما تحتاجه:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                tf(noteC, 'مثال: تسريب في الحمام، الأحد صباحاً'),
                                FilledButton(
                                  onPressed: busy ? null : send,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kGreen,
                                    foregroundColor: kBg,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: Text(busy
                                      ? 'جاري الإرسال...'
                                      : 'اطلب الخدمة'),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'أرقام الحرفي لا تظهر إلا بعد أن يقبل طلبك.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
    );
  }
}
