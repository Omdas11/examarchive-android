import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/papers_provider.dart';
import 'services/appwrite_service.dart';
import 'theme/app_themes.dart';
import 'screens/home_screen.dart';
import 'screens/syllabus_screen.dart';
import 'screens/account_screen.dart';
import 'screens/ai_tools_screen.dart';
import 'screens/store_screen.dart';

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
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    SyllabusScreen(),
    AiToolsScreen(),
    StoreScreen(),
    AccountScreen(),
  ];

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
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Papers',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Syllabus',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
