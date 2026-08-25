import 'package:flutter/material.dart';

/// Semantic colors used by Lume surfaces and controls.
@immutable
class LumeColors extends ThemeExtension<LumeColors> {
  const LumeColors({
    required this.background,
    required this.surface,
    required this.brand,
    required this.brandSoft,
    required this.brandStrong,
    required this.calendar,
    required this.wellbeing,
    required this.finance,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.onBrand,
    required this.onSoft,
  });

  final Color background;
  final Color surface;
  final Color brand;
  final Color brandSoft;
  final Color brandStrong;
  final Color calendar;
  final Color wellbeing;
  final Color finance;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color error;
  final Color onBrand;
  final Color onSoft;

  static const light = LumeColors(
    background: Color(0xFFFAF8F7),
    surface: Color(0xFFFFFEFC),
    brand: Color(0xFFA44266),
    brandSoft: Color(0xFFF3E7EC),
    brandStrong: Color(0xFF6F2947),
    calendar: Color(0xFFEEEAF4),
    wellbeing: Color(0xFFE6EFE9),
    finance: Color(0xFFF4EBDD),
    text: Color(0xFF2E272A),
    textSecondary: Color(0xFF756B70),
    border: Color(0xFFE6DEE1),
    error: Color(0xFFB53D3B),
    onBrand: Color(0xFFFFFFFF),
    onSoft: Color(0xFF7A294B),
  );

  static const dark = LumeColors(
    background: Color(0xFF1B1819),
    surface: Color(0xFF262122),
    brand: Color(0xFFD783A2),
    brandSoft: Color(0xFF4B2C39),
    brandStrong: Color(0xFFF1B6CA),
    calendar: Color(0xFF37323E),
    wellbeing: Color(0xFF283B31),
    finance: Color(0xFF44372A),
    text: Color(0xFFF7EFF1),
    textSecondary: Color(0xFFC9B8BE),
    border: Color(0xFF403638),
    error: Color(0xFFFFB4AB),
    onBrand: Color(0xFF4B102A),
    onSoft: Color(0xFFFFC1D6),
  );

  @override
  LumeColors copyWith({
    Color? background,
    Color? surface,
    Color? brand,
    Color? brandSoft,
    Color? brandStrong,
    Color? calendar,
    Color? wellbeing,
    Color? finance,
    Color? text,
    Color? textSecondary,
    Color? border,
    Color? error,
    Color? onBrand,
    Color? onSoft,
  }) => LumeColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    brand: brand ?? this.brand,
    brandSoft: brandSoft ?? this.brandSoft,
    brandStrong: brandStrong ?? this.brandStrong,
    calendar: calendar ?? this.calendar,
    wellbeing: wellbeing ?? this.wellbeing,
    finance: finance ?? this.finance,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
    error: error ?? this.error,
    onBrand: onBrand ?? this.onBrand,
    onSoft: onSoft ?? this.onSoft,
  );

  @override
  LumeColors lerp(ThemeExtension<LumeColors>? other, double t) {
    if (other is! LumeColors) return this;
    return LumeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      calendar: Color.lerp(calendar, other.calendar, t)!,
      wellbeing: Color.lerp(wellbeing, other.wellbeing, t)!,
      finance: Color.lerp(finance, other.finance, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onSoft: Color.lerp(onSoft, other.onSoft, t)!,
    );
  }
}

class LumeSpacing {
  const LumeSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const contentHorizontal = 20.0;
  static const touchMinimum = 44.0;
}

class LumeRadii {
  const LumeRadii._();
  static const control = 10.0;
  static const card = 16.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

class LumeTheme {
  const LumeTheme._();

  static ThemeData light() => _theme(Brightness.light, LumeColors.light);

  static ThemeData dark() => _theme(Brightness.dark, LumeColors.dark);

  static ThemeData _theme(Brightness brightness, LumeColors colors) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: colors.onBrand,
      secondary: colors.brandStrong,
      onSecondary: colors.onBrand,
      error: colors.error,
      onError: brightness == Brightness.light ? Colors.white : Colors.black,
      surface: colors.surface,
      onSurface: colors.text,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
    );
    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: base.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

extension LumeThemeContext on BuildContext {
  LumeColors get lumeColors =>
      Theme.of(this).extension<LumeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? LumeColors.dark
          : LumeColors.light);
}
