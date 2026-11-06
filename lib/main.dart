// KNL Church — Kisii Newlife SDA (Flutter native sibling).
// Single-file app: Home, Give, Songs (hymns+sermons), Family, Visit, Support.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ---------- brand + constants ----------
const kNavy = Color(0xFF0A2A5C);
const kNavy2 = Color(0xFF123A7A);
const kGold = Color(0xFFC9A227);
const kBg = Color(0xFFF4EFE4);
const kCard = Color(0xFFFFFDF8);
const kInk = Color(0xFF1E2430);
const kMuted = Color(0xFF5B6472);
const kLine = Color(0xFFE3DCC8);
const kNight = Color(0xFF0B1530);

const appVersion = '5.0';
const stkBase = 'https://knl-stk.spidmax.win';
const telChurch = 'tel:+254737428240';
const smsChurch = 'sms:+254737428240';
const waChurch =
    'https://wa.me/254737428240?text=Hello%20KNL%20Church';
const waDev = 'https://wa.me/254713702904?text=KNL%20App%20feedback%3A%20';
const ytChannel = 'https://youtube.com/@KISIINEWLIFESDACHURCH/streams';
const mapsQuery = 'https://www.google.com/maps/search/?api=1&query=8QH8'
    '+FP8+Kisii';
const osmDirs = 'https://www.openstreetmap.org/directions?'
    'to=-0.6713375%2C34.7668281';
const siteUrl = 'https://knlsda.org/';

Future<bool> openLink(String url) async {
  final u = Uri.parse(url);
  try {
    if (await canLaunchUrl(u)) {
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}
  return false;
}

void toast(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> copyText(BuildContext ctx, String text, String done) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (ctx.mounted) toast(ctx, done);
}

// ---------- models ----------
class Hymn {
  final int n;
  final String t;
  final int s;
  final List<String> v;
  final String? r;
  final String? r2;
  Hymn(
      {required this.n,
      required this.t,
      required this.s,
      required this.v,
      this.r,
      this.r2});
  factory Hymn.fromJson(Map<String, dynamic> j) => Hymn(
        n: j['n'] as int,
        t: j['t'] as String,
        s: j['s'] as int,
        v: (j['v'] as List).map((e) => e as String).toList(),
        r: j['r'] as String?,
        r2: j['r2'] as String?,
      );
}

class HymnData {
  final List<Hymn> hymns;
  final Map<int, String> sections;
  HymnData(this.hymns, this.sections);
}

Future<HymnData> loadHymns() async {
  final raw = await rootBundle.loadString('assets/hymns.json');
  final d = json.decode(raw) as Map<String, dynamic>;
  final secs = <int, String>{};
  for (final s in (d['sections'] as List)) {
    secs[(s as List)[0] as int] = (s as List)[1] as String;
  }
  final hymns = ((d['hymns'] as List)
        ..sort((a, b) => (a['n'] as int).compareTo(b['n'] as int)))
      .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
      .toList();
  return HymnData(hymns, secs);
}

String nextServiceChip() {
  final d = DateTime.now().weekday; // Mon=1..Sun=7
  if (d == 3) return '● Today: Wed Prayers • 5:30 PM';
  if (d == 5) return '● Today: Fri Vespers • 5:30 PM';
  if (d == 6) return '● Today: Sabbath • 9:00 AM';
  if (d < 3) return '● Next: Wed Prayers • 5:30 PM';
  if (d < 5) return '● Next: Fri Vespers • 5:30 PM';
  return '● Next: Sabbath • Sat 9:00 AM';
}

// ---------- app ----------
void main() => runApp(const KnlApp());

class KnlApp extends StatelessWidget {
  const KnlApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KNL Church',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: kNavy,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
            backgroundColor: kNavy, foregroundColor: Colors.white),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  static const _titles = [
    'KNL Church',
    'Give',
    'Songs',
    'Family',
    'Visit',
    'Support'
  ];
  static const _pages = [
    HomeScreen(),
    GiveScreen(),
    SongsScreen(),
    FamilyScreen(),
    VisitScreen(),
    SupportScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tab == 0
          ? null
          : AppBar(title: Text(_titles[_tab]), backgroundColor: kNavy),
      body: SafeArea(child: _pages[_tab]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kNavy,
        unselectedItemColor: kMuted,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 22)), label: 'Home'),
          BottomNavigationBarItem(icon: Text('💚', style: TextStyle(fontSize: 22)), label: 'Give'),
          BottomNavigationBarItem(icon: Text('🎶', style: TextStyle(fontSize: 22)), label: 'Songs'),
          BottomNavigationBarItem(icon: Text('🤝', style: TextStyle(fontSize: 22)), label: 'Family'),
          BottomNavigationBarItem(icon: Text('📍', style: TextStyle(fontSize: 22)), label: 'Visit'),
          BottomNavigationBarItem(icon: Text('♥', style: TextStyle(fontSize: 22, color: kGold)), label: 'Support'),
        ],
      ),
    );
  }

  void goTab(int i) => setState(() => _tab = i);
}

// ---------- shared bits ----------
class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: kMuted)),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Future<void> Function()? onTap;
  const BigButton(
      {super.key,
      required this.label,
      required this.bg,
      required this.fg,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap == null ? null : () => onTap!(),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(0, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ---------- HOME ----------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final shell = context.findAncestorStateOfType<_ShellState>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            Image.asset('assets/hero-aerial.webp',
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 210, color: kNavy)),
            Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x060E142E).withOpacity(0.15),
                    const Color(0xFF06142E).withOpacity(0.88)
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  ClipOval(
                      child: Image.asset('assets/knl-logo.png',
                          width: 60, height: 60)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kisii Newlife SDA',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const Text('KNL Church Community • Behind Quickmart, Kisii',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: kGold,
                              borderRadius: BorderRadius.circular(999)),
                          child: Text(nextServiceChip(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF231A00))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _quick('💚 Give', kNavy, Colors.white,
                  () => shell?.goTab(1)),
              _quick('🗺️ Directions', kGold, const Color(0xFF231A00),
                  () => openLink(mapsQuery)),
              _quick('🎵 Songs', kNavy, Colors.white,
                  () => shell?.goTab(2)),
              _quick('💬 WhatsApp', const Color(0xFF1FA855), Colors.white,
                  () => openLink(waChurch)),
            ],
          ),
        ),
        const _Announcements(),
        const Eyebrow('GATHERINGS'),
        const _Card(child: _SvcRows()),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: InkWell(
            onTap: () => shell?.goTab(5),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kNavy, kNavy2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text('♥', style: TextStyle(fontSize: 26, color: kGold)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support the Developer',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        Text('Keep this app running & improving',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('›',
                      style: TextStyle(color: kGold, fontSize: 24)),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(18),
          child: Center(
              child: Text('Kisii Newlife SDA (KNL) • knlsda.org • v$appVersion',
                  style: TextStyle(fontSize: 12, color: kMuted))),
        ),
      ],
    );
  }

  Widget _quick(String label, Color bg, Color fg, void Function() fn) {
    return ElevatedButton(
      onPressed: () {
        fn();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
  }
}

class _SvcRows extends StatelessWidget {
  const _SvcRows();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['🙏 Wednesday Prayers', 'Wed 5:30 PM'],
      ['🕯️ Friday Vespers', 'Fri 5:30 PM'],
      ['⛪ Sabbath Service', 'Sat 9:00 AM'],
    ];
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r[0],
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(r[1],
                        style: const TextStyle(
                            color: kNavy, fontWeight: FontWeight.w800)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Announcements extends StatelessWidget {
  const _Announcements();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/announcements.json'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        late final List items;
        try {
          items = json.decode(snap.data!) as List;
        } catch (_) {
          return const SizedBox.shrink();
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('ANNOUNCEMENTS'),
            _Card(
              child: Column(
                children: (items).map<Widget>((a) {
                  final m = a as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m['title'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text('${m['body'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 13, color: kMuted)),
                          ],
                        )),
                        Text('${m['date'] ?? ''}',
                            style: const TextStyle(
                                color: kNavy, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------- GIVE ----------
class GiveScreen extends StatelessWidget {
  const GiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Eyebrow('M-PESA GIVING • OFFICIAL PAYBILLS'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: kNight, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paybill(context, 'TITHES & OFFERINGS', '946085',
                  'Account: Tithes / Offerings', true),
              _paybill(context, 'DEVELOPMENT', '921058',
                  'Account: Home-Church / Visitor', false),
              const Text('How to pay',
                  style: TextStyle(
                      color: kGold,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                  '1. M-Pesa → Lipa na M-Pesa → Paybill\n2. Business no: 946085 or 921058\n3. Account: Tithes / Offering / Home-Church\n4. Amount → PIN → Send ✓',
                  style: TextStyle(color: Colors.white, height: 1.8)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _paybill(BuildContext ctx, String label, String num, String acc,
      bool green) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800)),
          Text(num,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: green ? const Color(0xFF8CE76A) : kGold)),
          Text(acc, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => copyText(ctx, num, '✓ $num copied'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    green ? const Color(0xFF43B02A) : kGold,
                foregroundColor:
                    green ? Colors.white : const Color(0xFF231A00),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Copy Paybill',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- SONGS ----------
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});
  @override
  State<SongsScreen> createState() => _SongsState();
}

class _SongsState extends State<SongsScreen> {
  bool _sermons = false;
  final _q = TextEditingController();
  final _jump = TextEditingController();
  int _sec = -1; // -1 all, -2 saved, -3 recent
  late Future<HymnData> _future;
  final Set<int> _favs = {};
  final List<int> _recent = [];

  @override
  void initState() {
    super.initState();
    _future = loadHymns();
  }

  @override
  void dispose() {
    _q.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFFE7E0CC),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _seg('🎵 Hymns', !_sermons,
                  () => setState(() => _sermons = false)),
              _seg('▶️ Sermons', _sermons,
                  () => setState(() => _sermons = true)),
            ],
          ),
        ),
        Expanded(child: _sermons ? _sermonList() : _hymnBrowser()),
      ],
    );
  }

  Widget _seg(String label, bool on, VoidCallback fn) {
    return Expanded(
      child: GestureDetector(
        onTap: fn,
        child: Container(
          alignment: Alignment.center,
          height: 48,
          decoration: BoxDecoration(
            color: on ? kCard : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: on ? kNavy : kMuted)),
        ),
      ),
    );
  }

  Widget _sermonList() {
    const cards = [
      ['▶', 'Divine Service • Sat 11 AM', 'Full worship replay'],
      ['📖', 'Sabbath School • Sat 9 AM', 'Lesson study replay'],
      ['🕯️', 'Vespers • Wed & Fri 5:30 PM', 'Midweek prayer replay'],
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: cards
          .map((c) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: kNight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  leading: CircleAvatar(
                      backgroundColor: kGold,
                      child: Text(c[0],
                          style: const TextStyle(fontSize: 20))),
                  title: Text(c[1],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text(c[2],
                      style: const TextStyle(color: Colors.white70)),
                  trailing: const Text('Watch ›',
                      style: TextStyle(
                          color: kGold, fontWeight: FontWeight.w800)),
                  onTap: () => openLink(ytChannel),
                ),
              ))
          .toList(),
    );
  }

  Widget _hymnBrowser() {
    return FutureBuilder<HymnData>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load hymnal.'),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () =>
                      setState(() => _future = loadHymns()),
                  child: const Text('Retry')),
            ],
          ));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final pool = _filter(data);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _q,
                      decoration: const InputDecoration(
                        hintText: 'Title, №, first line…',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: TextField(
                      controller: _jump,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '№',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final n = int.tryParse(_jump.text);
                        if (n == null) return;
                        final hit = data.hymns
                            .where((h) => h.n == n)
                            .toList();
                        if (hit.isNotEmpty) _open(hit.first, data);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kNavy,
                          foregroundColor: Colors.white),
                      child: const Text('Go',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                children: [
                  _chip('All 695', -1),
                  _chip('★ Saved', -2),
                  _chip('🕘 Recent', -3),
                  for (final e in data.sections.entries)
                    _chip(e.value, e.key),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${pool.length} hymns',
                    style:
                        const TextStyle(fontSize: 12, color: kMuted)),
              ),
            ),
            Expanded(
              child: pool.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      itemCount: pool.length > 150 ? 150 : pool.length,
                      itemBuilder: (c, i) {
                        final x = pool[i];
                        return Card(
                          child: ListTile(
                            minVerticalPadding: 10,
                            leading: Container(
                              width: 52,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: kNavy,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${x.n}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                            ),
                            title: Text(x.t,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${data.sections[x.s] ?? ''} • ${x.v.length}v${(x.r != null || x.r2 != null) ? ' • refrain' : ''}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                                _favs.contains(x.n) ? '★' : '',
                                style: const TextStyle(
                                    color: kGold, fontSize: 20)),
                            onTap: () => _open(x, data),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, int id) {
    final on = _sec == id;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => setState(() => _sec = id),
        selectedColor: kNavy,
        labelStyle: TextStyle(
            color: on ? Colors.white : kNavy, fontWeight: FontWeight.w700),
      ),
    );
  }

  List<Hymn> _filter(HymnData data) {
    Iterable<Hymn> pool = data.hymns;
    if (_sec == -2) {
      pool = pool.where((h) => _favs.contains(h.n));
    } else if (_sec == -3) {
      final order = {for (var i = 0; i < _recent.length; i++) _recent[i]: i};
      final list =
          pool.where((h) => order.containsKey(h.n)).toList();
      list.sort((a, b) => order[a.n]!.compareTo(order[b.n]!));
      pool = list;
    } else if (_sec >= 0) {
      pool = pool.where((h) => h.s == _sec);
    }
    final q = _q.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      pool = pool.where((h) =>
          h.t.toLowerCase().contains(q) ||
          '${h.n}'.startsWith(q) ||
          (h.v.isNotEmpty && h.v.first.toLowerCase().contains(q)));
    }
    return pool.toList();
  }

  void _open(Hymn x, HymnData data) {
    setState(() {
      _recent.remove(x.n);
      _recent.insert(0, x.n);
      if (_recent.length > 20) _recent.removeLast();
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ReaderScreen(
                hymn: x,
                all: data.hymns,
                secName: data.sections[x.s] ?? '',
                fav: _favs.contains(x.n),
                onFav: () =>
                    setState(() => _toggleFav(x.n)))));
  }

  void _toggleFav(int n) {
    if (_favs.contains(n)) {
      _favs.remove(n);
    } else {
      _favs.add(n);
    }
  }
}

class ReaderScreen extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn> all;
  final String secName;
  final bool fav;
  final VoidCallback onFav;
  const ReaderScreen(
      {super.key,
      required this.hymn,
      required this.all,
      required this.secName,
      required this.fav,
      required this.onFav});
  @override
  State<ReaderScreen> createState() => _ReaderState();
}

class _ReaderState extends State<ReaderScreen> {
  late Hymn _h;
  double _size = 19;
  @override
  void initState() {
    super.initState();
    _h = widget.hymn;
  }

  void _step(int d) {
    final i = widget.all.indexWhere((h) => h.n == _h.n);
    final n = widget.all[(i + d + widget.all.length) % widget.all.length];
    setState(() => _h = n);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (var i = 0; i < _h.v.length; i++) {
      blocks.add(_verse('VERSE ${i + 1}', _h.v[i], false));
      if (i == 0 && _h.r != null) {
        blocks.add(_verse('REFRAIN', _h.r!, true));
      }
    }
    if (_h.r2 != null) blocks.add(_verse('REFRAIN', _h.r2!, true));
    return Scaffold(
      appBar: AppBar(
        title: Text('${_h.n} • ${_h.t}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Text(widget.fav ? '★' : '☆',
                style: const TextStyle(fontSize: 24, color: kGold)),
            onPressed: () {
              widget.onFav();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
              child: Text(
                  '${widget.secName} • ${_h.v.length} verses${(_h.r != null || _h.r2 != null) ? ' • refrain' : ''}',
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: kMuted,
                      fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          ...blocks,
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _step(-1),
                      child: const Text('‹ Prev'))),
              IconButton(
                  onPressed: () => setState(
                      () => _size = (_size - 2).clamp(15, 26).toDouble()),
                  icon: const Text('A−',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              IconButton(
                  onPressed: () => setState(
                      () => _size = (_size + 2).clamp(15, 26).toDouble()),
                  icon: const Text('A+',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _step(1),
                      child: const Text('Next ›'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verse(String label, String text, bool refrain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: refrain ? const Color(0xFFF7F3E6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: kNavy)),
          const SizedBox(height: 6),
          Text(text,
              style: TextStyle(
                  fontSize: _size,
                  height: 1.8,
                  fontStyle:
                      refrain ? FontStyle.italic : FontStyle.normal)),
        ],
      ),
    );
  }
}

// ---------- FAMILY ----------
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: SizedBox.shrink(),
          ),
        ),
        const Eyebrow('LIFE AT KNL'),
        _Card(
          child: Image.asset('assets/youth.webp',
              errorBuilder: (_, __, ___) =>
                  const SizedBox(height: 120, child: Center(child: Text('🤝')))),
        ),
        const Eyebrow('PROGRAMS'),
        _Card(
          child: Column(
            children: const [
              _MRow('📖', 'Bible Study', 'Grow in the Word week by week'),
              _MRow('🎶', 'Sing & Praise', 'Choir and worship music'),
              _MRow('🌍', 'Community Outreach', 'Serving Kisii town'),
              _MRow('🌿', 'Nature Fellowships', 'Worship outdoors together'),
            ],
          ),
        ),
        const Eyebrow('MINISTRIES • TEAM KNL'),
        _Card(
          child: Column(
            children: const [
              _MRow('🧒', 'Children',
                  'Nurturing young hearts to follow Jesus'),
              _MRow('🔥', 'Youths', 'Empowering young leaders'),
              _MRow('👫', 'ALO & AMO',
                  'Men & women championing God\'s purpose'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MRow extends StatelessWidget {
  final String ic;
  final String title;
  final String sub;
  const _MRow(this.ic, this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF3E6B8),
                borderRadius: BorderRadius.circular(12)),
            child: Text(ic, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(sub,
                    style:
                        const TextStyle(fontSize: 13, color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- VISIT ----------
class VisitScreen extends StatelessWidget {
  const VisitScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Eyebrow('PLAN YOUR VISIT'),
        const _Card(child: _SvcRows()),
        const Eyebrow('FIND US'),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Plus code: 8QH8+FP8\nBehind Quickmart, Kisii town\nP.O Box 3970, 40200, Kisii, Kenya\nPhone: 0737 428 240',
                  style: TextStyle(height: 1.6)),
              const SizedBox(height: 10),
              BigButton(
                  label: '🗺️ Get directions',
                  bg: kGold,
                  fg: const Color(0xFF231A00),
                  onTap: () => openLink(mapsQuery)),
              const SizedBox(height: 8),
              BigButton(
                  label: '🧭 OSM directions',
                  bg: kNavy,
                  fg: Colors.white,
                  onTap: () => openLink(osmDirs)),
            ],
          ),
        ),
        const Eyebrow('CONTACT'),
        _Card(
          child: Column(
            children: [
              BigButton(
                  label: '📞 Call 0737 428 240',
                  bg: kNavy,
                  fg: Colors.white,
                  onTap: () => openLink(telChurch)),
              const SizedBox(height: 8),
              BigButton(
                  label: '💬 WhatsApp the church',
                  bg: const Color(0xFF1FA855),
                  fg: Colors.white,
                  onTap: () => openLink(waChurch)),
              const SizedBox(height: 8),
              BigButton(
                  label: '✉️ Send SMS',
                  bg: kCard,
                  fg: kNavy,
                  onTap: () => openLink(smsChurch)),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => openLink(siteUrl),
                child: const Text('Visit knlsda.org 🌐',
                    style: TextStyle(
                        color: kNavy2,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
              const SizedBox(height: 8),
              Text('KNL Church • v$appVersion',
                  style: const TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------- SUPPORT ----------
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportState();
}

class _SupportState extends State<SupportScreen> {
  final _phone = TextEditingController();
  final _amt = TextEditingController();
  int _chip = -1;
  bool _sending = false;
  String _msg = '';
  Color _msgColor = Colors.white;
  Map<String, dynamic>? _receipt;
  final List<Map<String, String>> _hist = [];

  static const _amounts = [20, 50, 100, 200, 500];

  @override
  void dispose() {
    _phone.dispose();
    _amt.dispose();
    super.dispose();
  }

  String _norm(String raw) {
    var ph = raw.replaceAll(RegExp(r'[\s\-+]'), '');
    if (ph.startsWith('0')) ph = '254${ph.substring(1)}';
    if (!ph.startsWith('254') && ph.length == 9) ph = '254$ph';
    return ph;
  }

  Future<void> _send() async {
    final ph = _norm(_phone.text);
    if (!RegExp(r'^254[17]\d{8}$').hasMatch(ph)) {
      setState(() {
        _msg = 'Enter a valid Safaricom number (07… or 254…).';
        _msgColor = const Color(0xFFFFB4A8);
        _receipt = null;
      });
      return;
    }
    final amt = int.tryParse(_amt.text) ?? 0;
    if (amt < 10) {
      setState(() {
        _msg = 'Pick an amount above, or type at least KSh 10.';
        _msgColor = const Color(0xFFFFB4A8);
        _receipt = null;
      });
      return;
    }
    setState(() {
      _sending = true;
      _msg = 'Prompt on its way — check the phone now.';
      _msgColor = const Color(0xFFFFE9A8);
      _receipt = null;
    });
    try {
      final r = await http
          .post(Uri.parse('$stkBase/api/pay'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': ph, 'amount': amt}))
          .timeout(const Duration(seconds: 45));
      final d = json.decode(r.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (r.statusCode == 200 && d['CheckoutRequestID'] != null) {
        setState(() {
          _msg = '';
          _receipt = {
            'amt': '$amt',
            'id': '${d['CheckoutRequestID']}',
            'when': DateTime.now().toString().substring(0, 16),
          };
        });
        _hist.insert(0, {
          'a': '$amt',
          'd': DateTime.now().toString().substring(0, 10)
        });
        if (_hist.length > 10) _hist.removeLast();
      } else if (d['demo'] == true) {
        setState(() {
          _msg = 'STK service is linking — please try again shortly.';
          _msgColor = const Color(0xFFFFD97A);
        });
      } else {
        setState(() {
          _msg = '⚠ ${d['message'] ?? 'Prompt failed — please try again.'}';
          _msgColor = const Color(0xFFFFB4A8);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msg = '⚠ Network error — check connection and try again.';
        _msgColor = const Color(0xFFFFB4A8);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kNight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGold.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: kGold, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                    'NOT a church tithe — tithes live under Give',
                    style: TextStyle(
                        color: kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              const Text('Keep this app running & improving',
                  style: TextStyle(
                      color: kGold,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const Text(
                  'Your gift pays for the server, the offline hymnal and fresh content. An M-Pesa prompt lands straight on the phone.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.6)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _amounts.length; i++)
                    ChoiceChip(
                      label: Text('${_amounts[i]}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900)),
                      selected: _chip == i,
                      onSelected: (_) => setState(() {
                        _chip = i;
                        _amt.text = '${_amounts[i]}';
                      }),
                      selectedColor: kGold,
                    ),
                  ChoiceChip(
                    label: const Text('Other',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    selected: _chip == 99,
                    onSelected: (_) => setState(() {
                      _chip = 99;
                      _amt.clear();
                    }),
                    selectedColor: kGold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('M-Pesa phone for prompt',
                  style: TextStyle(
                      color: kGold, fontWeight: FontWeight.w700)),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: '07… / 254…',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Amount (KSh, min 10)',
                  style: TextStyle(
                      color: kGold, fontWeight: FontWeight.w700)),
              TextField(
                controller: _amt,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Tap an amount above or type',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
                onChanged: (_) => setState(() => _chip = -1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: const Color(0xFF231A00),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3)),
                            SizedBox(width: 10),
                            Text('Sending…',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17)),
                          ],
                        )
                      : const Text('Send M-Pesa Prompt',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17)),
                ),
              ),
              if (_msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_msg,
                      style: TextStyle(color: _msgColor, fontSize: 14)),
                ),
              if (_receipt != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: kGold, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('✓ PROMPT SENT',
                          style: TextStyle(
                              color: kGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      Text('KSh ${_receipt!['amt']}',
                          style: const TextStyle(
                              color: Color(0xFF8CE76A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                      Text(
                          'Enter your M-Pesa PIN on ${_phone.text} to finish.',
                          style: const TextStyle(color: Colors.white)),
                      Text(
                          '${_receipt!['id']} • ${_receipt!['when']}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('WHY GIVE HERE',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: kMuted)),
        const _Card(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🖥️ Server & hosting that delivers every STK prompt',
                style: TextStyle(height: 2)),
            Text('🎵 Offline hymnal — all 695 songs, no data needed',
                style: TextStyle(height: 2)),
            Text('📢 Fresh announcements & sermon updates',
                style: TextStyle(height: 2)),
          ],
        )),
        const SizedBox(height: 12),
        const Text('TALK TO THE DEVELOPER',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: kMuted)),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Bug? Idea? Opens straight into the developer\'s WhatsApp.'),
              const SizedBox(height: 8),
              BigButton(
                  label: '💬 WhatsApp feedback',
                  bg: const Color(0xFF1FA855),
                  fg: Colors.white,
                  onTap: () => openLink(waDev)),
            ],
          ),
        ),
        if (_hist.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('YOUR RECENT SUPPORT • THIS PHONE ONLY',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: kMuted)),
          _Card(
            child: Column(
              children: _hist
                  .map((x) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('♥ KSh ${x['a']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text('${x['d']}',
                                style: const TextStyle(
                                    color: kNavy,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
