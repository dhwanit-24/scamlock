import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

/// Color tokens.
///
/// `signalRed` is the app's brand color and is reserved specifically for
/// locking actions, danger, and critical/destructive states — never used
/// as a generic decorative accent. The `block*` colors are soft pastel
/// surfaces repurposed here as functional status/highlight backgrounds
/// (not marketing decoration).
class AppColors {
  AppColors._();

  static const ink = Color(0xFF000000);
  static const canvas = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFE6E6E6);
  static const hairlineSoft = Color(0xFFF1F1F1);
  static const surfaceSoft = Color(0xFFF7F7F5);

  /// Brand signal red — reserved for locking actions, danger, and
  /// critical/destructive states only.
  static const signalRed = Color(0xFFB42318);

  static const blockMint = Color(0xFFC8E6CD); // active / approved
  static const blockLime = Color(0xFFDCEEB1); // neutral highlight
  static const blockLilac = Color(0xFFC5B0F4); // admin / secondary highlight
  static const blockCream = Color(0xFFF4ECD6); // neutral / info
  static const blockBlush = Color(0xFFF2C6C2); // pending / attention (soft red family)
  static const blockCoral = Color(0xFFF3C9B6); // warm accent
  static const blockNavy = Color(0xFF1F1D3D); // admin dark accent

  static const success = Color(0xFF1EA64A);
}

/// Spacing scale, in logical pixels.
class AppSpacing {
  AppSpacing._();

  static const hair = 1.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Corner radius scale, in logical pixels.
class AppRadius {
  AppRadius._();

  static const xs = 2.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const pill = 50.0;
  static const full = 9999.0;
}

/// Typography scale.
///
/// Uses the bundled variable fonts' full weight axis via [FontVariation]
/// to hit exact in-between weights, rather than being limited to the
/// standard 100-900-in-steps-of-100 [FontWeight] enum.
class AppTypography {
  AppTypography._();

  static const _sans = 'Manrope';
  static const _mono = 'JetBrainsMono';

  static const TextStyle headline = TextStyle(
    fontFamily: _sans,
    fontSize: 28,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 560)],
  );

  static const TextStyle subhead = TextStyle(
    fontFamily: _sans,
    fontSize: 19,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 380)],
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1.4,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    height: 1.4,
    letterSpacing: -0.1,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 380)],
  );

  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    height: 1.45,
    letterSpacing: -0.1,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 360)],
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.45,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 380)],
  );

  static const TextStyle link = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    height: 1.4,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 520)],
  );

  static const TextStyle button = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.3,
    color: AppColors.canvas,
    fontVariations: [FontVariation('wght', 560)],
  );

  /// Uppercase, mono, positive letter-spacing — used for short taxonomy
  /// labels like status tags and G/A-number field labels, never body copy.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 1.3,
    letterSpacing: 0.6,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 500)],
  );

  /// Uppercase, mono — used for short metadata like timestamps.
  static const TextStyle caption = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.ink,
    fontVariations: [FontVariation('wght', 420)],
  );
}

/// Builds the app's global [ThemeData].
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.signalRed,
      brightness: Brightness.light,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.canvas,
        disabledBackgroundColor: AppColors.hairline,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AppTypography.link,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairlineSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      labelStyle: AppTypography.body,
    ),
  );
}