import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'main.dart' show kBg, kGreen;

const supabaseUrl = 'https://dcxxvljvffmxlnjvcvjb.supabase.co';
const supabaseKey = 'sb_publishable_igIjHNZb6dbOXsuv0LU4Gw_MAAchmyk';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const AmilakApp());
}

class AmilakApp extends StatelessWidget {
  const AmilakApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'عاملك علينا',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kGreen),
        ),
        builder: (c, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const AuthGate(),
      );
}
