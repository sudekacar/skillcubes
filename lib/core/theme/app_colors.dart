/// Brand color tokens for SkillCubes dark & light themes.
library;

import 'package:flutter/material.dart';

/// Shared accent hues used across both themes.
abstract final class AppAccents {
  static const Color primaryBlue = Color(0xFF00A8E8);
  static const Color primaryBlueLight = Color(0xFF0077B6);
  static const Color amber = Color(0xFFFFB703);
  static const Color accentRed = Color(0xFFE63946);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color navy = Color(0xFF0A192F);
}

/// Dark-mode palette (default).
abstract final class DarkPalette {
  static const Color background = Color(0xFF0A192F);
  static const Color surface = Color(0xFF112240);
  static const Color border = Color(0xFF233554);
  static const Color surfaceLight = Color(0xFF1A3358);
  static const Color primary = AppAccents.primaryBlue;
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textMuted = Color(0xFF8892B0);
}

/// Light-mode palette.
abstract final class LightPalette {
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD8DEE9);
  static const Color surfaceLight = Color(0xFFE8EDF5);
  static const Color primary = AppAccents.primaryBlueLight;
  static const Color textPrimary = Color(0xFF0A192F);
  static const Color textMuted = Color(0xFF5C6B8A);
}

/// Theme-aware colors + static accents for game feedback.
///
/// Prefer [Theme.of] / [scheme] in widgets. Static fields mirror the dark
/// palette and accents so game logic can stay concise.
class AppColors {
  AppColors._();

  // --- Static accents / dark defaults (games, const contexts) ---
  static const Color background = DarkPalette.background;
  static const Color surface = DarkPalette.surface;
  static const Color surfaceLight = DarkPalette.surfaceLight;
  static const Color border = DarkPalette.border;
  static const Color primary = AppAccents.primaryBlue;
  static const Color amber = AppAccents.amber;
  static const Color accentRed = AppAccents.accentRed;
  static const Color mint = AppAccents.mint;
  static const Color textPrimary = DarkPalette.textPrimary;
  static const Color textMuted = DarkPalette.textMuted;
  static const Color success = AppAccents.mint;
  static const Color warning = AppAccents.amber;
  static const Color error = AppAccents.accentRed;

  // --- Context helpers (respect active theme) ---
  static ColorScheme scheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? DarkPalette.background : LightPalette.background;

  static Color card(BuildContext context) => scheme(context).surface;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? DarkPalette.border : LightPalette.border;

  static Color muted(BuildContext context) =>
      isDark(context) ? DarkPalette.textMuted : LightPalette.textMuted;
}
