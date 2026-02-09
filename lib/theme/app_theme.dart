import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Colors.deepOrange;
  static const Color secondary = Color(0xFFFF9A56);
  static const Color background = Color(0xFFFEF8FD);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE0E0E0);

  static const Color title = Color(0xFF5A5A5A);
  static const Color subtitle = Color(0xFF777777);
  static const Color labels = Color(0xFF9D9C9C);
  static const Color bodyS = Color(0xFF777777);
  static const Color textPrimary = Color(0xFF212121);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: title,
      ),
      displayMedium: TextStyle(
        color: title,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      displaySmall: TextStyle(fontSize: 16, color: subtitle),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5A5A5A),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: subtitle,
        letterSpacing: 0.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        color: Color(0xFF9E9E9E),
      ),
      bodySmall: TextStyle(
        color: bodyS,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      hintStyle: TextStyle(
        color: labels,
        fontSize: 14,
      ),
      prefixIconColor: labels,
      suffixIconColor: labels,
    ),
  );
}
