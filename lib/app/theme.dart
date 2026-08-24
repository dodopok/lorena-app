import 'package:flutter/material.dart';

abstract final class LumeColors {
  static const background = Color(0xFFFFF8FB);
  static const surface = Color(0xFFFFFFFF);
  static const brand = Color(0xFFC94F7C);
  static const brandSoft = Color(0xFFF4C5D6);
  static const brandStrong = Color(0xFF7A294B);
  static const calendar = Color(0xFFDCCCF4);
  static const wellbeing = Color(0xFFC8E7D3);
  static const finance = Color(0xFFFFEBC8);
  static const text = Color(0xFF372A30);
  static const textSecondary = Color(0xFF6E5A63);
  static const error = Color(0xFFB3261E);
}

abstract final class LumeTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: LumeColors.brandSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: LumeColors.brandSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LumeColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LumeColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: LumeColors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LumeColors.surface,
        indicatorColor: LumeColors.brandSoft,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: LumeColors.brandStrong, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = light();
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF21191E),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF2C2228),
        onSurface: const Color(0xFFFFECF3),
        primary: const Color(0xFFF58DAF),
        onPrimary: const Color(0xFF4D132B),
        primaryContainer: const Color(0xFF6A2843),
        onPrimaryContainer: const Color(0xFFFFD9E4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF21191E),
        foregroundColor: Color(0xFFFFECF3),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF2C2228),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF6A2843)),
        ),
      ),
    );
  }
}
