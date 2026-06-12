import 'package:flutter/material.dart';

/// All color constants used across the TRIBAL app.
/// Primary brand palette: deep maroon gradient inspired by the TRIBAL identity.
class AppColors {
  AppColors._();

  // --- Primary Gradient Colors ---
  static const Color gradientStart = Color(0xFF5E0F0F);
  static const Color gradientMid = Color(0xFF7A1313);
  static const Color gradientEnd = Color(0xFF8E1D14);

  // --- Solid Brand Colors ---
  static const Color primary = Color(0xFF6A1A12);
  static const Color primaryDark = Color(0xFF5E0F0F);
  static const Color primaryLight = Color(0xFF8E1D14);

  // --- Background ---
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);

  // --- Text ---
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFBDBDBD);

  // --- Input Fields ---
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFill = Color(0xFFFAFAFA);

  // --- Divider / Subtle ---
  static const Color divider = Color(0xFFEEEEEE);

  // --- Tab Switcher ---
  static const Color tabActive = Color(0xFF6A1A12);
  static const Color tabInactive = Color(0xFFFFFFFF);
  static const Color tabBorder = Color(0xFFE0E0E0);

  // --- Social Buttons ---
  static const Color googleButtonBg = Color(0xFFFFFFFF);
  static const Color appleButtonBg = Color(0xFF1A1A1A);

  // --- Onboarding Page Indicator ---
  static const Color indicatorActive = Color(0xFF6A1A12);
  static const Color indicatorInactive = Color(0xFFBBBBBB);

  // --- Gradient for onboarding background ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientMid, gradientEnd],
  );
}
