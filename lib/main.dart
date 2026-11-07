import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const App());

const kGreen = Color(0xFF6FCBB4);
const kBg = Color(0xFF0B1514);
const kCard = Color(0xFF111C1B);
const kBorder = Color(0xFF223130);

class Craftsman {
  final String name, job, state, city, phone;
  final bool available;
  final int reviews;
  const Craftsman(this.name, this.job, this.state, this.city, this.phone,
      this.available,
      [this.reviews = 0]);
}

const data = [
  Craftsman('معز نعيم الله جعفر', 'سباك', 'الشمالية', 'مروي', '249900000001', true),
  Craftsman('اكرم سليمان ادريس', 'كهربجي منازل', 'الخرطوم', 'امدرمان', '249900000002', false),
];

class App extends StatelessWidget {
  const App({super.key});

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
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 1;
  String q = '';
  String job = 'كل المهن';
  String? state;
  String? city;

  static const jobs = [
    'كل المهن', 'سباك', 'كهربجي منازل', 'حداد', 'نجار', 'نقاش', 'معلم بناء'
  ];
  static const labels = ['القيادة', 'العمال', 'الاشتراكات', 'المهن', 'الولايات'];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.engineering,
    Icons.account_balance_wallet_outlined,
    Icons.build_outlined,
    Icons.location_on_outlined,
  ];

  List<String> get states => data.map((c) => c.state).toSet().toList();
  List<String> get cities =>
      data.where((c) => c.state == state).map((c) => c.city).toSet().toList();

  List<Craftsman> get list => data.where((c) {
        if (job != 'كل المهن' && c.job != job) return false;
        if (state != null && c.state != state) return false;
        if (city != null && c.city != city) return false;
        if (q.isNotEmpty && !(c.name.contains(q) || c.job.contains(q))) {
          return false;
        }
        return true;
      }).toList();

  Future<void> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: tab == 1
            ? finder()
            : Center(child: Text(labels[tab], style: const TextStyle(fontSize: 20))),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: kBg,
        indicatorColor: const Color(0x336FCBB4),
        destinations: [
          for (var i = 0; i < 5; i++)
            NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
        ],
      ),
    );
  }

  Widget finder() {
    final items = list;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: kGreen, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.build, color: kBg),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('عاملك علينا',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('أقرب حرفي إليك',
                style: TextStyle(fontSize: 12, color: Colors.white60)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(28)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ابحث عن حرفي قريب منك',
                style: TextStyle(
                    color: kBg, fontSize: 26, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
                'سباك، كهربائي، حداد، نجار، بناء، توصيل ركشة ومواتر — في ولايتك ومدينتك.',
                style: TextStyle(color: Color(0xFF1F3F3A), fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            hintText: 'ابحث باسم الحرفي أو المهنة',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kBorder)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final j in jobs)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(j),
                    selected: job == j,
                    showCheckmark: false,
                    selectedColor: kGreen,
                    shape: const StadiumBorder(side: BorderSide(color: kBorder)),
                    labelStyle: TextStyle(
                        color: job == j ? kBg : Colors.white,
                        fontWeight: FontWeight.bold),
                    onSelected: (_) => setState(() => job = j),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: dd('كل الولايات', state, states,
                  (v) => setState(() {
                        state = v;
                        city = null;
                      }))),
          const SizedBox(width: 12),
          Expanded(
              child: dd('كل المدن', city, state == null ? [] : cities,
                  (v) => setState(() => city = v))),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم تفعيل الترتيب بالأقرب بعد ربط الموقع'))),
          icon: const Icon(Icons.near_me_outlined),
          label: const Text('رتّب حسب الأقرب إليّ'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kGreen,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: kBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
        ),
        const SizedBox(height: 16),
        Text('${items.length} حرفي',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('لا توجد نتائج')),
          ),
        for (final c in items) card(c),
      ],
    );
  }

  Widget dd(String hint, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(22)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          dropdownColor: kCard,
          items: [
            DropdownMenuItem<String>(value: null, child: Text(hint)),
            for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
          ],
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget card(Craftsman c) {
    final col = c.available ? const Color(0xFF12A36B) : const Color(0xFFE08A00);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.person, color: Colors.black26, size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(c.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold))),
                const SizedBox(width: 6),
                const Icon(Icons.verified_outlined, color: kGreen, size: 20),
              ]),
              const SizedBox(height: 2),
              Text(c.job,
                  style: const TextStyle(
                      color: kGreen, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text('${c.city}، ${c.state}',
                    style: const TextStyle(color: Colors.white54)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: col),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 9, color: col),
                      const SizedBox(width: 6),
                      Text(c.available ? 'متاح الآن' : 'مشغول حالياً',
                          style: TextStyle(
                              color: col, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 5; i++)
                      const Icon(Icons.star_border,
                          size: 18, color: Colors.white38),
                    Text(' (${c.reviews})',
                        style: const TextStyle(color: Colors.white60)),
                  ]),
                ],
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => open('tel:+${c.phone}'),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('اتصال'),
              style: FilledButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: kBg,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => open('https://wa.me/${c.phone}'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('واتساب'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE9FFF8),
                foregroundColor: const Color(0xFF0E7A5F),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          TextButton(
            onPressed: () => profile(c),
            child: const Text('الملف',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }

  void profile(Craftsman c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(c.job, style: const TextStyle(color: kGreen, fontSize: 17)),
                const SizedBox(height: 6),
                Text('${c.city}، ${c.state}'),
                const SizedBox(height: 6),
                Text('الهاتف: +${c.phone}'),
              ]),
        ),
      ),
    );
  }
}
