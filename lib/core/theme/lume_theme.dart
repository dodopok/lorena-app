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
    background: Color(0xFFFFF8FB),
    surface: Color(0xFFFFFFFF),
    brand: Color(0xFFC94F7C),
    brandSoft: Color(0xFFF4C5D6),
    brandStrong: Color(0xFF7A294B),
    calendar: Color(0xFFDCCCF4),
    wellbeing: Color(0xFFC8E7D3),
    finance: Color(0xFFFFEBC8),
    text: Color(0xFF372A30),
    textSecondary: Color(0xFF6E5A63),
    border: Color(0xFFE9DDE2),
    error: Color(0xFFB3261E),
    onBrand: Color(0xFFFFFFFF),
    onSoft: Color(0xFF7A294B),
  );

  static const dark = LumeColors(
    background: Color(0xFF21181D),
    surface: Color(0xFF2D2228),
    brand: Color(0xFFE486A9),
    brandSoft: Color(0xFF633144),
    brandStrong: Color(0xFFFFC1D6),
    calendar: Color(0xFF44375A),
    wellbeing: Color(0xFF294737),
    finance: Color(0xFF554329),
    text: Color(0xFFFFF1F5),
    textSecondary: Color(0xFFD5BBC5),
    border: Color(0xFF493740),
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
  static const control = 12.0;
  static const card = 20.0;
  static const sheet = 24.0;
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
