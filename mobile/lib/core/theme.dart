import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Colors (same across both modes) ───
  static const Color primary = Color(0xFF10B981);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);

  // ─── Legacy compat aliases ───
  static const Color background = Color(0xFF0C0C14);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Spacing Tokens ───
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ─── Radius Tokens ───
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // ═══════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════
  static ThemeData get lightTheme {
    const bg = Color(0xFFF8FAFC);
    const surfaceColor = Color(0xFFFFFFFF);
    const onSurface = Color(0xFF0F172A);
    const onSurfaceVariant = Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surfaceColor,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        onError: Colors.white,
        outline: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFFF1F5F9),
      ),
      cardColor: surfaceColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: _buildTextTheme(Brightness.light),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.light),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════
  static ThemeData get darkTheme {
    const bg = Color(0xFF0C0C14);
    const surfaceColor = Color(0xFF1A1A2E);
    const onSurface = Color(0xFFF1F5F9);
    const onSurfaceVariant = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surfaceColor,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        onError: Colors.white,
        outline: Color(0xFF2D2D3F),
        surfaceContainerHighest: Color(0xFF1E1E30),
      ),
      cardColor: surfaceColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      dividerColor: const Color(0xFF2D2D3F),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.dark),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.3)
                : const Color(0xFF2D2D3F)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
      ),
    );
  }

  // ─── Text Theme ───
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final secondaryText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return TextTheme(
      displayLarge: TextStyle(
          color: primaryText, fontWeight: FontWeight.w900, fontSize: 32),
      displayMedium: TextStyle(
          color: primaryText, fontWeight: FontWeight.w800, fontSize: 28),
      displaySmall: TextStyle(
          color: primaryText, fontWeight: FontWeight.w700, fontSize: 24),
      headlineLarge: TextStyle(
          color: primaryText, fontWeight: FontWeight.w800, fontSize: 22),
      headlineMedium: TextStyle(
          color: primaryText, fontWeight: FontWeight.w700, fontSize: 20),
      headlineSmall: TextStyle(
          color: primaryText, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: TextStyle(
          color: primaryText, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(
          color: primaryText, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(
          color: primaryText, fontWeight: FontWeight.w500, fontSize: 16),
      bodyMedium: TextStyle(
          color: secondaryText, fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall: TextStyle(
          color: secondaryText, fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge: TextStyle(
          color: primaryText, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: TextStyle(
          color: secondaryText, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: TextStyle(
          color: secondaryText, fontWeight: FontWeight.w500, fontSize: 10),
    );
  }

  // ─── Input Decoration ───
  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF1F5F9);
    final borderColor =
        isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0);
    final hintColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      labelStyle: TextStyle(color: hintColor, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: danger),
      ),
    );
  }

  // ─── Elevated Button ───
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  // ─── Outlined Button ───
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final border = isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE2E8F0);

    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

/// Quick access to theme-adaptive colors from any widget
extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get onSurface => colors.onSurface;
  Color get onSurfaceVariant =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get surfaceColor => colors.surface;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get outline => colors.outline;
  Color get cardBg => Theme.of(this).cardColor;
}
