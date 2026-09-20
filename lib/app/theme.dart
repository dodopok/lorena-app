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
  static ThemeData light() => core_theme.LumeTheme.light();
  static ThemeData dark() => core_theme.LumeTheme.dark();
}
