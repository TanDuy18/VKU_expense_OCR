import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B4332);
  static const bg = Color(0xFFFBFAF6);
  static const ink = Color(0xFF1C2B24);
  static const muted = Color(0xFF5C6B63);
  static const line = Color(0xFFE8E5DC);
  static const bar = Color(0xFF2D6A4F);
  static const sub = Color(0xFFB7E4C7);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'BeVietnamPro',
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bg,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.sub,
      ),
    );
