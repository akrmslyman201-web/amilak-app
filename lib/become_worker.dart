import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'common.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;

class BecomeWorkerPage extends StatefulWidget {
  final VoidCallback onDone;
  const BecomeWorkerPage({super.key, required this.onDone});

  @override
  State<BecomeWorkerPage> createState() => _BecomeWorkerPageState();
}

class _BecomeWorkerPageState extends State<BecomeWorkerPage> {
  final waC = TextEditingController();
  bool busy = false;

  List<Map<String, dynamic>> profs = [];
  List<Map<String, dynamic>> states = [];
  String? profId;
  String? stateId;
  String? city;
  XFile? avatar;
  String? docType;
  XFile? docFile;

  @override
  void initState() {
    super.initState();
    loadLists();
  }

  Future<void> loadLists() async {
    try {
      final p = await sb
          .from('professions')
          .select('id, name')
          .eq('active', true)
          .order('name');
      final s = await sb
          .from('states')
          .select('id, name, cities')
          .eq('active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        profs = List<Map<String, dynamic>>.from(p);
        states = List<Map<String, dynamic>>.from(s);
      });
    } catch (_) {
      if (mounted) msg(context, 'تعذر تحميل القوائم، تحقق من الإنترنت');
    }
  }

  List<String> get cities {
    for (final s in states) {
      if (s['id'] == stateId) {
        return (s['cities'] as List).map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<void> submit() async {
    final wa = waC.text.replaceAll(' ', '');
    String? err;
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(wa)) {
      err = 'رقم الواتساب غير صحيح (بالأرقام الإنجليزية ومع كود الدولة)';
    } else if (profId == null) {
      err = 'اختر مهنتك';
    } else if (stateId == null || (cities.isNotEmpty && city == null)) {
      err = 'اختر الولاية والمدينة';
    } else if (avatar == null) {
      err = 'أضف صورتك الشخصية';
    } else if (docType == null || docFile == null) {
      err = 'اختر مستند التوثيق وصوّره';
    }
    if (err != null) {
      msg(context, err);
      return;
    }

    setState(() => busy = true);
    try {
      await sb.rpc('become_worker', params: {
        'p_profession': profId,
        'p_state': stateId,
        'p_city': city ?? '',
        'p_whatsapp': wa,
      });
    } catch (e) {
      if (mounted) {
        msg(context, 'تعذر التحويل: $e');
        setState(() => busy = false);
      }
      return;
    }

    try {
      final uid = sb.auth.currentUser!.id;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ap = await upload('avatars', uid, 'avatar_$stamp', avatar!);
      final url = sb.storage.from('avatars').getPublicUrl(ap);
      final dp = await upload('id-docs', uid, 'doc_$stamp', docFile!);
      await sb.from('workers').update({
        'photo_url': url,
        'id_doc_url': dp,
        'id_doc_type': docType,
      }).eq('id', uid);
    } catch (_) {
      if (mounted) {
        msg(context, 'تم التحويل لكن تعذر رفع الصور. أكملها من شاشة حسابك');
      }
    }
    profileRefresh.value++;
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كن حرفياً'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'أضف بيانات حرفتك وتوثيقك بنفس حسابك. بعد قبول الإدارة يظهر حسابك للعملاء، وأول شهرين مجاناً.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () async {
                final f = await pickPhoto(context);
                if (f != null) setState(() => avatar = f);
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: kCard,
                backgroundImage:
                    avatar == null ? null : FileImage(File(avatar!.path)),
                child: avatar == null
                    ? const Icon(Icons.add_a_photo_outlined, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
              child: Text('صورتك الشخصية (تظهر للعملاء)',
                  style: TextStyle(color: Colors.white60))),
          const SizedBox(height: 18),
          tf(waC, 'رقم الواتساب',
              icon: Icons.chat_outlined,
              ltr: true,
              type: TextInputType.phone,
              hint: 'مع كود الدولة، مثال: 249912345678'),
          pick(
            'المهنة',
            profId,
            [
              for (final p in profs)
                DropdownMenuItem<String>(
                    value: p['id'] as String, child: Text(p['name'] as String)),
            ],
            (v) => setState(() => profId = v),
          ),
          const SizedBox(height: 12),
          pick(
            'الولاية',
            stateId,
            [
              for (final s in states)
                DropdownMenuItem<String>(
                    value: s['id'] as String, child: Text(s['name'] as String)),
            ],
            (v) => setState(() {
              stateId = v;
              city = null;
            }),
          ),
          const SizedBox(height: 12),
          if (cities.isNotEmpty)
            pick(
              'المدينة',
              city,
              [
                for (final c in cities)
                  DropdownMenuItem<String>(value: c, child: Text(c)),
              ],
              (v) => setState(() => city = v),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(20)),
            child: DocPicker(
              type: docType,
              file: docFile,
              onType: (v) => setState(() => docType = v),
              onFile: (f) => setState(() => docFile = f),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : submit,
            style: FilledButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: kBg,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(busy ? 'جاري الإرسال...' : 'إرسال الطلب'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
