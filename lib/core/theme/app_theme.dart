import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds Material 3 [ThemeData] for SkillCubes dark & light modes.
///
/// Typography uses Poppins via Google Fonts with sub-pixel rendering hints
/// to keep text razor-sharp on both mobile and web (CanvasKit).
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: DarkPalette.background,
        surface: DarkPalette.surface,
        border: DarkPalette.border,
        primary: DarkPalette.primary,
        onPrimary: DarkPalette.background,
        textPrimary: DarkPalette.textPrimary,
        textMuted: DarkPalette.textMuted,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: LightPalette.background,
        surface: LightPalette.surface,
        border: LightPalette.border,
        primary: LightPalette.primary,
        onPrimary: Colors.white,
        textPrimary: LightPalette.textPrimary,
        textMuted: LightPalette.textMuted,
      );

  /// Merges Poppins into every text style of [base], ensuring consistent
  /// fontWeight, height, and sub-pixel rendering across all platforms.
  static TextTheme _sharpenTextTheme(TextTheme base, Color body, Color display) {
    TextStyle applyPoppins(TextStyle? s) {
      return GoogleFonts.poppins(textStyle: s).copyWith(
        fontFeatures: const [FontFeature.proportionalFigures()],
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );
    }

    return TextTheme(
      displayLarge: applyPoppins(base.displayLarge?.copyWith(color: display)),
      displayMedium: applyPoppins(base.displayMedium?.copyWith(color: display)),
      displaySmall: applyPoppins(base.displaySmall?.copyWith(color: display)),
      headlineLarge: applyPoppins(base.headlineLarge?.copyWith(color: display)),
      headlineMedium: applyPoppins(base.headlineMedium?.copyWith(color: display)),
      headlineSmall: applyPoppins(base.headlineSmall?.copyWith(color: display)),
      titleLarge: applyPoppins(base.titleLarge?.copyWith(color: body)),
      titleMedium: applyPoppins(base.titleMedium?.copyWith(color: body, fontWeight: FontWeight.w600)),
      titleSmall: applyPoppins(base.titleSmall?.copyWith(color: body, fontWeight: FontWeight.w600)),
      bodyLarge: applyPoppins(base.bodyLarge?.copyWith(color: body)),
      bodyMedium: applyPoppins(base.bodyMedium?.copyWith(color: body)),
      bodySmall: applyPoppins(base.bodySmall?.copyWith(color: body)),
      labelLarge: applyPoppins(base.labelLarge?.copyWith(color: body, fontWeight: FontWeight.w600)),
      labelMedium: applyPoppins(base.labelMedium?.copyWith(color: body, fontWeight: FontWeight.w500)),
      labelSmall: applyPoppins(base.labelSmall?.copyWith(color: body, fontWeight: FontWeight.w500)),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color primary,
    required Color onPrimary,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = _sharpenTextTheme(base.textTheme, textPrimary, textPrimary);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: AppAccents.amber,
        onSecondary: AppAccents.navy,
        tertiary: AppAccents.mint,
        onTertiary: AppAccents.navy,
        error: AppAccents.accentRed,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textMuted,
        outline: border,
        outlineVariant: border.withValues(alpha: 0.7),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.poppins(
          color: textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? DarkPalette.surfaceLight
            : LightPalette.surfaceLight,
        contentTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: border,
    );
  }
}
