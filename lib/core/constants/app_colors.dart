import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accent = Color(0xFFFF9800);
  static const Color expense = Color(0xFFE53935);
  static const Color income = Color(0xFF43A047);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFF7043),
    'transport': Color(0xFF42A5F5),
    'shopping': Color(0xFFAB47BC),
    'entertainment': Color(0xFFFFCA28),
    'medical': Color(0xFFEF5350),
    'education': Color(0xFF66BB6A),
    'other': Color(0xFF78909C),
  };

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFFFF7043),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFFCA28),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF78909C),
  ];
}
