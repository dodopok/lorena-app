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
    background: Color(0xFFF9F8FA),
    surface: Color(0xFFFFFFFF),
    brand: Color(0xFFA44266),
    brandSoft: Color(0xFFF3E7EC),
    brandStrong: Color(0xFF6F2947),
    calendar: Color(0xFFE6EDF5),
    wellbeing: Color(0xFFE3F0EB),
    finance: Color(0xFFF2EBD7),
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
  static const control = 14.0;
  static const card = 22.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

class LumeTheme {
  const LumeTheme._();

  static ThemeData light() => _theme(Brightness.light, LumeColors.light);

  static ThemeData dark() => _theme(Brightness.dark, LumeColors.dark);

  static ThemeData _theme(Brightness brightness, LumeColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.brand,
          brightness: brightness,
          surface: colors.surface,
        ).copyWith(
          primary: colors.brand,
          onPrimary: colors.onBrand,
          primaryContainer: colors.brandSoft,
          onPrimaryContainer: colors.onSoft,
          secondary: colors.brandStrong,
          onSurface: colors.text,
          onSurfaceVariant: colors.textSecondary,
          outline: colors.border,
          error: colors.error,
        );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Nunito',
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
    );
    final text = base.textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LumeRadii.control),
      borderSide: BorderSide(color: colors.border),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LumeRadii.control),
    );
    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: text
          .copyWith(
            headlineMedium: text.headlineMedium?.copyWith(
              fontFamily: 'Lora',
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            headlineSmall: text.headlineSmall?.copyWith(
              fontFamily: 'Lora',
              letterSpacing: 0,
            ),
            displayMedium: text.displayMedium?.copyWith(
              fontFamily: 'Lora',
              letterSpacing: 0,
            ),
            titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            titleMedium: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
            bodySmall: text.bodySmall?.copyWith(height: 1.4),
          )
          .apply(bodyColor: colors.text, displayColor: colors.text),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: colors.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.brand, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LumeRadii.card),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: colors.border),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LumeRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.brandStrong,
        contentTextStyle: TextStyle(
          color: colors.surface,
          fontFamily: 'Nunito',
        ),
        actionTextColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
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
