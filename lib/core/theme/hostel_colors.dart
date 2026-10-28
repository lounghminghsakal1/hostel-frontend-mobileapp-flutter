import 'package:flutter/material.dart';

@immutable
class HostelColors extends ThemeExtension<HostelColors> {
  const HostelColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.brand,
    required this.brandRaised,
    required this.onBrand,
    required this.onBrandMuted,
    required this.primary,
    required this.onPrimary,
    required this.marigold,
    required this.onMarigold,
    required this.marigoldSoft,
    required this.marigoldInk,
    required this.success,
    required this.onSuccess,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.scrim,
  });

  final Color surface, surfaceRaised, surfaceSunken, line, lineStrong;
  final Color ink, inkMuted;
  final Color brand, brandRaised, onBrand, onBrandMuted;
  final Color primary, onPrimary;
  final Color marigold, onMarigold, marigoldSoft, marigoldInk;
  final Color success, onSuccess, successSoft;
  final Color danger, dangerSoft;
  final Color warning, warningSoft;
  final Color info, infoSoft;
  final Color scrim;

  Color get focus => info;

  static const light = HostelColors(
    surface: Color(0xFFF3F5F8),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE9EDF3),
    line: Color(0xFFDDE3EB),
    lineStrong: Color(0xFF7D8A9D),
    ink: Color(0xFF0E1A2B),
    inkMuted: Color(0xFF546072),
    brand: Color(0xFF0F2C52),
    brandRaised: Color(0xFF1E4373),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFC3D0E3),
    primary: Color(0xFF0F2C52),
    onPrimary: Color(0xFFFFFFFF),
    marigold: Color(0xFFE8A317),
    onMarigold: Color(0xFF1F1600),
    marigoldSoft: Color(0xFFFCEFCF),
    marigoldInk: Color(0xFF865800),
    success: Color(0xFF176B40),
    onSuccess: Color(0xFFFFFFFF),
    successSoft: Color(0xFFE1F3E8),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFCE8E6),
    warning: Color(0xFF9A4F00),
    warningSoft: Color(0xFFFDEBD6),
    info: Color(0xFF1E5AA8),
    infoSoft: Color(0xFFE3EDFA),
    scrim: Color(0x80080F1C),
  );

  static const dark = HostelColors(
    surface: Color(0xFF0B1220),
    surfaceRaised: Color(0xFF131D2E),
    surfaceSunken: Color(0xFF1B2740),
    line: Color(0xFF263550),
    lineStrong: Color(0xFF5C6F8C),
    ink: Color(0xFFE9EEF5),
    inkMuted: Color(0xFF9DAABD),
    brand: Color(0xFF16365F),
    brandRaised: Color(0xFF24497A),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFC3D0E3),
    primary: Color(0xFFBFD3F2),
    onPrimary: Color(0xFF0B1F3A),
    marigold: Color(0xFFF2B53A),
    onMarigold: Color(0xFF1F1600),
    marigoldSoft: Color(0xFF3A2A08),
    marigoldInk: Color(0xFFF5C35A),
    success: Color(0xFF5FD39A),
    onSuccess: Color(0xFF0B1220),
    successSoft: Color(0xFF0F2E20),
    danger: Color(0xFFFF8A80),
    dangerSoft: Color(0xFF3B1412),
    warning: Color(0xFFFFB86B),
    warningSoft: Color(0xFF3A2307),
    info: Color(0xFF8DB8F5),
    infoSoft: Color(0xFF12284A),
    scrim: Color(0x99000000),
  );

  @override
  HostelColors copyWith() => this;

  // Switches light and dark without animating between them.
  @override
  HostelColors lerp(ThemeExtension<HostelColors>? other, double t) =>
      other is HostelColors && t >= 0.5 ? other : this;
}
