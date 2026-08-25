import 'package:flutter/material.dart';

import '../core/theme/lume_theme.dart' as core_theme;

abstract final class LumeColors {
  static const background = Color(0xFFFAF8F7);
  static const surface = Color(0xFFFFFEFC);
  static const brand = Color(0xFFA44266);
  static const brandSoft = Color(0xFFF3E7EC);
  static const brandStrong = Color(0xFF6F2947);
  static const calendar = Color(0xFFEEEAF4);
  static const wellbeing = Color(0xFFE6EFE9);
  static const finance = Color(0xFFF4EBDD);
  static const text = Color(0xFF2E272A);
  static const textSecondary = Color(0xFF756B70);
  static const error = Color(0xFFB53D3B);
}

abstract final class LumeTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: LumeColors.brand,
          brightness: Brightness.light,
          surface: LumeColors.surface,
        ).copyWith(
          primary: LumeColors.brand,
          onPrimary: Colors.white,
          primaryContainer: LumeColors.brandSoft,
          onPrimaryContainer: LumeColors.brandStrong,
          surface: LumeColors.surface,
          onSurface: LumeColors.text,
          error: LumeColors.error,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LumeColors.background,
      fontFamily: 'Avenir Next',
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LumeColors.background,
        foregroundColor: LumeColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LumeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: LumeColors.brandSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: LumeColors.brandSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LumeColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LumeColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: LumeColors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LumeColors.surface,
        indicatorColor: LumeColors.brandSoft,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: LumeColors.brandStrong, fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[core_theme.LumeColors.light],
    );
  }

  static ThemeData dark() {
    final base = light();
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1B1819),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF262122),
        onSurface: const Color(0xFFF7EFF1),
        primary: const Color(0xFFD783A2),
        onPrimary: const Color(0xFF3D1627),
        primaryContainer: const Color(0xFF4B2C39),
        onPrimaryContainer: const Color(0xFFF1B6CA),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B1819),
        foregroundColor: Color(0xFFF7EFF1),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF262122),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF4B2C39)),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[core_theme.LumeColors.dark],
    );
  }
}
