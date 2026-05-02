import 'package:flutter/material.dart';

class NexthriaTheme {
  const NexthriaTheme._();

  static const Color bg = Color(0xFF0B0F19);
  static const Color card = Color(0xFF161B28);
  static const Color input = Color(0xFF1F2937);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color blue = Color(0xFF3B82F6);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color emerald = Color(0xFF34D399);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFFB7185);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color outline = Color(0x1AFFFFFF);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[cyan, blue, indigo],
  );

  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      primary: cyan,
      secondary: blue,
      surface: card,
      error: coral,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.05,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary, height: 1.45),
        bodySmall: TextStyle(color: textTertiary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return blue.withValues(alpha: 0.22);
            }
            return input.withValues(alpha: 0.8);
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(textPrimary),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: outline),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: textPrimary,
          backgroundColor: blue,
          disabledBackgroundColor: input,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      dividerColor: outline,
    );
  }

  static ThemeData lightTheme() => darkTheme();
}
