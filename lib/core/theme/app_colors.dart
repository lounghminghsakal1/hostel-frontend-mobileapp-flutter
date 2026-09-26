import 'package:flutter/material.dart';

/// The app uses exactly two base colors: white and a dark navy blue.
/// Every other value here is a tint/shade of those two so the palette
/// stays consistent across the app.
class AppColors {
  AppColors._();

  // Base colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color navy = Color(0xFF0B2545);

  // Shades of navy (darker)
  static const Color navyDeep = Color(0xFF061830);
  static const Color navyMid = Color(0xFF14396B);

  // Tints of navy (lighter, still navy)
  static const Color navyLight = Color(0xFF2D5A96);
  static const Color navySoft = Color(0xFFEAF0F7);
  static const Color navySoftAlt = Color(0xFFF5F8FC);

  // Opacity helpers for borders/dividers/disabled states
  static Color navyAlpha(double opacity) => navy.withValues(alpha: opacity);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyMid, navy, navyDeep],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDeep, navy, navyMid],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navySoftAlt, white],
  );
}
