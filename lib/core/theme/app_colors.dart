import 'package:flutter/material.dart';

/// Design tokens for the Hostel Management app.
///
/// Brand foundation is ink navy (the hostel ledger/building) paired with a
/// brass-gold accent (the room key). Status colors read like a register:
/// present/approved green, pending amber, absent/rejected red.
class AppColors {
  AppColors._();

  // Brand
  static const Color navy = Color(0xFF0B2545);
  static const Color navyDeep = Color(0xFF061830);
  static const Color navyMid = Color(0xFF14396B);
  static const Color navyLight = Color(0xFF2D5A96);
  static const Color navySoft = Color(0xFFEAF0F7);
  static const Color navySoftAlt = Color(0xFFF5F8FC);

  static Color navyAlpha(double opacity) => navy.withValues(alpha: opacity);

  /// Brass/gold accent — the room key. Reserved for highlights: active
  /// states, key CTAs, the brand mark. Never used as a background fill.
  static const Color brass = Color(0xFFC9972E);
  static const Color brassDeep = Color(0xFFA47A1F);
  static const Color brassSoft = Color(0xFFFBF1DD);

  static Color brassAlpha(double opacity) => brass.withValues(alpha: opacity);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color paper = Color(0xFFF6F5F1);
  static const Color ink = navy;

  // Status — register semantics (present/approved, pending, absent/rejected)
  static const Color success = Color(0xFF2E7D5B);
  static const Color successSoft = Color(0xFFE4F2EB);
  static const Color pending = Color(0xFF9C6B00);
  static const Color pendingSoft = Color(0xFFFBF0DC);
  static const Color error = Color(0xFFB42318);
  static const Color errorSoft = Color(0xFFFBE7E5);

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
