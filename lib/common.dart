import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart' show kBg, kCard, kGreen;

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

Widget pick(String label, String? value, List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged) {
  return InputDecorator(
    decoration: dec(label),
    isEmpty: value == null,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        isDense: true,
        value: value,
        dropdownColor: kCard,
        items: items,
        onChanged: onChanged,
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
          label: Text(
              file == null ? 'تصوير / اختيار صورة المستند' : 'تغيير الصورة'),
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
