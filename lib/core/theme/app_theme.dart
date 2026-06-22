import 'package:flutter/material.dart';

/// StreamVault design tokens — extracted from the HTML design mockups.
///
/// Every color, radius, and text style used across the app lives here
/// so we have a single source of truth.
abstract class AppColors {
  // ── Backgrounds ──
  static const Color bg = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF141418);
  static const Color surfaceElevated = Color(0xFF1C1C22);
  static const Color surfaceHover = Color(0xFF222228);

  // ── Accent ──
  static const Color accent = Color(0xFFE5383B);
  static const Color accentGlow = Color(0x40E5383B); // 25%
  static const Color accentLight = Color(0xFFFF7B7E);

  // ── Status ──
  static const Color liveGreen = Color(0xFF34D399);
  static const Color liveGreenGlow = Color(0x4D34D399); // 30%
  static const Color purple = Color(0xFFA78BFA);

  // ── Text ──
  static const Color textPrimary = Color(0xFFF0F0F2);
  static const Color textSecondary = Color(0xFF7A7A86);
  static const Color textTertiary = Color(0xFF4A4A54);

  // ── Border ──
  static const Color border = Color(0x0FFFFFFF); // 6%
  static const Color borderHover = Color(0x1AFFFFFF); // 10%
}

abstract class AppRadii {
  static const double card = 16;
  static const double cardInner = 12;
  static const double searchBar = 14;
  static const double tab = 9;
  static const double tabContainer = 12;
  static const double logo = 12;
  static const double pill = 20;
  static const double button = 10;
}

abstract class AppTextStyles {
  static const String _fontFamily = 'Inter';

  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle channelName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle epgTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.accentLight,
  );

  static const TextStyle epgTime = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle tabText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle searchHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static const TextStyle seeAll = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
}

/// Builds the app-wide MaterialTheme from our design tokens.
ThemeData buildAppTheme() {
  return ThemeData(
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.liveGreen,
      onSurface: AppColors.textPrimary,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
