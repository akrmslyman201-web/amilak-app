import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'common.dart';
import 'main.dart' show kBg, kCard;

const kBankAccount = '2591569';
const kMonthlyFee = 10000;

class PayButton extends StatelessWidget {
  const PayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PayPage())),
          icon: const Icon(Icons.payments),
          label: const Text('تجديد الاشتراك'),
        ),
      ),
    );
  }
}

class PayPage extends StatefulWidget {
  const PayPage({super.key});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  XFile? file;
  bool busy = false;
  bool loading = true;
  Map<String, dynamic>? last;

  String t(dynamic v) => v == null ? '' : v.toString();

  @override
  void initState() {
    super.initState();
    loadLast();
  }

  Future<void> loadLast() async {
    try {
      final r = await sb
          .from('subscriptions')
          .select()
          .eq('worker_id', sb.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1);
      last = r.isNotEmpty ? Map<String, dynamic>.from(r.first) : null;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> pick() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (f != null) setState(() => file = f);
  }

  Future<void> submit() async {
    if (file == null) {
      msg(context, 'اختر صورة إشعار الدفع');
      return;
    }
    final uid = sb.auth.currentUser!.id;
    setState(() => busy = true);
    try {
      final bytes = await file!.readAsBytes();
      final name = file!.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      final path = '$uid/pay_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await sb.storage.from('receipts').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
                contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
          );
      await sb.from('subscriptions').insert({
        'worker_id': uid,
        'amount': kMonthlyFee,
        'status': 'pending',
        'receipt_url': path,
      });
      if (!mounted) return;
      msg(context, 'تم إرسال الإشعار للمراجعة');
      Navigator.of(context).pop();
      return;
    } catch (e) {
      final s = e.toString();
      if (mounted) {
        msg(context, 'تعذر الإرسال: ${s.length > 120 ? s.substring(0, 120) : s}');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  Widget statusBox() {
    if (last == null) return const SizedBox.shrink();
    final st = t(last!['status']);
    String text;
    Color c;
    if (st == 'pending') {
      text = 'إشعارك الأخير قيد المراجعة من الإدارة';
      c = Colors.orangeAccent;
    } else if (st == 'rejected') {
      final r = t(last!['reject_reason']);
      text = 'تم رفض الإشعار الأخير${r.isEmpty ? '' : ': $r'}. ارفع إشعارًا جديدًا';
      c = Colors.redAccent;
    } else {
      text = 'اشتراكك ساري حتى ${t(last!['ends_at'])}';
      c = Colors.greenAccent;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c),
      ),
      child: Text(text, style: TextStyle(color: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = t(last?['status']) == 'pending';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('اشتراكي'), backgroundColor: kBg),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                statusBox(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('طريقة الدفع',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text(
                          '1. افتح تطبيق بنكك\n2. حوّل 10,000 جنيه إلى الحساب:\n3. صوّر إشعار التحويل وارفعه هنا'),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Text(kBankAccount,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent)),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: kBankAccount));
                            msg(context, 'تم نسخ رقم الحساب');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ'),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: pending ? null : pick,
                    icon: const Icon(Icons.image),
                    label: Text(file == null
                        ? 'اختر صورة إشعار الدفع'
                        : 'تم اختيار: ${file!.name}'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: (busy || pending) ? null : submit,
                    child: Text(busy ? 'جارٍ الإرسال...' : 'إرسال للمراجعة'),
                  ),
                ),
              ],
            ),
    );
  }
}
