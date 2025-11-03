// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemNavigator;

// ⚙️ Create a global Supabase client for easy access
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://odmfqhaosvvscbgcghie.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kbWZxaGFvc3Z2c2NiZ2NnaGllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNDI3MTIsImV4cCI6MjA3NTYxODcxMn0.vSVWiruqXCGNkUieO-j1noWE4K8KzTUOLEfSAPP-sUk',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: 'pk_test_YnVzeS1yb2Jpbi01NS5jbGVyay5hY2NvdW50cy5kZXYk',
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Link Saver',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF08787),
            // ⚙️ CORRECTED THE TYPO HERE
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFF1F1F1F),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

// ... THE REST OF THE CODE IS EXACTLY THE SAME AS THE PREVIOUS VERSION ...
// I am including it all below so you can copy and paste the entire file.

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      signedInBuilder: (context, authState) {
        final user = authState.user;
        final email = user?.emailAddresses?.isNotEmpty == true 
            ? user!.emailAddresses!.first.emailAddress 
            : '';
        final isAdmin = email.trim().toLowerCase() == 'sohammisal22@gmail.com';

        final Widget dest = isAdmin ? const AdminDashboard() : const HomePage();
        return _EnsureUserMapping(child: dest);
      },
      signedOutBuilder: (context, authState) {
        return const _SignedOutGate();
      },
    );
  }
}

class _EnsureUserMapping extends StatefulWidget {
  final Widget child;
  const _EnsureUserMapping({required this.child});

  @override
  State<_EnsureUserMapping> createState() => _EnsureUserMappingState();
}

class _EnsureUserMappingState extends State<_EnsureUserMapping> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ensure();
  }

  Future<void> _ensure() async {
    try {
      final user = ClerkAuth.of(context).user;
      if (user == null) return;
      // Upsert mapping: if you later adopt different supabase user ids, replace value accordingly
      await supabase
          .from('user_mapping')
          .upsert({
            'clerk_user_id': user.id,
            'supabase_user_id': user.id,
          })
          .select()
          .maybeSingle();
    } catch (_) {}
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SignedOutGate extends StatefulWidget {
  const _SignedOutGate();

  @override
  State<_SignedOutGate> createState() => _SignedOutGateState();
}

class _SignedOutGateState extends State<_SignedOutGate> {
  bool _showAuth = false;

  @override
  void initState() {
    super.initState();
    // Briefly delay rendering the auth UI to avoid flashing the login screen
    // while a valid session is being restored in the background.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showAuth = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showAuth) {
      return const _SplashScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF08787),
              Color(0xFFFFC7A7),
              Color(0xFFFEE2AD),
              Color(0xFFF8FAB4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(height: 8),
                        Text(
                          'Welcome to Link Saver',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 12),
                        ClerkAuthentication(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF08787),
            Color(0xFFFFC7A7),
            Color(0xFFFEE2AD),
            Color(0xFFF8FAB4),
          ],
        ),
      ),
      child: const SafeArea(
        child: Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  int _totalUsers = 0;
  int _totalLinks = 0;
  int _totalFolders = 0;
  int _activeUsersToday = 0;

  List<Map<String, dynamic>> _recentSaves = [];
  List<Map<String, dynamic>> _topSources = [];
  List<Map<String, dynamic>> _popularFolders = [];
  List<Map<String, dynamic>> _newUsersSeries = [];
  String? _newUsersSelection;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      // Load in parallel
      final now = DateTime.now();
      final since24h = now.subtract(const Duration(hours: 24)).toIso8601String();
      final since30d = now.subtract(const Duration(days: 30)).toIso8601String();

      final usersF = supabase.from('user_mapping').select('clerk_user_id, created_at');
      final linksF = supabase.from('saved_links').select('id, url, title, created_at, user_id, folder_id').order('created_at', ascending: false);
      final foldersF = supabase.from('folders').select('id, name, created_at, user_id');
      final recentLinksF = supabase.from('saved_links').select('id, url, title, created_at, user_id').order('created_at', ascending: false).limit(10);
      final activeLinksF = supabase.from('saved_links').select('user_id, created_at').gte('created_at', since24h);
      final activeFoldersF = supabase.from('folders').select('user_id, created_at').gte('created_at', since24h);
      final newUsersF = supabase.from('user_mapping').select('clerk_user_id, created_at').gte('created_at', since30d);

      final results = await Future.wait([
        usersF,
        linksF,
        foldersF,
        recentLinksF,
        activeLinksF,
        activeFoldersF,
        newUsersF,
      ]);

      final users = List<Map<String, dynamic>>.from(results[0] as List);
      final links = List<Map<String, dynamic>>.from(results[1] as List);
      final folders = List<Map<String, dynamic>>.from(results[2] as List);
      final recentLinks = List<Map<String, dynamic>>.from(results[3] as List);
      final activeLinks = List<Map<String, dynamic>>.from(results[4] as List);
      final activeFolders = List<Map<String, dynamic>>.from(results[5] as List);
      final newUsers = List<Map<String, dynamic>>.from(results[6] as List);

      // KPIs
      final totalUsers = users.length;
      final totalLinks = links.length;
      final totalFolders = folders.length;

      final activeSet = <String>{};
      for (final r in activeLinks) {
        final id = (r['user_id'] ?? '').toString();
        if (id.isNotEmpty) activeSet.add(id);
      }
      for (final r in activeFolders) {
        final id = (r['user_id'] ?? '').toString();
        if (id.isNotEmpty) activeSet.add(id);
      }
      final activeUsersToday = activeSet.length;

      // Top sources (by host)
      final hostCounts = <String, int>{};
      for (final l in links) {
        final h = _hostOf(l['url'])
            .replaceFirst('www.', '')
            .toLowerCase();
        if (h.isEmpty) continue;
        hostCounts[h] = (hostCounts[h] ?? 0) + 1;
      }
      final topSources = hostCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final topSourcesList = topSources.take(7).map((e) => {'label': e.key, 'value': e.value}).toList();

      // Popular folders: top 10 folders by number of saved links, aggregate the rest as "Other"
      final folderIdToName = <int, String>{};
      for (final f in folders) {
        final id = (f['id'] as int);
        folderIdToName[id] = (f['name'] ?? 'Untitled').toString();
      }
      final folderCounts = <int, int>{};
      for (final l in links) {
        final fid = l['folder_id'];
        if (fid is int) {
          folderCounts[fid] = (folderCounts[fid] ?? 0) + 1;
        }
      }
      final sortedFolders = folderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTen = sortedFolders.take(10).toList();
      final others = sortedFolders.skip(10).fold<int>(0, (sum, e) => sum + e.value);
      final popularFoldersList = <Map<String, dynamic>>[
        ...topTen.map((e) => {
          'label': folderIdToName[e.key] ?? 'Folder ${e.key}',
          'value': e.value,
        })
      ];
      if (others > 0) {
        popularFoldersList.add({'label': 'Other', 'value': others});
      }

      // Recent saves
      final recent = recentLinks;

      // New users last 30 days (daily counts)
      final byDay = <String, int>{};
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.year}-${_two(d.month)}-${_two(d.day)}';
        byDay[key] = 0;
      }
      for (final u in newUsers) {
        final dt = _parseCreatedAtFlexible(u['created_at']);
        if (dt == null) continue;
        final key = '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
        if (byDay.containsKey(key)) {
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
      }
      final sortedDays = byDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final newUsersSeries = sortedDays.map((e) => {'date': e.key, 'value': e.value}).toList();

      if (!mounted) return;
      setState(() {
        _totalUsers = totalUsers;
        _totalLinks = totalLinks;
        _totalFolders = totalFolders;
        _activeUsersToday = activeUsersToday;
        _recentSaves = recent;
        _topSources = topSourcesList;
        _popularFolders = popularFoldersList;
        _newUsersSeries = newUsersSeries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ClerkAuth.of(context).signOut();
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3E5F8A), Color(0xFF5F7DC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF74EBD5),
              Color(0xFF9FACE6),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _KpiRow(cards: [
                        _KpiCard(title: 'Total Users', value: _totalUsers.toString(), icon: Icons.people),
                        _KpiCard(title: 'Total Links Saved', value: _totalLinks.toString(), icon: Icons.link),
                        _KpiCard(title: 'Total Folders', value: _totalFolders.toString(), icon: Icons.folder),
                        _KpiCard(title: 'Active Users (24h)', value: _activeUsersToday.toString(), icon: Icons.insights),
                      ]),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Content Insights',
                        child: Column(
                          children: [
                            _PieChart(title: 'Most Popular Folders', items: _popularFolders),
                            const SizedBox(height: 12),
                            _BarChart(title: 'Top Saved Sources', items: _topSources),
                            const SizedBox(height: 12),
                            _RecentSavesList(items: _recentSaves),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'User Activity',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LineSeries(
                              title: 'New Users (30 days)',
                              series: _newUsersSeries,
                              onPointTap: (p) {
                                setState(() {
                                  _newUsersSelection = '${p['date']}: ${p['value']}';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('New users on ${p['date']}: ${p['value']}')),
                                );
                              },
                            ),
                            if (_newUsersSelection != null) ...[
                              const SizedBox(height: 8),
                              Text(_newUsersSelection!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List<_KpiCard> cards;
  const _KpiRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final cross = isWide ? 2 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((c) => SizedBox(
                    width: isWide ? (constraints.maxWidth - 12 * (cross - 1)) / 2 : constraints.maxWidth,
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: const Color(0xFF1F1F1F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items; // [{'label':..., 'value':...}]
  const _BarChart({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final max = (items.isEmpty) ? 0 : items.map((e) => (e['value'] as int)).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        ...items.map((e) {
          final v = (e['value'] as int);
          final ratio = max == 0 ? 0.0 : (v / max).clamp(0.0, 1.0);
          final label = (e['label'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9FACE6).withOpacity(0.30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5F7DC8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 56, child: Text('$v', textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _RecentSavesList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _RecentSavesList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Recent Saves', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        ...items.map((e) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: Text((e['title'] ?? e['url'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_hostOf(e['url'])),
          );
        }).toList(),
      ],
    );
  }
}

class _LineSeries extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> series; // [{'date': 'YYYY-MM-DD', 'value': int}]
  final ValueChanged<Map<String, dynamic>>? onPointTap;
  const _LineSeries({required this.title, required this.series, this.onPointTap});

  @override
  Widget build(BuildContext context) {
    final max = (series.isEmpty) ? 0 : series.map((e) => (e['value'] as int)).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: series.map((e) {
              final v = (e['value'] as int);
              final ratio = max == 0 ? 0.0 : (v / max).clamp(0.0, 1.0);
              return Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () => onPointTap?.call({'date': e['date'], 'value': v}),
                    child: Container(
                      height: 10 + 90 * ratio,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF74EBD5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items; // [{'user': id, 'value': count}]
  const _Leaderboard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        ...items.map((e) {
          final user = (e['user'] ?? '').toString();
          final short = user.length > 8 ? '${user.substring(0, 8)}…' : user;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
            title: Text('User: $short'),
            trailing: Text('${e['value']}', style: const TextStyle(fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ],
    );
  }
}

class _PieChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items; // [{'label':..., 'value':...}]
  const _PieChart({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, e) => sum + (e['value'] as int));
    final colors = <Color>[
      const Color(0xFF5F7DC8),
      const Color(0xFF74EBD5),
      const Color(0xFFF08787),
      const Color(0xFFFFC7A7),
      const Color(0xFFFEE2AD),
      const Color(0xFFF8FAB4),
      const Color(0xFF9FACE6),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _PiePainter(items: items, colors: colors),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(items.length, (i) {
                      final e = items[i];
                      final c = colors[i % colors.length];
                      final label = (e['label'] ?? '').toString();
                      final v = (e['value'] as int);
                      final pct = total == 0 ? 0 : ((v * 100) / total).round();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Expanded(child: Text('$label ($pct%)', maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final List<Color> colors;
  _PiePainter({required this.items, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<int>(0, (sum, e) => sum + (e['value'] as int));
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double padding = 8;
    final double dim = (size.shortestSide - padding * 2).clamp(0.0, 9999.0);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = dim / 2;

    double startRads = -3.14159 / 2; // start at top
    for (int i = 0; i < items.length; i++) {
      final v = (items[i]['value'] as int);
      final sweep = total == 0 ? 0.0 : (v / total) * 6.28318; // 2*pi
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRads, sweep, true, paint);
      startRads += sweep;
    }

    // Optional inner hole for a donut look
    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.items != items;
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _folders = [];
  final TextEditingController _textFieldController = TextEditingController();
  String? _sharedUrl;
  bool _isFromShare = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _sharedCaption;
  static const MethodChannel _shareChannel = MethodChannel('share_receiver');
  AppLifecycleState? _lastLifecycleState;
  int _foldersLoadAttempts = 0;
  
  Future<String?> _getMappedUserId() async {
    final clerkUser = ClerkAuth.of(context).user;
    if (clerkUser == null) return null;
    try {
      final result = await supabase
          .from('user_mapping')
          .select('supabase_user_id')
          .eq('clerk_user_id', clerkUser.id)
          .maybeSingle();
      final mapped = result != null ? result['supabase_user_id'] as String? : null;
      return mapped ?? clerkUser.id;
    } catch (_) {
      return clerkUser.id;
    }
  }

  Future<List<String>> _getUserIdCandidates() async {
    final clerkUser = ClerkAuth.of(context).user;
    if (clerkUser == null) return [];
    final mapped = await _getMappedUserId();
    final ids = <String>{};
    if (mapped != null) ids.add(mapped);
    ids.add(clerkUser.id); // include clerk id for backward compatibility
    return ids.toList();
  }

  @override
  void initState() {
    super.initState();
    _refreshFolders();
    _checkInitialSharedText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForNewSharedText();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialSharedText();
      _refreshFolders(); // Refresh folders when app resumes
    }
  }

  Future<void> _checkInitialSharedText() async {
    try {
      final String? value = await _shareChannel.invokeMethod<String>('getSharedText');
      if (value == null || value.trim().isEmpty) return;
      final parsed = _extractUrlAndCaption(value);
      if (parsed.$1 != null && mounted) {
        setState(() {
          _sharedUrl = parsed.$1;
          _sharedCaption = parsed.$2;
          _isFromShare = true;
        });
        await _shareChannel.invokeMethod('clearSharedText');
        _showSaveLinkDialog();
      }
    } catch (_) {}
  }

  void _listenForNewSharedText() {
    // For simplicity, rely on activity relaunch bringing us to foreground,
    // and re-check when page resumes via didChangeAppLifecycleState if needed.
  }

  Future<void> _refreshFolders() async {
    try {
      final mappedUserId = await _getMappedUserId();
      if (mappedUserId == null) {
        print('No Clerk user found');
        _scheduleFoldersRetry();
        return;
      }
      
      final idCandidates = await _getUserIdCandidates();
      print('Fetching folders for users: $idCandidates');
      final data = await supabase
          .from('folders')
          .select()
          .inFilter('user_id', idCandidates);
      print('Folders data: $data');
      
      if (mounted) {
        setState(() {
          final list = List<Map<String, dynamic>>.from(data);
          list.sort((a, b) {
            final at = _parseCreatedAtFlexible(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = _parseCreatedAtFlexible(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          _folders = list;
        });
      }

      if (_folders.isEmpty && _foldersLoadAttempts < 5) {
        // Retry briefly in case auth/session or network lag
        _scheduleFoldersRetry();
      } else {
        _foldersLoadAttempts = 0;
      }
    } catch (e) {
      print('Error fetching folders: $e');
      _scheduleFoldersRetry();
    }
  }

  void _scheduleFoldersRetry() {
    if (!mounted) return;
    if (_foldersLoadAttempts >= 5) return;
    _foldersLoadAttempts++;
    Future<void>.delayed(Duration(milliseconds: 400 * _foldersLoadAttempts), () {
      if (mounted) _refreshFolders();
    });
  }

  Future<void> _showAddFolderDialog() async {
    _textFieldController.clear();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a new folder'),
          content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "Folder Name")),
          actions: <Widget>[
            TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('ADD'),
              onPressed: () async {
                final folderName = _textFieldController.text.trim();
                final mappedUserId = await _getMappedUserId();

                if (folderName.isNotEmpty && mappedUserId != null) {
                  try {
                    print('Creating folder: $folderName for user: $mappedUserId');
                    await supabase
                        .from('folders')
                        .insert({'name': folderName, 'user_id': mappedUserId});
                    print('Folder created successfully');
                    Navigator.pop(context);
                    _refreshFolders();
                  } catch (e) {
                    print('Error adding folder: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddLinkDialog() async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController folderController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a new link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: "Enter URL",
                  labelText: "URL",
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  hintText: "Enter folder name",
                  labelText: "Folder Name",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('ADD'),
              onPressed: () async {
                final url = urlController.text.trim();
                final folderName = folderController.text.trim();
                final mappedUserId = await _getMappedUserId();

                if (url.isNotEmpty && folderName.isNotEmpty && mappedUserId != null) {
                  try {
                    // First, find or create the folder
                    var folderResult = await supabase
                        .from('folders')
                        .select('id')
                        .eq('name', folderName)
                        .eq('user_id', mappedUserId)
                        .maybeSingle();
                    
                    int folderId;
                    if (folderResult == null) {
                      // Create new folder
                      final newFolder = await supabase
                          .from('folders')
                          .insert({'name': folderName, 'user_id': mappedUserId})
                          .select()
                          .single();
                      folderId = newFolder['id'];
                    } else {
                      folderId = folderResult['id'];
                    }
                    
                    // Save the link
                    await _saveLinkToFolder(folderId, url);
                    Navigator.pop(context);
                    _refreshFolders();
                  } catch (e) {
                    print('Error adding link: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding link: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLinkToFolder(int folderId, String url, {String? overrideTitle}) async {
    try {
      final mappedUserId = await _getMappedUserId();
      if (mappedUserId == null) return;

      final formattedUrl = _ensureHttpScheme(url);
      final metadata = await _fetchUrlMetadata(formattedUrl);
      final resolvedTitle = (overrideTitle != null && overrideTitle.trim().isNotEmpty)
          ? overrideTitle.trim()
          : metadata['title'];

      print('Saving link: $formattedUrl with title: $resolvedTitle to folder: $folderId');
      await supabase.from('saved_links').insert({
        'user_id': mappedUserId,
        'url': formattedUrl,
        'title': resolvedTitle,
        'folder_id': folderId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Link saved!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print('Error saving link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving link')),
      );
    }
  }

  Future<void> _showDeleteFolderDialog(int folderId, String folderName) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
              'Are you sure you want to delete "$folderName"? This will also delete all links inside it.'),
          actions: [
            TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await supabase.from('folders').delete().eq('id', folderId);
                  Navigator.pop(context);
                  _refreshFolders();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Folder deleted!'),
                          duration: Duration(seconds: 2)),
                    );
                  }
                } catch (e) {
                  print('Error deleting folder: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSaveLinkDialog() async {
    if (_sharedUrl == null) return;

    // Refresh folders before showing dialog
    await _refreshFolders();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(" Save Link"),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sharedUrl!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              if ((_sharedCaption ?? '').trim().isNotEmpty) ...[
                const Text("Caption:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sharedCaption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text("Choose folder:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_folders.isEmpty)
                const Text("No folders found. Create one first.",
                    style: TextStyle(color: Colors.grey))
              else
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Color(0xFFF08787)),
                        title: Text(folder['name']),
                        onTap: () async {
                          await _saveLinkToFolder(folder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                          Navigator.pop(context);
                          _sharedUrl = null;
                          _sharedCaption = null;
                          _isFromShare = false;
                          _closeApp();
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.create_new_folder,
                    color: Color(0xFF8D6E63)),
                title: const Text("Create New Folder"),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFolderWhileSharingDialog();
                },
              ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () {
                Navigator.pop(context);
                _sharedUrl = null;
                _sharedCaption = null;
                _isFromShare = false;
                _closeApp();
              },
            ),
          ],
        );
      },
    );
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  Future<void> _showCreateFolderWhileSharingDialog() async {
    final TextEditingController folderNameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: folderNameController,
                decoration: const InputDecoration(
                  hintText: "Folder Name",
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Link to save: $_sharedUrl',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
                _showSaveLinkDialog(); // Return to previous dialog
              },
            ),
            TextButton(
              child: const Text('CREATE & SAVE'),
              onPressed: () async {
                final folderName = folderNameController.text.trim();
                final mappedUserId = await _getMappedUserId();
                if (folderName.isNotEmpty && mappedUserId != null) {
                  try {
                    final newFolder = await supabase
                        .from('folders')
                        .insert({'name': folderName, 'user_id': mappedUserId})
                        .select()
                        .single();

                    final newFolderId = newFolder['id'];

                    await _saveLinkToFolder(newFolderId, _sharedUrl!, overrideTitle: _sharedCaption);

                    Navigator.pop(context);
                    _sharedUrl = null;
                    _sharedCaption = null;
                    _isFromShare = false;
                    _closeApp();
                  } catch (e) {
                    print('Error creating folder and saving link: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _ensureHttpScheme(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  /// Extracts the first URL from the text and treats the rest as caption.
  /// Returns a Dart record (url, caption).
  (String?, String?) _extractUrlAndCaption(String text) {
    try {
      final RegExp urlRegex = RegExp(r'(https?:\/\/\S+)', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      if (match == null) return (null, null);
      final url = match.group(0);
      if (url == null) return (null, null);
      final caption = (text.replaceFirst(url, '').trim());
      return (url, caption.isEmpty ? null : caption);
    } catch (_) {
      return (null, null);
    }
  }

  Future<Map<String, String?>> _fetchUrlMetadata(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final document = html_parser.parse(response.body);
        final titleTag = document.querySelector('title');
        final ogTitle = document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        final metaTitle = document
            .querySelector('meta[name="title"]')
            ?.attributes['content'];
        final resolvedTitle =
        (ogTitle ?? metaTitle ?? titleTag?.text ?? '').trim();

        String? favicon = document
            .querySelector('link[rel~="shortcut"][rel~="icon"]')
            ?.attributes['href'] ??
            document.querySelector('link[rel~="icon"]')?.attributes['href'] ??
            '/favicon.ico';

        favicon = _resolveUrl(url, favicon);

        return {
          'title': resolvedTitle.isEmpty ? null : resolvedTitle,
          'favicon': favicon,
        };
      }
    } catch (_) {}
    final uri = Uri.tryParse(url);
    final hostTitle = uri?.host ?? url;
    final favicon = _resolveUrl(url, '/favicon.ico');
    return {'title': hostTitle, 'favicon': favicon};
  }

  String _resolveUrl(String baseUrl, String? href) {
    if (href == null || href.isEmpty) return baseUrl;
    try {
      final base = Uri.parse(baseUrl);
      final resolved = Uri.parse(href);
      final uri = resolved.hasScheme ? resolved : base.resolveUri(resolved);
      return uri.toString();
    } catch (_) {
      return href;
    }
  }

  Future<String?> _getClerkToken() async {
    try {
      final auth = ClerkAuth.of(context);
      final session = auth.session;
      if (session == null) return null;
      
      // Use the user ID directly since we can't access the token
      // We'll pass the user ID to a simpler approach
      return auth.user?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFromShare && _sharedUrl != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(),
      );
    }

    final filtered = _folders.where((f) {
      if (_query.isEmpty) return true;
      final name = (f['name'] ?? '').toString();
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Saved Folders'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ClerkAuth.of(context).signOut();
            },
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF08787),
              Color(0xFFFFC7A7),
              Color(0xFFFEE2AD),
              Color(0xFFF8FAB4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search folders...',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.75),
                    prefixIcon:
                    const Icon(Icons.search, color: Colors.black54),
                    hintStyle: const TextStyle(color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      const BorderSide(color: Color(0xFFF08787)),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF1F1F1F)),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final folder = filtered[index];
                    return OpenContainer(
                      openColor: Colors.white,
                      closedColor: Colors.white,
                      closedElevation: 0,
                      openElevation: 0,
                      transitionType: ContainerTransitionType.fadeThrough,
                      closedBuilder: (context, open) {
                        return _FolderCard(
                          name: folder['name'],
                          onDelete: () => _showDeleteFolderDialog(
                              folder['id'], folder['name']),
                          onOpen: open,
                        );
                      },
                      openBuilder: (context, _) => FolderViewPage(
                        folderId: folder['id'],
                        folderName: folder['name'],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddLinkDialog,
            label: const Text('Add Link'),
            icon: const Icon(Icons.link),
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _showAddFolderDialog,
            label: const Text('Add Folder'),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFFF08787),
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _FolderCard(
      {required this.name, required this.onDelete, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border:
          Border.all(color: const Color(0xFFF08787).withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF08787).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.folder_open,
                        color: Color(0xFFF08787)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                    const Icon(Icons.delete_outline, color: Colors.black45),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                'Tap to open',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_off, size: 64, color: Colors.black38),
            SizedBox(height: 16),
            Text('No folders yet',
                style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Create your first folder to start saving links',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class FolderViewPage extends StatefulWidget {
  final int folderId;
  final String folderName;

  const FolderViewPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends State<FolderViewPage> {
  List<Map<String, dynamic>> _links = [];
  Timer? _relativeTimeTicker;

  Future<String?> _getMappedUserId() async {
    final clerkUser = ClerkAuth.of(context).user;
    if (clerkUser == null) return null;
    try {
      final result = await supabase
          .from('user_mapping')
          .select('supabase_user_id')
          .eq('clerk_user_id', clerkUser.id)
          .maybeSingle();
      final mapped = result != null ? result['supabase_user_id'] as String? : null;
      return mapped ?? clerkUser.id;
    } catch (_) {
      return clerkUser.id;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLinks();
    _relativeTimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure we refresh when returning to this page
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final mappedUserId = await _getMappedUserId();
      if (mappedUserId == null) return;
      
      print('Loading links for folder: ${widget.folderId}');
      final data = await supabase
          .from('saved_links')
          .select()
          .eq('folder_id', widget.folderId)
          ;
      print('Links data: $data');
      if (mounted) {
        setState(() {
          final list = List<Map<String, dynamic>>.from(data);
          list.sort((a, b) {
            final aTime = _parseCreatedAtFlexible(a['created_at'] ?? a['saved_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = _parseCreatedAtFlexible(b['created_at'] ?? b['saved_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          _links = list;
        });
      }
    } catch (e) {
      print('Error loading links: $e');
    }
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    try {
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      final Uri uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('URL launch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening URL: Could not launch $url'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.folderName),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF08787),
              Color(0xFFFFC7A7),
              Color(0xFFFEE2AD),
              Color(0xFFF8FAB4),
            ],
          ),
        ),
        child: SafeArea(
          child: _links.isEmpty
              ? const _FolderEmptyState()
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: _links.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final link = _links[index];
              return InkWell(
                onTap: () async {
                  final url = link['url'];
                  if (url != null && url.isNotEmpty) {
                    await _launchUrl(url);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                        const Color(0xFFF08787).withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF08787),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                _LinkLeadingIcon(
                                    thumbnailUrl: link['thumbnail_url'],
                                    fallbackUrl: link['url']),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (link['title'] != null &&
                                            (link['title']
                                            as String)
                                                .trim()
                                                .isNotEmpty)
                                            ? link['title']
                                            : (link['url'] ??
                                            'No URL'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F1F1F)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (_hostOf(link['url'])
                                              .isNotEmpty)
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 120),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                      0xFFFFC7A7)
                                                      .withOpacity(
                                                      0.6),
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(999),
                                                ),
                                                child: Text(
                                                  _hostOf(link['url']),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(
                                                          0xFF5A4A42),
                                                      fontWeight:
                                                      FontWeight
                                                          .w600),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _formatSavedAt(
                                                  link['created_at'] ?? link['saved_at']),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.black54),
                                  onPressed: () async {
                                    try {
                                      await supabase
                                          .from('saved_links')
                                          .delete()
                                          .eq('id', link['id']);
                                      _loadLinks();
                                    } catch (e) {
                                      print(
                                          'Error deleting link: $e');
                                    }
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FolderEmptyState extends StatelessWidget {
  const _FolderEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.link_off, size: 64, color: Colors.black38),
            SizedBox(height: 16),
            Text('No links saved in this folder yet',
                style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Save a link from share or add manually',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _LinkLeadingIcon extends StatelessWidget {
  final String? thumbnailUrl;
  final String? fallbackUrl;

  const _LinkLeadingIcon(
      {required this.thumbnailUrl, required this.fallbackUrl});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl =
    (thumbnailUrl != null && (thumbnailUrl!.isNotEmpty))
        ? thumbnailUrl
        : null;
    if (imageUrl == null) {
      return const Icon(Icons.link);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.link),
      ),
    );
  }
}

String _formatSavedAt(dynamic createdAt) {
  try {
    if (createdAt == null) return '';
    final DateTime dt = _parseCreatedAtFlexible(createdAt) ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inSeconds < 60) return 'Saved just now';
    if (difference.inMinutes < 60) {
      return 'Saved ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) return 'Saved ${difference.inHours} h ago';
    if (difference.inDays < 7) return 'Saved ${difference.inDays} d ago';
    return 'Saved on ${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
  } catch (_) {
    return '';
  }
}

String _two(int n) => n < 10 ? '0$n' : '$n';

DateTime? _parseCreatedAtFlexible(dynamic createdAt) {
  try {
    if (createdAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(createdAt).toLocal();
    }
    final s = createdAt.toString();
    if (RegExp(r'^\d{13}$').hasMatch(s.trim())) {
      final ms = int.tryParse(s.trim());
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }

    String t = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    final frac = RegExp(r'(\.\d{1,})').firstMatch(t)?.group(1);
    if (frac != null && frac.length > 7) {
      t = t.replaceFirst(frac, frac.substring(0, 7));
    }
    final hasZone = RegExp(r'[zZ]|[\+\-]\d{2}:?\d{2}').hasMatch(t);
    if (!hasZone) {
      return DateTime.parse(t);
    } else {
      final dt = DateTime.parse(t);
      return dt.isUtc ? dt.toLocal() : dt;
    }
  } catch (_) {}
  return null;
}

String _hostOf(dynamic url) {
  try {
    final s = (url ?? '').toString();
    if (s.isEmpty) return '';
    final uri = Uri.parse(s.startsWith('http') ? s : 'https://$s');
    return uri.host.replaceFirst('www.', '');
  } catch (_) {
    return '';
  }
}