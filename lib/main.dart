// KNL Church — Kisii Newlife SDA (Flutter native, Material 3).
// Tabs: Home, Give, Songs (hymns+sermons), Family, Visit, Support.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------- brand + constants ----------
const kNavy = Color(0xFF0A2A5C);
const kNavy2 = Color(0xFF123A7A);
const kGold = Color(0xFFC9A227);
const kInk = Color(0xFF1E2430);
const kNight = Color(0xFF0B1530);
const kCream = Color(0xFFF3E6B8);

const appVersion = '5.4';
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

Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

List<int> _intList(List<String> ss) {
  final out = <int>[];
  for (final s in ss) {
    final n = int.tryParse(s);
    if (n != null) out.add(n);
  }
  return out;
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
    final row = (s as List).toList();
    secs[row[0] as int] = row[1] as String;
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
    final scheme = ColorScheme.fromSeed(seedColor: kNavy).copyWith(
      secondary: kGold,
      surface: const Color(0xFFF4EFE4),
    );
    return MaterialApp(
      title: 'KNL Church',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: kCream,
        ),
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
  void goTab(int i) => setState(() => _tab = i);

  @override
  void initState() {
    super.initState();
    _maybeTour();
  }

  Future<void> _maybeTour() async {
    final p = await prefs();
    if ((p.getBool('knl_tour') ?? false) || !mounted) return;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const TourDialog());
    await p.setBool('knl_tour', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: _tab != 0,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onGo: goTab),
            const GiveScreen(),
            const SongsScreen(),
            const FamilyScreen(),
            const VisitScreen(),
            const SupportScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: goTab,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Give'),
          NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: 'Songs'),
          NavigationDestination(
              icon: Icon(Icons.diversity_3_outlined),
              selectedIcon: Icon(Icons.diversity_3),
              label: 'Family'),
          NavigationDestination(
              icon: Icon(Icons.church_outlined),
              selectedIcon: Icon(Icons.church),
              label: 'Visit'),
          NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake),
              label: 'Support'),
        ],
      ),
    );
  }
}

class TourDialog extends StatefulWidget {
  const TourDialog({super.key});
  @override
  State<TourDialog> createState() => _TourState();
}

class _TourState extends State<TourDialog> {
  final _ctl = PageController();
  int _i = 0;
  static const _pages = [
    [
      'Karibu to KNL ✝',
      'Kisii Newlife SDA in your pocket — service times, giving, hymns & directions. Works offline in church.'
    ],
    [
      'Give in seconds',
      'Tithes via Paybill 946085, or a prompt straight to your phone from the ♥ tab.'
    ],
    [
      '695 hymns, fully offline',
      'Every hymn with lyrics, no data needed — plus Sabbath times and the map to 8QH8+FP8.'
    ],
  ];
  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kNight,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: kGold)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
                child: Image.asset('assets/knl-logo.png',
                    width: 76, height: 76)),
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _ctl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(_pages[i][0],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kGold,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(_pages[i][1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, height: 1.6)),
                  ],
                ),
              ),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 0; k < _pages.length; k++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: k == _i
                              ? kGold
                              : Colors.white30),
                    ),
                ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white54)),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (_i < _pages.length - 1) {
                        _ctl.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor:
                            const Color(0xFF231A00)),
                    child: Text(_i < _pages.length - 1
                        ? 'Next ›'
                        : 'Enter ✝'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- HOME ----------
class HomeScreen extends StatelessWidget {
  final void Function(int) onGo;
  const HomeScreen({super.key, required this.onGo});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          backgroundColor: kNavy,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Kisii Newlife SDA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            titlePadding:
                const EdgeInsetsDirectional.only(start: 88, bottom: 14),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/hero-aerial.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: kNavy)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF06142E).withValues(alpha: 0.15),
                        const Color(0xFF06142E).withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 40,
                  child: Row(
                    children: [
                      ClipOval(
                          child: Image.asset('assets/knl-logo.png',
                              width: 56, height: 56)),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KNL Church Community',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          Text('Behind Quickmart, Kisii',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Container(
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
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  FilledButton.icon(
                      onPressed: () => onGo(1),
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Give',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  FilledButton.tonalIcon(
                      onPressed: () => openLink(mapsQuery),
                      icon: const Icon(Icons.map),
                      label: const Text('Directions',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  FilledButton.icon(
                      onPressed: () => onGo(2),
                      icon: const Icon(Icons.music_note),
                      label: const Text('Songs',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  FilledButton.tonalIcon(
                      onPressed: () => openLink(waChurch),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                ],
              ),
            ),
            const _Announcements(),
            _eyebrow(context, 'GATHERINGS'),
            _SvcCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Card.filled(
                color: kNavy,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onGo(5),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.favorite,
                            color: kGold, size: 28),
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
                                      color: Colors.white70,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: kGold),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                  child: Text(
                      'Kisii Newlife SDA (KNL) • knlsda.org • v$appVersion',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant))),
            ),
          ]),
        ),
      ],
    );
  }
}

Widget _eyebrow(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        letterSpacing: 1.2, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  );
}

class _SvcCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Wednesday Prayers', 'Wed 5:30 PM', Icons.nights_stay_outlined],
      ['Friday Vespers', 'Fri 5:30 PM', Icons.bedtime_outlined],
      ['Sabbath Service', 'Sat 9:00 AM', Icons.church_outlined],
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: rows
            .map((r) => ListTile(
                  leading: Icon(r[2] as IconData, color: kNavy),
                  title: Text(r[0] as String,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Text(r[1] as String,
                      style: const TextStyle(
                          color: kNavy,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ))
            .toList(),
      ),
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
            _eyebrow(context, 'ANNOUNCEMENTS'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: (items).map<Widget>((a) {
                  final m = a as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.campaign_outlined,
                        color: kGold),
                    title: Text('${m['title'] ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800)),
                    subtitle: Text('${m['body'] ?? ''}'),
                    trailing: Text('${m['date'] ?? ''}',
                        style: const TextStyle(
                            color: kNavy, fontWeight: FontWeight.w800)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Give')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card.filled(
            color: kNight,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('M-PESA GIVING • OFFICIAL PAYBILLS',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: kGold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _paybill(context, 'TITHES & OFFERINGS', '946085',
                      'Account: Tithes / Offerings', true),
                  _paybill(context, 'DEVELOPMENT', '921058',
                      'Account: Home-Church / Visitor', false),
                  Text('How to pay',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: kGold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  const Text(
                      '1. M-Pesa → Lipa na M-Pesa → Paybill\n2. Business no: 946085 or 921058\n3. Account: Tithes / Offering / Home-Church\n4. Amount → PIN → Send ✓',
                      style: TextStyle(color: Colors.white, height: 1.8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paybill(BuildContext ctx, String label, String num, String acc,
      bool green) {
    return Card.outlined(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800)),
            SelectableText(num,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: green ? const Color(0xFF8CE76A) : kGold)),
            Text(acc, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => copyText(ctx, num, '✓ $num copied'),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Paybill'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    green ? const Color(0xFF43B02A) : kGold,
                foregroundColor:
                    green ? Colors.white : const Color(0xFF231A00),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
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
  final _note = TextEditingController();
  List<String> _notes = [];
  int _sec = -1; // -1 all, -2 saved, -3 recent
  late Future<HymnData> _future;
  final Set<int> _favs = {};
  final List<int> _recent = [];

  @override
  void initState() {
    super.initState();
    _future = loadHymns();
    prefs().then((p) {
      if (!mounted) return;
      setState(() {
        _favs.addAll(_intList(p.getStringList('knl_favs') ?? []));
        for (final n in _intList(p.getStringList('knl_recent') ?? [])) {
          if (!_recent.contains(n)) _recent.add(n);
        }
      });
    });
    _loadNotes();
  }

  void _persistHymns() {
    prefs().then((p) {
      p.setStringList(
          'knl_favs', _favs.map((e) => '$e').toList());
      p.setStringList(
          'knl_recent', _recent.map((e) => '$e').toList());
    });
  }

  @override
  void dispose() {
    _q.dispose();
    _jump.dispose();
    _note.dispose();
    super.dispose();
  }

  void _loadNotes() {
    prefs().then((p) {
      if (!mounted) return;
      setState(
          () => _notes = p.getStringList('knl_notes') ?? []);
    });
  }

  void _saveNotes() {
    prefs().then((p) => p.setStringList('knl_notes', _notes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.music_note),
                    label: Text('Hymns')),
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.play_circle),
                    label: Text('Sermons')),
              ],
              selected: {_sermons},
              onSelectionChanged: (s) =>
                  setState(() => _sermons = s.first),
            ),
          ),
          Expanded(child: _sermons ? _sermonList() : _hymnBrowser()),
        ],
      ),
    );
  }

  Widget _sermonList() {
    const cards = [
      [Icons.church, 'Divine Service • Sat 11 AM', 'Full worship replay'],
      [Icons.menu_book, 'Sabbath School • Sat 9 AM', 'Lesson study replay'],
      [Icons.bedtime, 'Vespers • Wed & Fri 5:30 PM', 'Midweek prayer replay'],
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (var i = 0; i < cards.length; i++)
          _sermonCard(cards[i]),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY SERMON NOTES • THIS PHONE ONLY',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 8 Nov — faith of Daniel…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                          onPressed: _addNote,
                          child: const Text('Save note')),
                    ),
                  ],
                ),
                for (var k = 0; k < _notes.length; k++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.note_alt_outlined,
                        color: kNavy),
                    title: Text(_notes[k]),
                    trailing: IconButton(
                      tooltip: 'Delete note',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _notes.removeAt(k);
                        _saveNotes();
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addNote() {
    final t = _note.text.trim();
    if (t.isEmpty) {
      toast(context, 'Write a note first.');
      return;
    }
    setState(() {
      _notes.insert(
          0, '${DateTime.now().toString().substring(0, 10)} — $t');
      if (_notes.length > 30) _notes.removeLast();
      _note.clear();
      _saveNotes();
    });
  }

  Widget _sermonCard(List card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card.filled(
        color: kNight,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
              backgroundColor: kGold,
              child: Icon(card[0] as IconData, color: kNight)),
          title: Text(card[1] as String,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          subtitle: Text(card[2] as String,
              style: const TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.play_arrow, color: kGold),
          onTap: () => openLink(ytChannel),
        ),
      ),
    );
  }

  Widget _hymnBrowser() {
    return FutureBuilder<HymnData>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.hasError || (snap.connectionState == ConnectionState.done &&
            !snap.hasData)) {
          return Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load hymnal.'),
              const SizedBox(height: 8),
              FilledButton(
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
                    child: SearchBar(
                      controller: _q,
                      hintText: 'Title, №, first line…',
                      leading: const Icon(Icons.search),
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
                    child: FilledButton(
                      onPressed: () {
                        final n = int.tryParse(_jump.text);
                        if (n == null) return;
                        final hit = data.hymns
                            .where((h) => h.n == n)
                            .toList();
                        if (hit.isNotEmpty) _open(hit.first, data);
                      },
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${pool.length} hymns',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
            Expanded(
              child: pool.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      itemCount: pool.length > 150 ? 150 : pool.length,
                      itemBuilder: (c, i) {
                        final x = pool[i];
                        return Card(
                          child: ListTile(
                            minVerticalPadding: 10,
                            leading: CircleAvatar(
                              backgroundColor: kNavy,
                              foregroundColor: Colors.white,
                              child: Text('${x.n}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ])),
                            ),
                            title: Text(x.t,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${data.sections[x.s] ?? ''} • ${x.v.length}v${(x.r != null || x.r2 != null) ? ' • refrain' : ''}',
                                style:
                                    const TextStyle(fontSize: 12)),
                            trailing: _favs.contains(x.n)
                                ? const Icon(Icons.star,
                                    color: kGold)
                                : null,
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _sec == id,
        onSelected: (_) => setState(() => _sec = id),
      ),
    );
  }

  Widget _emptyState() {
    final bool fav = _sec == -2;
    final bool rec = _sec == -3;
    final IconData ic =
        fav ? Icons.star_outline : rec ? Icons.history : Icons.search_off;
    final String title = fav
        ? 'No saved hymns yet'
        : rec
            ? 'Nothing recent yet'
            : 'No matches';
    final String sub = fav
        ? 'Tap ☆ inside any hymn to build your songbook.'
        : rec
            ? 'Hymns you open will appear here.'
            : 'Try a title, a number 1–695, or a first line.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 48, color: kMuted),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(sub, textAlign: TextAlign.center),
            if (fav || rec) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: () => setState(() => _sec = -1),
                  child: const Text('Browse all hymns')),
            ],
          ],
        ),
      ),
    );
  }

  List<Hymn> _filter(HymnData data) {
    Iterable<Hymn> pool = data.hymns;
    if (_sec == -2) {
      pool = pool.where((h) => _favs.contains(h.n));
    } else if (_sec == -3) {
      final order = {
        for (var i = 0; i < _recent.length; i++) _recent[i]: i
      };
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
    _persistHymns();
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
    _persistHymns();
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
    final n =
        widget.all[(i + d + widget.all.length) % widget.all.length];
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
            icon: Icon(widget.fav ? Icons.star : Icons.star_outline,
                color: kGold),
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
                  style: Theme.of(context).textTheme.labelLarge)),
          const SizedBox(height: 12),
          ...blocks,
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              IconButton(
                  tooltip: 'Previous hymn',
                  onPressed: () => _step(-1),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Slider(
                  value: _size,
                  min: 15,
                  max: 26,
                  divisions: 11,
                  label: 'Text ${_size.round()}',
                  onChanged: (v) => setState(() => _size = v),
                ),
              ),
              IconButton(
                  tooltip: 'Next hymn',
                  onPressed: () => _step(1),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verse(String label, String text, bool refrain) {
    return Card(
      color: refrain ? kCream : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SelectableText(text,
                style: TextStyle(
                    fontSize: _size,
                    height: 1.8,
                    fontStyle: refrain
                        ? FontStyle.italic
                        : FontStyle.normal)),
          ],
        ),
      ),
    );
  }
}

// ---------- FAMILY ----------
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/youth.webp',
                errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(
                        child: Icon(Icons.group, size: 48)))),
          ),
          const SizedBox(height: 14),
          Text('PROGRAMS',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                _MRow(Icons.menu_book_outlined, 'Bible Study',
                    'Grow in the Word week by week'),
                _MRow(Icons.music_note_outlined, 'Sing & Praise',
                    'Choir and worship music'),
                _MRow(Icons.public_outlined, 'Community Outreach',
                    'Serving Kisii town'),
                _MRow(Icons.park_outlined, 'Nature Fellowships',
                    'Worship outdoors together'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('MINISTRIES • TEAM KNL',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                _MRow(Icons.child_care_outlined, 'Children',
                    'Nurturing young hearts to follow Jesus'),
                _MRow(Icons.local_fire_department_outlined, 'Youths',
                    'Empowering young leaders'),
                _MRow(Icons.people_outline, 'ALO & AMO',
                    'Men & women championing God\'s purpose'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MRow extends StatelessWidget {
  final IconData ic;
  final String title;
  final String sub;
  const _MRow(this.ic, this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: kCream, child: Icon(ic, color: kNavy)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
    );
  }
}

// ---------- VISIT ----------
class VisitScreen extends StatelessWidget {
  const VisitScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('PLAN YOUR VISIT',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          const Card(child: _SvcRows()),
          const SizedBox(height: 14),
          Text('FIND US', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SelectableText(
                      'Plus code: 8QH8+FP8\nBehind Quickmart, Kisii town\nP.O Box 3970, 40200, Kisii, Kenya\nPhone: 0737 428 240',
                      style: TextStyle(height: 1.6)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: () => openLink(mapsQuery),
                      icon: const Icon(Icons.map),
                      label: const Text('Get directions'),
                      style: FilledButton.styleFrom(
                          backgroundColor: kGold,
                          foregroundColor: const Color(0xFF231A00),
                          minimumSize:
                              const Size(double.infinity, 52))),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                      onPressed: () => openLink(osmDirs),
                      icon: const Icon(Icons.explore),
                      label: const Text('OSM directions')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('CONTACT', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FilledButton.icon(
                      onPressed: () => openLink(telChurch),
                      icon: const Icon(Icons.call),
                      label: const Text('Call 0737 428 240')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      onPressed: () => openLink(waChurch),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp the church'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1FA855))),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                      onPressed: () => openLink(smsChurch),
                      icon: const Icon(Icons.sms),
                      label: const Text('Send SMS')),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => openLink(siteUrl),
                    child: Text('Visit knlsda.org 🌐',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: kNavy2)),
                  ),
                  const SizedBox(height: 6),
                  Text('KNL Church • v$appVersion',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                      onPressed: () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const TourDialog()),
                      icon: const Icon(Icons.replay),
                      label: const Text('Replay welcome tour')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SvcRows extends StatelessWidget {
  const _SvcRows();
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Wednesday Prayers', 'Wed 5:30 PM', Icons.nights_stay_outlined],
      ['Friday Vespers', 'Fri 5:30 PM', Icons.bedtime_outlined],
      ['Sabbath Service', 'Sat 9:00 AM', Icons.church_outlined],
    ];
    return Column(
      children: rows
          .map((r) => ListTile(
                leading: Icon(r[2] as IconData, color: kNavy),
                title: Text(r[0] as String,
                    style:
                        const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Text(r[1] as String,
                    style: const TextStyle(
                        color: kNavy,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ))
          .toList(),
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
  void initState() {
    super.initState();
    prefs().then((p) {
      if (!mounted) return;
      setState(() {
        _phone.text = p.getString('knl_phone') ?? '';
        _hist.clear();
        for (final s in p.getStringList('knl_hist') ?? <String>[]) {
          final parts = s.split('|');
          if (parts.length == 2) {
            _hist.add({'a': parts[0], 'd': parts[1]});
          }
        }
      });
    });
  }

  void _persistSupport() {
    prefs().then((p) {
      p.setString('knl_phone', _phone.text);
      p.setStringList('knl_hist',
          _hist.map((x) => '${x['a']}|${x['d']}').toList());
    });
  }

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
        _persistSupport();
      } else if (d['demo'] == true) {
        setState(() {
          _msg = 'STK service is linking — please try again shortly.';
          _msgColor = const Color(0xFFFFD97A);
        });
      } else {
        setState(() {
          _msg =
              '⚠ ${d['message'] ?? 'Prompt failed — please try again.'}';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card.filled(
            color: kNight,
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                        ),
                      ChoiceChip(
                        label: const Text('Other',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                        selected: _chip == 99,
                        onSelected: (_) => setState(() {
                          _chip = 99;
                          _amt.clear();
                        }),
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
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: const Color(0xFF231A00),
                        minimumSize: const Size(0, 56),
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
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17)),
                    ),
                  ),
                  if (_msg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_msg,
                          style:
                              TextStyle(color: _msgColor, fontSize: 14)),
                    ),
                  if (_receipt != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: kGold),
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
                              style:
                                  const TextStyle(color: Colors.white)),
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
          ),
          const SizedBox(height: 14),
          Text('WHY GIVE HERE',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          const Card(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  leading: Icon(Icons.dns_outlined, color: kNavy),
                  title: Text(
                      'Server & hosting that delivers every STK prompt')),
              ListTile(
                  leading: Icon(Icons.music_note_outlined, color: kNavy),
                  title: Text(
                      'Offline hymnal — all 695 songs, no data needed')),
              ListTile(
                  leading:
                      Icon(Icons.campaign_outlined, color: kNavy),
                  title: Text('Fresh announcements & sermon updates')),
            ],
          )),
          const SizedBox(height: 14),
          Text('TALK TO THE DEVELOPER',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Bug? Idea? Opens straight into the developer\'s WhatsApp.'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      onPressed: () => openLink(waDev),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp feedback'),
                      style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1FA855))),
                ],
              ),
            ),
          ),
          if (_hist.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('YOUR RECENT SUPPORT • THIS PHONE ONLY',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _hist
                    .map((x) => ListTile(
                          leading: const Icon(Icons.favorite,
                              color: kGold),
                          title: Text('KSh ${x['a']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          trailing: Text('${x['d']}',
                              style: const TextStyle(
                                  color: kNavy,
                                  fontWeight: FontWeight.w800)),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
