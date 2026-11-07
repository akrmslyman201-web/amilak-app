import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'common.dart';
import 'main.dart' show kBg, kBorder, kCard, kGreen;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final waC = TextEditingController();
  bool sameWa = true;
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

  Future<String?> createAccount(
      String name, String email, String phone, String wa) async {
    try {
      final res = await sb.auth.signUp(
        email: email,
        password: passC.text,
        data: {
          'role': 'worker',
          'full_name': name,
          'phone': phone,
          'whatsapp': wa,
          'profession_id': profId,
          'state_id': stateId,
          'city': city ?? '',
        },
      );
      if (res.user == null || res.session == null) {
        if (mounted) {
          msg(context, 'تم إنشاء الحساب. تحقق من بريدك ثم سجّل الدخول');
        }
        return null;
      }
      return res.user!.id;
    } on AuthException catch (e) {
      if (mounted) {
        msg(
            context,
            e.message.toLowerCase().contains('already')
                ? 'هذا البريد مسجل من قبل'
                : 'تعذر إنشاء الحساب: ${e.message}');
      }
      return null;
    } catch (_) {
      if (mounted) msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
      return null;
    }
  }

  Future<void> submit() async {
    final name = nameC.text.trim();
    final email = emailC.text.trim();
    final phone = phoneC.text.replaceAll(' ', '');
    final wa = (sameWa ? phoneC.text : waC.text).replaceAll(' ', '');
    final phoneRe = RegExp(r'^\+?\d{9,15}$');
    String? err;
    if (!email.contains('@') || !email.contains('.')) {
      err = 'اكتب بريداً إلكترونياً صحيحاً';
    } else if (passC.text.length < 6) {
      err = 'كلمة المرور لا تقل عن 6 أحرف';
    } else if (name.split(RegExp(r'\s+')).length < 3) {
      err = 'اكتب اسمك الثلاثي كاملاً';
    } else if (!phoneRe.hasMatch(phone)) {
      err = 'رقم الهاتف غير صحيح';
    } else if (!phoneRe.hasMatch(wa)) {
      err = 'رقم الواتساب غير صحيح';
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
    final uid = await createAccount(name, email, phone, wa);
    if (uid == null) {
      if (mounted) setState(() => busy = false);
      return;
    }

    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final avatarPath = await upload('avatars', uid, 'avatar_$stamp', avatar!);
      final url = sb.storage.from('avatars').getPublicUrl(avatarPath);
      final docPath = await upload('id-docs', uid, 'doc_$stamp', docFile!);
      await sb.from('workers').update({
        'photo_url': url,
        'id_doc_url': docPath,
        'id_doc_type': docType,
      }).eq('id', uid);
    } catch (_) {
      if (mounted) {
        msg(context, 'تم إنشاء الحساب لكن تعذر رفع الصور. أكملها من شاشة حسابك');
      }
    }
    profileRefresh.value++;
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب حرفي جديد'), backgroundColor: kBg),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          tf(emailC, 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              ltr: true,
              type: TextInputType.emailAddress),
          tf(passC, 'كلمة المرور (6 أحرف على الأقل)',
              icon: Icons.lock_outline, obscure: true, ltr: true),
          tf(nameC, 'الاسم الثلاثي', icon: Icons.person_outline),
          tf(phoneC, 'رقم الهاتف',
              icon: Icons.phone_outlined,
              ltr: true,
              type: TextInputType.phone,
              hint: 'مع كود الدولة، مثال: 249912345678'),
          CheckboxListTile(
            value: sameWa,
            onChanged: (v) => setState(() => sameWa = v ?? true),
            title: const Text('رقم الواتساب هو نفس رقم الهاتف'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (!sameWa)
            tf(waC, 'رقم الواتساب',
                icon: Icons.chat_outlined,
                ltr: true,
                type: TextInputType.phone,
                hint: 'مع كود الدولة'),
          const SizedBox(height: 4),
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
            child: Text(busy ? 'جاري الإنشاء...' : 'إنشاء الحساب'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
