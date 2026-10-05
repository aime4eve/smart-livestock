import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2F6B3B);
  static const Color primaryDark = Color(0xFF244F2D);
  static const Color primarySoft = Color(0xFFE3F0E4);
  static const Color accent = Color(0xFF8BA95A);

  static const Color surface = Color(0xFFF8F6F0);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F0EA);
  static const Color border = Color(0xFFD7D2C6);

  static const Color textPrimary = Color(0xFF263126);
  static const Color textSecondary = Color(0xFF617061);

  static const Color success = Color(0xFF4C9A5F);
  static const Color successStrong = Color(0xFF2F7D44);
  static const Color successSoft = Color(0xFFE4F3E8);
  static const Color warning = Color(0xFFD28A2D);
  static const Color warningStrong = Color(0xFFB36A16);
  static const Color warningSoft = Color(0xFFFFF2DE);
  static const Color danger = Color(0xFFC2564B);
  static const Color dangerStrong = Color(0xFFB3352C);
  static const Color dangerSoft = Color(0xFFFBE8E6);
  static const Color info = Color(0xFF4A7F9D);
  static const Color infoStrong = Color(0xFF315F79);
  static const Color infoSoft = Color(0xFFE7F1F6);
  static const Color estrus = Color(0xFFC25689);
  static const Color aiAnomaly = Color(0xFF7C3AED);

  /// Fever / active illness-window chip accent (NIX-256, prototype --fever).
  static const Color fever = Color(0xFFD97B29);

  /// Drinking semantic color (NIX-256, prototype --drinking): big numbers,
  /// mini bars, chips and diamond markers.
  static const Color drinking = Color(0xFF3D7FA8);

  /// Drinking chip soft background (prototype --drinking-soft).
  static const Color drinkingSoft = Color(0xFFE2EDF4);

  /// Drinking valley marker on temperature curves (prototype
  /// --drinking-event, white stroke ring).
  static const Color drinkingEvent = Color(0xFF2C6486);

  /// Map / vegetation green (design token --map-green) — reused as the
  /// drinking peak reference-zone fill (NIX-256 prototype screen 2).
  static const Color mapGreen = Color(0xFFDCE8D5);

  /// LINE check type color (NIX-68, spec §9 --c-line).
  static const Color lineTeal = Color(0xFF0F766E);
  static const Color fenceApproach = Color(0xFF454F45);
  static const Color fenceBreach = Color(0xFF1A1F1A);

  static const Color overlayDark = Color(0xB3000000);
}
