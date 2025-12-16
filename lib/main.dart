// lib/main.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'theme/shapes.dart';
import 'services/metadata_service.dart';
import 'services/suggestion_service.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemNavigator;

// ⚙️ Create a global Supabase client for easy access
final supabase = Supabase.instance.client;

// 🔗 Shared Data Manager - Persists shared URLs across auth states
class SharedDataManager {
  static final SharedDataManager _instance = SharedDataManager._internal();
  factory SharedDataManager() => _instance;
  SharedDataManager._internal();

  String? pendingUrl;
  String? pendingCaption;
  bool hasPendingData = false;

  void setSharedData(String url, String? caption) {
    pendingUrl = url;
    pendingCaption = caption;
    hasPendingData = true;
  }

  (String?, String?) consumeSharedData() {
    final url = pendingUrl;
    final caption = pendingCaption;
    pendingUrl = null;
    pendingCaption = null;
    hasPendingData = false;
    return (url, caption);
  }

  void clearSharedData() {
    pendingUrl = null;
    pendingCaption = null;
    hasPendingData = false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://odmfqhaosvvscbgcghie.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kbWZxaGFvc3Z2c2NiZ2NnaGllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNDI3MTIsImV4cCI6MjA3NTYxODcxMn0.vSVWiruqXCGNkUieO-j1noWE4K8KzTUOLEfSAPP-sUk',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _shareChannel = MethodChannel('share_receiver');
  final _sharedDataManager = SharedDataManager();

  @override
  void initState() {
    super.initState();
    _setupShareHandling();
  }

  void _setupShareHandling() {
    // Set up MethodChannel listener for push-based sharing
    _shareChannel.setMethodCallHandler(_handleMethodCall);
    
    // Check for initial shared text (cold start)
    _checkInitialSharedText();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSharedTextReceived') {
      final String? text = call.arguments as String?;
      if (text != null) {
        _processSharedText(text);
      }
    }
  }

  Future<void> _checkInitialSharedText() async {
    try {
      final String? value = await _shareChannel.invokeMethod<String>('getSharedText');
      if (value != null && value.trim().isNotEmpty) {
        _processSharedText(value);
      }
    } catch (e) {
      print('Error checking shared text: $e');
    }
  }

  void _processSharedText(String value) {
    final parsed = _extractUrlAndCaption(value);
    final urlToUse = parsed.$1 ?? value;
    final captionToUse = parsed.$2;
    
    // Store in SharedDataManager for later use
    _sharedDataManager.setSharedData(urlToUse, captionToUse);
    print('LinkSaver: Shared data stored: $urlToUse');
  }

  (String?, String?) _extractUrlAndCaption(String text) {
    try {
      final RegExp urlRegex = RegExp(
        r'((https?:\/\/)|(www\.))[^\s]+',
        caseSensitive: false,
      );
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

  @override
  Widget build(BuildContext context) {
    final lightScheme = buildColorScheme(Brightness.light);
    final lightTextTheme = AppTypography.textTheme(Brightness.light);

    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: 'pk_test_YnVzeS1yb2Jpbi01NS5jbGVyay5hY2NvdW50cy5kZXYk',
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Link Saver',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
          textTheme: lightTextTheme,
          scaffoldBackgroundColor: lightScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: lightScheme.onSurface,
          ),
          cardTheme: CardThemeData(
            color: lightScheme.surface,
            elevation: 0,
            shape: AppShapes.cardShape,
            margin: const EdgeInsets.all(0),
          ),
          dialogTheme: DialogThemeData(
            shape: AppShapes.dialogShape,
            backgroundColor: lightScheme.surface,
            surfaceTintColor: lightScheme.surface,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightScheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
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
        // TEMPORARY: Revert to simple return until we find the correct loading property
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
    // Ensure mapping is created even on slower networks/devices
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final user = ClerkAuth.of(context).user;
        if (user == null) break;
        final result = await supabase
            .from('user_mapping')
            .upsert({
              'clerk_user_id': user.id,
              'supabase_user_id': user.id,
            })
            .select()
            .maybeSingle();
        if (result != null) break;
      } catch (e) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
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
    // Delay showing auth UI to allow for auto-login/session restoration
    // Increased to 7s to observe the 5-6s loading time reported by user
    Future.delayed(const Duration(milliseconds: 7000), () {
      if (mounted) {
        setState(() => _showAuth = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showAuth) {
      return const _SplashScreen();
    }

    final sharedDataManager = SharedDataManager();
    final hasPendingShare = sharedDataManager.hasPendingData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Pending share banner
              if (hasPendingShare) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Color(0xFF6E8EF5), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Link ready to save!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sharedDataManager.pendingUrl ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              const Text('Link Saver', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              if (hasPendingShare) ...[
                                const Text(
                                  '👆 Sign in to save your link',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6E8EF5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const ClerkAuthentication(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: const SafeArea(
        child: Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
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
  List<Map<String, dynamic>> _allUsersData = [];
  String? _newUsersSelection;
  String _userActivityRange = 'Last 7 Days';

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
      final since1y = now.subtract(const Duration(days: 365)).toIso8601String();
      final newUsersF = supabase.from('user_mapping').select('clerk_user_id, created_at').gte('created_at', since1y);

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

      // Store all user data for dynamic range filtering
      final allUsers = List<Map<String, dynamic>>.from(newUsers);
      
      // New users last 30 days (daily counts) - default
      final byDay = <String, int>{};
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.year}-${_two(d.month)}-${_two(d.day)}';
        byDay[key] = 0;
      }
      for (final u in allUsers) {
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
        _allUsersData = allUsers;
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
        toolbarHeight: 64,
        titleSpacing: 24,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          padding: const EdgeInsets.only(top: 16),
        ),
        shape: const Border(
          bottom: BorderSide(color: Colors.white24, width: 0.4),
        ),
      ),
      body: Container(
        color: AppColors.surface,
        child: SafeArea(
          child: _loading
              ? const _DashboardSkeleton()
              : RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    children: [
                      _KpiGrid(
                        cards: [
                          _KpiCardData(
                            title: 'Total Users',
                            value: _totalUsers.toString(),
                            icon: Icons.people,
                          ),
                          _KpiCardData(
                            title: 'Total Links Saved',
                            value: _totalLinks.toString(),
                            icon: Icons.link,
                          ),
                          _KpiCardData(
                            title: 'Total Folders',
                            value: _totalFolders.toString(),
                            icon: Icons.folder,
                          ),
                          _KpiCardData(
                            title: 'Active Users (24h)',
                            value: _activeUsersToday.toString(),
                            icon: Icons.insights,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Content Insights',
                        subtitle: 'How your community is saving content',
                        child: _ContentInsightsSection(
                          popularFolders: _popularFolders,
                          topSources: _topSources,
                          recentSaves: _recentSaves,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'User Activity',
                        subtitle: 'New user registrations over time',
                        child: _UserActivitySection(
                          allUsersData: _allUsersData,
                          selectedRange: _userActivityRange,
                          onRangeChanged: (range) {
                            setState(() {
                              _userActivityRange = range;
                              _newUsersSelection = null;
                            });
                          },
                          onPointTap: (p) {
                            setState(() {
                              _newUsersSelection = '${p['date']}: ${p['value']} users';
                            });
                          },
                          selectedLabel: _newUsersSelection,
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

class _KpiCardData {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiCardData> cards;
  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 720;
        final columnCount = isTablet ? 4 : 2;
        final spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  height: 100, // Fixed height for consistency
                  child: _KpiCard(card: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiCardData card;
  const _KpiCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 0,
      borderRadius: AppShapes.cardRadius,
      child: InkWell(
        borderRadius: AppShapes.cardRadius,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.iconSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(card.icon, color: AppColors.textPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        card.value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 20,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget skeleton({double height = 80, double radius = 16}) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Row(
          children: [
            Expanded(child: skeleton(height: 84)),
            const SizedBox(width: 12),
            Expanded(child: skeleton(height: 84)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: skeleton(height: 84)),
            const SizedBox(width: 12),
            Expanded(child: skeleton(height: 84)),
          ],
        ),
        const SizedBox(height: 20),
        skeleton(height: 320, radius: 20),
        const SizedBox(height: 20),
        skeleton(height: 220, radius: 20),
      ],
    );
  }
}

class _ContentInsightsSection extends StatelessWidget {
  final List<Map<String, dynamic>> popularFolders;
  final List<Map<String, dynamic>> topSources;
  final List<Map<String, dynamic>> recentSaves;

  const _ContentInsightsSection({
    required this.popularFolders,
    required this.topSources,
    required this.recentSaves,
  });

  @override
  Widget build(BuildContext context) {
    final total = popularFolders.fold<int>(0, (sum, e) => sum + ((e['value'] ?? 0) as int));
    final leading = popularFolders.isEmpty
        ? null
        : popularFolders.reduce((a, b) => ((a['value'] ?? 0) as int) >= ((b['value'] ?? 0) as int) ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PieChart(items: popularFolders),
        if (leading != null) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final leadingValue = (leading['value'] ?? 0) as int;
              final percentage = total == 0 ? 0.0 : (leadingValue * 100.0) / total.toDouble();
              final pctLabel = percentage.toStringAsFixed(percentage >= 10 ? 0 : 1);
              return Text(
                '${leading['label']} holds $pctLabel% of saves',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        _TopSourcesChart(items: topSources),
        const SizedBox(height: 24),
        _RecentSavesList(items: recentSaves),
      ],
    );
  }
}

class _TopSourcesChart extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TopSourcesChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyMetricState(message: 'No top sources yet.');
    }

    final max = items.map((e) => (e['value'] as int)).fold<int>(0, (prev, val) => val > prev ? val : prev);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Saved Sources',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final value = (item['value'] as int);
          final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          children: [
                            Container(
                              height: 14,
                              color: const Color(0xFFEAF1F8),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(begin: 0.0, end: ratio),
                                  builder: (context, animated, child) {
                                    return Container(
                                      height: 14,
                                      width: constraints.maxWidth * animated,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (item['label'] ?? '').toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RecentSavesList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _RecentSavesList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyMetricState(message: 'No recent saves to show.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Saves',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = (item['title'] ?? item['url'] ?? '').toString();
              final host = _hostOf(item['url']);
              final createdAt = _formatSavedAt(item['created_at'] ?? item['saved_at']);
              return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: AppColors.iconSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.link, size: 20, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (host.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.iconSurface,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        host,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ),
                                  ),
                                if (createdAt.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      createdAt,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, size: 20, color: AppColors.textMuted),
                        tooltip: 'More actions',
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 48,
              color: AppColors.divider,
            ),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class _UserActivitySection extends StatelessWidget {
  final List<Map<String, dynamic>> allUsersData;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final ValueChanged<Map<String, dynamic>> onPointTap;
  final String? selectedLabel;

  const _UserActivitySection({
    required this.allUsersData,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onPointTap,
    this.selectedLabel,
  });

  List<Map<String, dynamic>> _calculateSeriesForRange(String range) {
    final now = DateTime.now();
    
    int days;
    String periodType;
    if (range == 'Last 7 Days') {
      days = 7;
      periodType = 'day';
    } else if (range == 'Last Month') {
      days = 30;
      periodType = 'day';
    } else { // Last Year
      days = 12;
      periodType = 'month';
    }

    if (periodType == 'day') {
      final byDay = <String, int>{};
      for (int i = 0; i < days; i++) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.year}-${_two(d.month)}-${_two(d.day)}';
        byDay[key] = 0;
      }
      for (final u in allUsersData) {
        final dt = _parseCreatedAtFlexible(u['created_at']);
        if (dt == null) continue;
        final key = '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
        if (byDay.containsKey(key)) {
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
      }
      final sortedDays = byDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return sortedDays.map((e) => {'date': e.key, 'value': e.value}).toList();
    } else {
      final byMonth = <String, int>{};
      for (int i = 0; i < days; i++) {
        final d = now.subtract(Duration(days: i * 30));
        final key = '${d.year}-${_two(d.month)}';
        byMonth[key] = 0;
      }
      for (final u in allUsersData) {
        final dt = _parseCreatedAtFlexible(u['created_at']);
        if (dt == null) continue;
        final key = '${dt.year}-${_two(dt.month)}';
        if (byMonth.containsKey(key)) {
          byMonth[key] = (byMonth[key] ?? 0) + 1;
        }
      }
      final sortedMonths = byMonth.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return sortedMonths.map((e) => {'date': e.key, 'value': e.value}).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = _calculateSeriesForRange(selectedRange);
    final totalNewUsers = series.fold<int>(0, (sum, e) => sum + ((e['value'] ?? 0) as int));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Users',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$totalNewUsers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedRange,
                underline: const SizedBox(),
                isDense: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                items: const [
                  DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                  DropdownMenuItem(value: 'Last Year', child: Text('Last Year')),
                ],
                onChanged: (value) {
                  if (value != null) onRangeChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _UserActivityChart(series: series, range: selectedRange, onPointTap: onPointTap),
        if (selectedLabel != null && selectedLabel!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.iconSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  selectedLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UserActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> series;
  final String range;
  final ValueChanged<Map<String, dynamic>> onPointTap;

  const _UserActivityChart({
    required this.series,
    required this.range,
    required this.onPointTap,
  });

  String _formatDateLabel(String date, String range) {
    try {
      if (range == 'Last Year') {
        final parts = date.split('-');
        if (parts.length >= 2) {
          final month = int.tryParse(parts[1]) ?? 1;
          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return monthNames[month - 1];
        }
        return date;
      } else {
        // For day-based ranges, parse the date string properly
        final parts = date.split('-');
        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final month = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          
          // Format as "DD/MM" or "DD Mon" for better readability
          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          if (range == 'Last 7 Days') {
            return '$day ${monthNames[month - 1]}';
          } else {
            return '$day/$month';
          }
        }
        return date;
      }
    } catch (_) {
      return date;
    }
  }

  List<int> _calculateYAxisLabels(int max) {
    if (max == 0) return [0, 1, 2, 3, 4];
    
    // Smart scaling for better visualization
    int step;
    if (max <= 5) {
      step = 1;
    } else if (max <= 20) {
      step = ((max / 4).ceil()).clamp(1, 5);
    } else if (max <= 100) {
      step = ((max / 4).ceil() / 5).ceil() * 5; // Round to nearest 5
    } else if (max <= 1000) {
      step = ((max / 4).ceil() / 10).ceil() * 10; // Round to nearest 10
    } else {
      step = ((max / 4).ceil() / 100).ceil() * 100; // Round to nearest 100
    }
    
    final labels = <int>[];
    for (int i = 0; i <= 4; i++) {
      labels.add(i * step);
    }
    // Ensure the max value is included or close to it
    if (labels.last < max) {
      labels[4] = ((max / step).ceil() * step);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyMetricState(message: 'No user activity recorded yet.');
    }
    final max = series.map((e) => (e['value'] as int)).fold<int>(0, (prev, val) => val > prev ? val : prev);
    // Calculate Y-axis labels first to get the proper max
    final yAxisLabels = _calculateYAxisLabels(max);
    // Use the max from Y-axis labels for consistent scaling
    final maxValue = yAxisLabels.isNotEmpty ? yAxisLabels.last : (max == 0 ? 1 : max);
    const chartHeight = 220.0;

    return SizedBox(
      height: chartHeight + 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-axis labels
          SizedBox(
            width: 35,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: yAxisLabels.reversed
                  .map((v) => SizedBox(
                        height: chartHeight / 4,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '$v',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          // Chart area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, t, _) {
                          return CustomPaint(
                            painter: _LineChartPainter(
                              series: series,
                              maxValue: maxValue,
                              progress: t,
                            ),
                            size: Size(constraints.maxWidth, chartHeight),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // X-axis labels - show more labels for better readability
                SizedBox(
                  height: 32,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate how many labels we can fit
                      final labelCount = series.length <= 7 ? series.length : 
                                       (series.length <= 14 ? (series.length / 2).ceil() : 5);
                      final step = series.length > 1 ? (series.length - 1) / (labelCount - 1) : 1;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(labelCount, (index) {
                          final dataIndex = (index * step).round().clamp(0, series.length - 1);
                          final dateLabel = _formatDateLabel(series[dataIndex]['date'], range);
                          return Flexible(
                            child: Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 9,
                                  ),
                              textAlign: index == 0 ? TextAlign.left : 
                                        index == labelCount - 1 ? TextAlign.right : TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> series;
  final int maxValue;
  final double progress; // 0..1 line draw animation

  _LineChartPainter({
    required this.series,
    required this.maxValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || maxValue <= 0) return;
    
    final chartHeight = size.height;
    final chartWidth = size.width;
    final paddingTop = 25.0; // Increased for value labels
    final paddingBottom = 5.0;
    final paddingLeft = 2.0; // Small left padding for alignment
    final paddingRight = 2.0;
    final usableHeight = chartHeight - paddingTop - paddingBottom;
    final usableWidth = chartWidth - paddingLeft - paddingRight;
    
    // Calculate step for X-axis - ensure proper spacing
    final stepX = series.length > 1 
        ? usableWidth / (series.length - 1) 
        : usableWidth / 2;

    // Calculate actual max from Y-axis labels (for proper alignment)
    final yAxisMax = maxValue;
    final yAxisStep = yAxisMax / 4;
    
    // Draw gridlines (horizontal lines) - aligned with Y-axis labels
    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (usableHeight * (i / 4));
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(chartWidth - paddingRight, y),
        gridPaint,
      );
    }

    // Calculate data points with proper Y-axis alignment
    final points = <Offset>[];
    for (int i = 0; i < series.length; i++) {
      final value = (series[i]['value'] as int);
      final x = paddingLeft + (stepX * i);
      // Use yAxisMax for scaling to ensure alignment with gridlines
      final ratio = yAxisMax > 0 ? (value / yAxisMax).clamp(0.0, 1.0) : 0.0;
      // Calculate Y from bottom, ensuring alignment with gridlines
      final y = paddingTop + usableHeight - (ratio * usableHeight);
      points.add(Offset(x, y));
    }

    // Draw line path
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      // Animate line drawing
      final metrics = path.computeMetrics();
      final animatedPath = Path();
      if (metrics.isNotEmpty) {
        double totalLength = 0;
        for (final metric in metrics) {
          totalLength += metric.length;
        }
        double remaining = totalLength * progress;
        for (final metric in metrics) {
          final extract = metric.extractPath(0, remaining.clamp(0.0, metric.length));
          animatedPath.addPath(extract, Offset.zero);
          remaining -= metric.length;
          if (remaining <= 0) break;
        }
      }

      // Draw red line
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFEF4444);
      canvas.drawPath(animatedPath, linePaint);
    }

    // Draw square points and value labels
    final squarePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    
    final textStyle = const TextStyle(
      color: Color(0xFF111827),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    );
    
    final visiblePoints = (series.length * progress).ceil();
    for (int i = 0; i < visiblePoints && i < points.length; i++) {
      final point = points[i];
      final value = (series[i]['value'] as int);
      
      // Draw red square (6x6px with rounded corners)
      final squareSize = 6.0;
      final squareRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: point,
          width: squareSize,
          height: squareSize,
        ),
        const Radius.circular(1),
      );
      canvas.drawRRect(squareRect, squarePaint);
      
      // Draw value label above the point
      final textPainter = TextPainter(
        text: TextSpan(text: '$value', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final labelY = point.dy - textPainter.height - 8;
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          labelY.clamp(0.0, chartHeight - textPainter.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.maxValue != maxValue || oldDelegate.progress != progress;
  }
}

class _PieChart extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _PieChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyMetricState(message: 'No folder distribution data yet.');
    }

    final colors = [
      const Color(0xFF5B6FE6),
      const Color(0xFF0EA5E9),
      const Color(0xFF2DD4BF),
      const Color(0xFFFF8F6B),
      const Color(0xFF8B5CF6),
      const Color(0xFFFFC857),
    ];
    final total = items.fold<int>(0, (sum, e) => sum + ((e['value'] ?? 0) as int));
    final semanticsSummary = items
        .map((e) {
          final label = (e['label'] ?? 'Unnamed').toString();
          final value = (e['value'] ?? 0) as int;
          final pct = total == 0 ? 0 : ((value * 100) / total).round();
          return '$label $pct percent';
        })
        .join(', ');

    return Semantics(
      label: 'Popular folder distribution',
      value: semanticsSummary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 520;
          final legend = _buildLegend(items, colors, total, context);
          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 220,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CustomPaint(
                              painter: _PiePainter(items: items, colors: colors, animationValue: value),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(width: 200, child: legend),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return CustomPaint(
                            painter: _PiePainter(items: items, colors: colors, animationValue: value),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    legend,
                  ],
                );
        },
      ),
    );
  }

  Widget _buildLegend(
    List<Map<String, dynamic>> items,
    List<Color> colors,
    int total,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(items.length, (index) {
          final entry = items[index];
          final label = (entry['label'] ?? '').toString();
          final value = (entry['value'] ?? 0) as int;
          final pct = total == 0 ? 0.0 : (value * 100.0) / total.toDouble();
          final pctLabel = pct.toStringAsFixed(pct >= 10 ? 0 : 1);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$label · $pctLabel%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final List<Color> colors;
  final double animationValue;

  _PiePainter({
    required this.items,
    required this.colors,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<int>(0, (sum, e) => sum + ((e['value'] ?? 0) as int));
    final dim = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = dim / 2.2;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < items.length; i++) {
      final value = (items[i]['value'] ?? 0) as int;
      final sweep = total == 0 ? 0.0 : (value / total) * 2 * math.pi * animationValue;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.animationValue != animationValue;
  }
}

class _EmptyMetricState extends StatelessWidget {
  final String message;
  const _EmptyMetricState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

String _condensedDate(dynamic dateString) {
  if (dateString == null) return '';
  final String input = dateString.toString();
  if (input.length >= 10) {
    return '${input.substring(5, 7)}/${input.substring(8, 10)}';
  }
  return input;
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
  final _sharedDataManager = SharedDataManager();
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
    _checkForPendingShare(); // Check SharedDataManager for pending shares after auth
    WidgetsBinding.instance.addObserver(this);
  }

  // Check SharedDataManager for pending shares (after successful login)
  void _checkForPendingShare() {
    if (_sharedDataManager.hasPendingData) {
      final (url, caption) = _sharedDataManager.consumeSharedData();
      if (url != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _sharedUrl = url;
            _sharedCaption = caption;
            _isFromShare = true;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _sharedUrl != null) {
              _showSaveLinkDialog();
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFolders(); // Refresh folders when app resumes
    }
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

    // Ensure we're on the HomePage before showing dialog
    if (!mounted) return;

    // Refresh folders before showing dialog (with timeout)
    try {
      await _refreshFolders().timeout(const Duration(seconds: 3), onTimeout: () {
        // Continue even if timeout
      });
    } catch (e) {
      // Log error but proceed to show dialog
      print('Error refreshing folders for share dialog: $e');
    }

    // Double-check mounted state before showing dialog
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
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
              
              const Text("Suggestions:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<FolderSuggestion>>(
                future: () async {
                  if (_sharedUrl == null) return <FolderSuggestion>[];

                  // 1. Fetch Metadata
                  final metadataFuture = MetadataService.fetchMetadata(_ensureHttpScheme(_sharedUrl!));

                  // 2. Fetch History (All saved links in user's folders)
                  final historyFuture = () async {
                    try {
                      if (_folders.isEmpty) return <Map<String, dynamic>>[];
                      final folderIds = _folders.map((f) => f['id']).toList();
                      final response = await supabase
                          .from('saved_links')
                          .select('title, folder_id, url')
                          .filter('folder_id', 'in', folderIds);
                      return List<Map<String, dynamic>>.from(response);
                    } catch (e) {
                      print('Error fetching history for suggestions: $e');
                      return <Map<String, dynamic>>[];
                    }
                  }();

                  final results = await Future.wait([metadataFuture, historyFuture]);
                  final metadata = results[0] as LinkMetadata;
                  final history = results[1] as List<Map<String, dynamic>>;
                  
                  return SuggestionService.suggestFolders(metadata, _folders, history);
                }(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const SizedBox.shrink(); 
                   }
                   final suggestions = snapshot.data!;
                   return Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: suggestions.map((suggestion) {
                       return ActionChip(
                          avatar: Icon(
                            suggestion.isExisting ? Icons.folder : Icons.create_new_folder,
                            size: 16,
                            color: suggestion.isExisting ? const Color(0xFF6EC1FF) : const Color(0xFF8D6E63)
                          ),
                          label: Text(suggestion.name),
                          tooltip: suggestion.reason,
                          backgroundColor: Colors.grey[50],
                          onPressed: () async {
                              if (suggestion.isExisting) {
                                // Find existing ID
                                final folder = _folders.firstWhere((f) => f['name'] == suggestion.name);
                                await _saveLinkToFolder(folder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                              } else {
                                // Create new folder
                                final mappedUserId = await _getMappedUserId();
                                if (mappedUserId != null) {
                                  try {
                                     final newFolder = await supabase
                                      .from('folders')
                                      .insert({'name': suggestion.name, 'user_id': mappedUserId})
                                      .select()
                                      .single();
                                     await _saveLinkToFolder(newFolder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                                  } catch (e) {
                                     print('Error auto-creating suggestion: $e');
                                     return;
                                  }
                                }
                              }
                              // Close flow
                              Navigator.pop(context);
                              _sharedUrl = null;
                              _sharedCaption = null;
                              _isFromShare = false;
                              try { const MethodChannel('share_receiver').invokeMethod('clearSharedText'); } catch (_) {}
                              _closeApp();
                          },
                       );
                     }).toList(),
                   );
                },
              ),
              const SizedBox(height: 16),

              const Text("Choose folder:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_folders.isEmpty) ...[
                const Text("No folders found yet.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text("Tip: Create a folder to save your link into.", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ] else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Color(0xFF6EC1FF)),
                          title: Text(folder['name']),
                          onTap: () async {
                            await _saveLinkToFolder(folder['id'], _sharedUrl!, overrideTitle: _sharedCaption);
                            Navigator.pop(context);
                            _sharedUrl = null;
                            _sharedCaption = null;
                            _isFromShare = false;
                            // Clear native shared text after user interaction
                            try {
                              const MethodChannel('share_receiver').invokeMethod('clearSharedText');
                            } catch (_) {}
                            _closeApp();
                          },
                        );
                      }),
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
              onPressed: () async {
                Navigator.pop(context);
                _sharedUrl = null;
                _sharedCaption = null;
                _isFromShare = false;
                // Clear native shared text after user interaction
                try {
                  const MethodChannel('share_receiver').invokeMethod('clearSharedText');
                } catch (_) {}
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
                    // Clear shared text only after user interaction
                    try {
                      const MethodChannel('share_receiver').invokeMethod('clearSharedText');
                    } catch (_) {}
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
    if (url.startsWith('www.')) return 'https://$url';
    return 'https://$url';
  }

  /// Extracts the first URL from the text and treats the rest as caption.
  /// Returns a Dart record (url, caption).
  (String?, String?) _extractUrlAndCaption(String text) {
    try {
      // Regex to find URLs, including those starting with www.
      final RegExp urlRegex = RegExp(
        r'((https?:\/\/)|(www\.))[^\s]+',
        caseSensitive: false,
      );
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
        backgroundColor: Colors.black.withOpacity(0.5),
        body: const Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
        ),
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
        title: const Text('My Saved Folders', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      body: Container(
        color: AppColors.surface,
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
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    hintStyle: const TextStyle(color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: buildColorScheme(Brightness.light).primary),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
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
                        childAspectRatio: 1.0,
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
            backgroundColor: const Color(0xFF6E8EF5),
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
          color: AppColors.card,
          boxShadow: AppColors.softShadow,
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
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.folder_open, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black38),
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
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
        title: Text(widget.folderName, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      body: Container(
        color: AppColors.surface,
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
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
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary),
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
                                                  color: AppColors.primaryBlue.withOpacity(0.20),
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
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w600),
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
                                      color: Colors.black45),
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