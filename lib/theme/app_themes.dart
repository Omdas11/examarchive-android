import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Named app themes — all use the website's Plus Jakarta Sans + emerald brand,
/// with Material 3 Expressive (dynamicSchemeVariant.expressive) for rounder,
/// more colourful components.
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
  static const ink = Color(0xFF0F172A);

  static TextTheme _jakarta(TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base);

  /// Material 3 Expressive colour scheme from the brand seed.
  static ColorScheme _expressiveScheme(Brightness brightness, Color seed) =>
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      );

  /// Expressive shapes: bigger radii everywhere.
  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  static ThemeData _withFont(ThemeData t) =>
      t.copyWith(textTheme: _jakarta(t.textTheme));

  static ThemeData _expressiveBase({
    required Brightness brightness,
    required Color seed,
    Color? scaffoldBackground,
    Color? cardColor,
    Color? surface,
    Color? surfaceContainerHighest,
    Color? appBarBackground,
    Color? appBarForeground,
    Color? cardBorder,
  }) {
    final scheme = _expressiveScheme(brightness, seed);
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return _withFont(base.copyWith(
      colorScheme: scheme.copyWith(
        surface: surface ?? scheme.surface,
        surfaceContainerHighest:
            surfaceContainerHighest ?? scheme.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: _cardShape.copyWith(
          side: cardBorder != null
              ? BorderSide(color: cardBorder)
              : BorderSide.none,
        ),
      ),
      // Expressive navigation bar: tall, pill indicator.
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
      // Expressive buttons and inputs: fully rounded where it fits.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ));
  }

  static ThemeData light() => _expressiveBase(
        brightness: Brightness.light,
        seed: emerald,
        cardBorder: Colors.grey.shade200,
      );

  static ThemeData dark() => _expressiveBase(
        brightness: Brightness.dark,
        seed: emerald,
        cardBorder: Colors.grey.shade800,
      );

  static ThemeData amoled() => _expressiveBase(
        brightness: Brightness.dark,
        seed: emerald,
        scaffoldBackground: Colors.black,
        cardColor: const Color(0xFF0A0A0A),
        surface: Colors.black,
        surfaceContainerHighest: const Color(0xFF111111),
        appBarBackground: Colors.black,
        cardBorder: const Color(0xFF1F1F1F),
      );

  static ThemeData emeraldTheme() {
    const surface = Color(0xFFF0FDF7);
    return _expressiveBase(
      brightness: Brightness.light,
      seed: emeraldDark,
      scaffoldBackground: surface,
      cardColor: Colors.white,
      appBarBackground: surface,
      appBarForeground: const Color(0xFF064E3B),
      cardBorder: const Color(0xFFA7F3D0),
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
