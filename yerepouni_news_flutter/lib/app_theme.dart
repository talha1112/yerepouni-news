import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFF482B6F);
  static const lightAccent = Color(0xFFFFCAC5);
  static const bg = Color(0xFFEBE8ED);
  static const text = Color(0xFF211B25);
  static const muted = Color(0xFF77717C);
  static const cardMuted = Color(0xFF68616D);
  static const error = Color(0xFF9A3B52);
  static const divider = Color(0xFFEBE6EE);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    fontFamily: 'Georgia',
  );
}
