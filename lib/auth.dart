import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart' show Home, kBg, kBorder, kCard, kGreen;

SupabaseClient get sb => Supabase.instance.client;

final profileRefresh = ValueNotifier<int>(0);

const docTypes = {
  'passport': 'جواز سفر',
  'national_id': 'الرقم الوطني',
  'id_card': 'بطاقة شخصية',
};

void msg(BuildContext c, String t) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

InputDecoration dec(String l) => InputDecoration(
      labelText: l,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );

Widget tf(TextEditingController c, String label,
    {IconData? icon,
    bool obscure = false,
    bool ltr = false,
    TextInputType? type,
    String? hint}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      textDirection: ltr ? TextDirection.ltr : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

Future<XFile?> pickPhoto(BuildContext context) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: kCard,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('التقاط صورة'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('اختيار من المعرض'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (src == null) return null;
  return ImagePicker().pickImage(source: src, imageQuality: 80, maxWidth: 1600);
}

Future<String> upload(String bucket, String uid, String base, XFile f) async {
  final isPng = f.path.toLowerCase().endsWith('.png');
  final path = '$uid/$base.${isPng ? 'png' : 'jpg'}';
  await sb.storage.from(bucket).upload(
        path,
        File(f.path),
        fileOptions:
            FileOptions(contentType: isPng ? 'image/png' : 'image/jpeg'),
      );
  return path;
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: sb.auth.onAuthStateChange,
      builder: (context, snap) {
        if (sb.auth.currentSession == null) return const LoginPage();
        return const RoleRouter();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool busy = false;

  Future<void> login() async {
    final email = emailC.text.trim();
    if (email.isEmpty || passC.text.isEmpty) {
      msg(context, 'اكتب البريد وكلمة المرور');
      return;
    }
    setState(() => busy = true);
    try {
      await sb.auth.signInWithPassword(email: email, password: passC.text);
    } on AuthException catch (e) {
      if (mounted) {
        msg(
            context,
            e.message.toLowerCase().contains('invalid')
                ? 'البريد أو كلمة المرور غير صحيحة'
                : 'تعذر الدخول: ${e.message}');
      }
    } catch (_) {
      if (mounted) msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: kGreen, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.build, color: kBg, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
                child: Text('عاملك علينا',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            const Center(
                child: Text('أقرب حرفي إليك',
                    style: TextStyle(color: Colors.white60))),
            const SizedBox(height: 28),
            tf(emailC, 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                ltr: true,
                type: TextInputType.emailAddress),
            tf(passC, 'كلمة المرور',
                icon: Icons.lock_outline, obscure: true, ltr: true),
            FilledButton(
              onPressed: busy ? null : login,
              style: FilledButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: kBg,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(busy ? 'جاري الدخول...' : 'تسجيل الدخول'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupPage())),
              child: const Text('حرفي جديد؟ أنشئ حسابك'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Home())),
              child: const Text('تصفح كزائر'),
            ),
          ],
        ),
      ),
    );
  }
}

class DocPicker extends StatelessWidget {
  final String? type;
  final XFile? file;
  final ValueChanged<String> onType;
  final ValueChanged<XFile> onFile;

  const DocPicker({
    super.key,
    required this.type,
    required this.file,
    required this.onType,
    required this.onFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر مستنداً واحداً للتوثيق:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final e in docTypes.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: type == e.key,
                showCheckmark: false,
                selectedColor: kGreen,
                labelStyle: TextStyle(
                    color: type == e.key ? kBg : Colors.white,
                    fontWeight: FontWeight.bold),
                onSelected: (_) => onType(e.key),
              ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final f = await pickPhoto(context);
            if (f != null) onFile(f);
          },
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(file == null
              ? 'تصوير / اختيار صورة المستند'
              : 'تغيير الصورة'),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(file!.path),
                  height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 6),
        const Text('صورة المستند خاصة، لا يراها غير الإدارة.',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

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
    String uid;
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
          setState(() => busy = false);
        }
        return;
      }
      uid = res.user!.id;
    } on AuthException catch (e) {
      if (mounted) {
        msg(
            context,
            e.message.toLowerCase().contains('already')
                ? 'هذا البريد مسجل من قبل'
                : 'تعذر إنشاء الحساب: ${e.message}');
        setState(() => busy = false);
      }
      return;
    } catch (_) {
      if (mounted) {
        msg(context, 'تعذر الاتصال، تحقق من الإنترنت');
        setState(() => busy = false);
      }
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
          DropdownButtonFormField<String>(
            value: profId,
            decoration: dec('المهنة'),
            items: [
              for (final p in profs)
                DropdownMenuItem(
                    value: p['id'] as String, child: Text(p['name'] as String)),
            ],
            onChanged: (v) => setState(() => profId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: stateId,
            decoration: dec('الولاية'),
            items: [
              for (final s in states)
                DropdownMenuItem(
                    value: s['id'] as String, child: Text(s['name'] as String)),
            ],
            onChanged: (v) => setState(() {
              stateId = v;
              city = null;
            }),
          ),
          const SizedBox(height: 12),
          if (cities.isNotEmpty)
            DropdownButtonFormField<String>(
              value: city,
              decoration: dec('المدينة'),
              items: [
                for (final c in cities) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => city = v),
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

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<Map<String, dynamic>> f;

  @override
  void initState() {
    super.initState();
    f = load();
  }

  Future<Map<String, dynamic>> load() async {
    final r = await sb
        .from('profiles')
        .select('role, full_name')
        .eq('id', sb.auth.currentUser!.id)
        .single();
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (s.hasError || s.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعذر تحميل الحساب'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      f = load();
                    }),
                    child: const Text('إعادة المحاولة'),
                  ),
                  TextButton(
                    onPressed: () => sb.auth.signOut(),
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          );
        }
        final role = s.data!['role'];
        final name = (s.data!['full_name'] ?? '').toString();
        if (role == 'worker') return WorkerHome(name: name);
        if (role == 'admin') return const AdminHome();
        return const Home();
      },
    );
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        backgroundColor: kBg,
        actions: [
          IconButton(
              onPressed: () => sb.auth.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: const Center(child: Text('شاشات الإدارة قادمة في الخطوة التالية')),
    );
  }
}

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
  
