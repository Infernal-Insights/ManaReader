import 'package:flutter/material.dart';

/// Deep purple / indigo OLED-friendly dark theme.
class ManaTheme {
  ManaTheme._();

  static const Color _seed = Color(0xFF6B3FA0); // deep purple
  static const Color _onSurface = Color(0xFFE8E0F0);
  static const Color _background = Color(0xFF000000); // true black
  static const Color _surface = Color(0xFF0D0D0D);
  static const Color _surfaceVariant = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFF9B59B6);

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      background: _background,
      surface: _surface,
      surfaceVariant: _surfaceVariant,
      primary: _accent,
      onPrimary: Colors.white,
      secondary: const Color(0xFF5C6BC0), // indigo
      onSecondary: Colors.white,
      onSurface: _onSurface,
      onBackground: _onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _background,
      cardColor: _surfaceVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: _onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: _accent.withOpacity(0.24),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardTheme(
        color: _surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        selectedColor: _accent.withOpacity(0.32),
        labelStyle: const TextStyle(color: _onSurface, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accent),
      ),
      iconTheme: const IconThemeData(color: _onSurface),
      dividerTheme: DividerThemeData(
        color: _onSurface.withOpacity(0.12),
        thickness: 0.5,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: _accent),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _onSurface,
          fontSize: 57,
          fontWeight: FontWeight.w300,
        ),
        headlineMedium: TextStyle(
          color: _onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _onSurface, fontSize: 16),
        bodyMedium: TextStyle(color: _onSurface, fontSize: 14),
        labelLarge: TextStyle(
          color: _onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Color(0xFFB0A0C8),
          fontSize: 11,
        ),
      ),
    );
  }
}
