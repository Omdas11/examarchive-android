import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/papers_provider.dart';
import 'services/appwrite_service.dart';
import 'services/analytics_service.dart';
import 'theme/app_themes.dart';
import 'screens/browse_screen.dart';
import 'screens/syllabus_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/login_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppwriteService().init();
  runApp(const ExamArchiveApp());
}

class ExamArchiveApp extends StatelessWidget {
  const ExamArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PapersProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final platformBrightness = MediaQuery.platformBrightnessOf(context);
          return MaterialApp(
            title: 'ExamArchive',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.resolve(themeProvider.theme, platformBrightness),
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Browse sits in the middle of the dock, like the website's main action.
  int _index = 1;

  static const _screens = [
    SyllabusScreen(),
    BrowseScreen(),
    ProfileScreen(),
  ];

  static const _screenNames = ['Syllabus', 'Browse', 'Profile'];
  static const _screenPaths = ['syllabus', 'browse', 'profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAskConsent();
      _trackCurrent();
    });
  }

  Future<void> _maybeAskConsent() async {
    if (await AnalyticsService().hasConsentDecision) return;
    if (!mounted) return;
    final accepted = await AnalyticsService.showConsentDialog(context);
    await AnalyticsService().setConsented(accepted);
    if (accepted && mounted) _trackCurrent();
  }

  void _trackCurrent() {
    AnalyticsService().trackScreen(
      _screenNames[_index],
      _screenPaths[_index],
    );
  }

  void _select(int i) {
    setState(() => _index = i);
    _trackCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Papers, syllabus and downloads all come straight from Appwrite,
    // which grants read access to logged-in users — so the app needs
    // an ExamArchive account (the same one as the website).
    if (!auth.isLoggedIn) {
      return const LoginGateScreen();
    }
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Syllabus',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
