import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand seed color — a rich indigo-teal blend
  static const _seedColor = Color(0xFF5C6BC0); // Indigo 400

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(seedColor: _seedColor, brightness: .light);
    return _base(cs).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F6FB),
      cardColor: Colors.white,
    );
  }

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(seedColor: _seedColor, brightness: .dark);
    return _base(cs).copyWith(
      scaffoldBackgroundColor: const Color(0xFF12131A),
      cardColor: const Color(0xFF1E1F2B),
    );
  }

  static ThemeData _base(ColorScheme cs) {
    final textTheme = _textTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: GoogleFonts.interTextTheme(_textTheme()),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: .w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(120),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withAlpha(160)),
        contentPadding: const .symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: .circular(28),
          borderSide: .none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: .circular(28),
          borderSide: .none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: .circular(28),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const .symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: .circular(28)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: .w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: .circular(5)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return Colors.transparent;
        }),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontWeight: .w800, letterSpacing: -1.5),
      headlineLarge: TextStyle(fontWeight: .w700, letterSpacing: -1),
      headlineMedium: TextStyle(fontWeight: .w700, letterSpacing: -0.5),
      titleLarge: TextStyle(fontWeight: .w700, letterSpacing: -0.5),
      titleMedium: TextStyle(fontWeight: .w600),
      titleSmall: TextStyle(fontWeight: .w600),
      bodyLarge: TextStyle(fontWeight: .w400, height: 1.5),
      bodyMedium: TextStyle(fontWeight: .w400, height: 1.5),
      labelLarge: TextStyle(fontWeight: .w600, letterSpacing: 0.3),
    );
  }
}
