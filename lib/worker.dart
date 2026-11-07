import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'common.dart';
import 'main.dart' show kBg, kCard;

class WorkerHome extends StatefulWidget {
  final String name;
  const WorkerHome({super.key, required this.name});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {
  Map<String, dynamic>? w;
  bool loading = true;
  bool busy = false;
  String? docType;
  XFile? docFile;

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
    if (mounted) setState(() => loading = true);
    try {
      w = await sb
          .from('workers')
          .select()
          .eq('id', sb.auth.currentUser!.id)
          .single();
    } catch (_) {
      w = null;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> sendDoc() async {
    if (docType == null || docFile == null) {
      msg(context, 'اختر نوع المستند وصوّره');
      return;
    }
    setState(() => busy = true);
    try {
      final uid = sb.auth.currentUser!.id;
      final path = await upload('id-docs', uid,
          'doc_${DateTime.now().millisecondsSinceEpoch}', docFile!);
      await sb
          .from('workers')
          .update({'id_doc_url': path, 'id_doc_type': docType}).eq('id', uid);
      docType = null;
      docFile = null;
      await load();
    } catch (_) {
      if (mounted) msg(context, 'تعذر الإرسال، حاول مرة أخرى');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final st = (w?['verification_status'] ?? 'pending').toString();
    final hasDoc = w?['id_doc_url'] != null;
    final needDoc = !hasDoc || st == 'rejected';
    final reason = w?['reject_reason'] as String?;
    final photo = w?['photo_url'] as String?;
    String title;
    Color col;
    if (!hasDoc) {
      title = 'لم يكتمل التوثيق: ارفع صورة مستندك';
      col = const Color(0xFFE08A00);
    } else if (st == 'approved') {
      title = 'حسابك موثّق ✓';
      col = const Color(0xFF12A36B);
    } else if (st == 'rejected') {
      title = 'تم رفض التوثيق. ارفع مستنداً جديداً';
      col = Colors.redAccent;
    } else {
      title = 'مستندك قيد المراجعة من الإدارة';
      col = const Color(0xFFE08A00);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: kBg,
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () => sb.auth.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              backgroundImage: photo == null ? null : NetworkImage(photo),
              child: photo == null
                  ? const Icon(Icons.person, size: 48, color: Colors.black26)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
              child: Text(widget.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: col),
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: col, fontWeight: FontWeight.bold, fontSize: 16)),
                if (st == 'rejected' && reason != null && reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('السبب: $reason'),
                  ),
                if (needDoc) ...[
                  const SizedBox(height: 12),
                  DocPicker(
                    type: docType,
                    file: docFile,
                    onType: (v) => setState(() => docType = v),
                    onFile: (f) => setState(() => docFile = f),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy ? null : sendDoc,
                    child: Text(busy ? 'جاري الإرسال...' : 'إرسال للمراجعة'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'يظهر حسابك للعملاء بعد توثيقه وتأكيد اشتراكك. أول شهرين مجاناً.',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
