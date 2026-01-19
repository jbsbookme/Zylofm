import 'package:flutter/material.dart';

extension ZyloColorX on Color {
  Color withAlphaF(double opacity) {
    final clamped = opacity < 0
        ? 0.0
        : (opacity > 1 ? 1.0 : opacity);
    return withValues(alpha: clamped);
  }
}

class ZyloColors {
  ZyloColors._();

  static const Color black = Color(0xFF000000);
  static const Color nearBlack = Color(0xFF0A0A0F);
  static const Color panel = Color(0xFF101018);
  static const Color panel2 = Color(0xFF141424);

  // Accents (neón)
  static const Color zyloYellow = Color(0xFFFFD400);
  static const Color electricBlue = Color(0xFF00A3FF);
  static const Color neonGreen = Color(0xFF00FF85);

  static const Color liveRed = Color(0xFFFF2D55);
}

class ZyloTheme {
  ZyloTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: null,
    );

    // Start from a dark seed, then force surfaces to true-black.
    final seeded = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: ZyloColors.electricBlue,
    );

    final scheme = seeded.copyWith(
      primary: ZyloColors.zyloYellow,
      secondary: ZyloColors.electricBlue,
      tertiary: ZyloColors.neonGreen,
      surface: ZyloColors.black,
      onSurface: Colors.white,
      surfaceTint: Colors.transparent,
      error: const Color(0xFFFF4D4D),
      onError: Colors.white,
      outline: const Color(0xFF2A2A36),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: ZyloColors.black,
      dividerColor: const Color(0xFF1F1F2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        bodyMedium: const TextStyle(
          height: 1.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: ZyloColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1C1C28), width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 3,
        activeTrackColor: ZyloColors.zyloYellow,
        inactiveTrackColor: const Color(0xFF2A2A36),
        thumbColor: ZyloColors.zyloYellow,
        overlayColor: ZyloColors.zyloYellow.withAlphaF(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1A1A24),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ZyloColors.zyloYellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class ZyloFx {
  ZyloFx._();

  static List<BoxShadow> glow(Color color, {double blur = 18, double spread = 0}) {
    return [
      BoxShadow(
        color: color.withAlphaF(0.22),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static LinearGradient neonSheen({double opacity = 1}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ZyloColors.electricBlue.withAlphaF(0.18 * opacity),
        ZyloColors.neonGreen.withAlphaF(0.10 * opacity),
        ZyloColors.zyloYellow.withAlphaF(0.14 * opacity),
      ],
    );
  }
}
