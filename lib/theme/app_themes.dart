import 'package:flutter/material.dart';

/// Named app themes.
enum AppThemeName {
  system('System default'),
  light('Light'),
  dark('Dark'),
  amoled('AMOLED black'),
  emerald('Emerald signature');

  const AppThemeName(this.label);
  final String label;
}

class AppThemes {
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF059669);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.light),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
    );
  }

  static ThemeData amoled() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: const Color(0xFF0A0A0A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        brightness: Brightness.dark,
      ).copyWith(surface: Colors.black, surfaceContainerHighest: const Color(0xFF111111)),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1F1F1F)),
        ),
      ),
    );
  }

  static ThemeData emeraldTheme() {
    final base = ThemeData.light(useMaterial3: true);
    const surface = Color(0xFFF0FDF7);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(seedColor: emeraldDark, brightness: Brightness.light),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: Color(0xFF064E3B),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFA7F3D0)),
        ),
      ),
    );
  }

  static ThemeData resolve(AppThemeName name, Brightness platformBrightness) {
    switch (name) {
      case AppThemeName.system:
        return platformBrightness == Brightness.dark ? dark() : light();
      case AppThemeName.light:
        return light();
      case AppThemeName.dark:
        return dark();
      case AppThemeName.amoled:
        return amoled();
      case AppThemeName.emerald:
        return emeraldTheme();
    }
  }
}
