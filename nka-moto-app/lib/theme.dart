import 'package:flutter/material.dart';

class NkaColors {
  static const primary = Color(0xFF0B6E4F);
  static const green = Color(0xFF1B9E5A);
  static const red = Color(0xFFC1121F);
  static const amber = Color(0xFFD4A017);
  static const bg = Color(0xFFF7F5F0);
  static const ink = Color(0xFF1A1A1A);
  static const navy = Color(0xFF12263A);
}

ThemeData nkaTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: NkaColors.primary, surface: NkaColors.bg),
    scaffoldBackgroundColor: NkaColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: NkaColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NkaColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
