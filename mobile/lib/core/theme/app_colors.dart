import 'package:flutter/material.dart';

class AppColors {
  // Pure Gunmetal & Metal Black Dark Palette
  static const background = Color(0xFF060709);
  static const surface = Color(0xFF0C0E12);
  static const surfaceElevated = Color(0xFF12161E);
  static const surfacePressed = Color(0xFF191F2B);
  static const surfaceGlass = Color(0xF20C0E12);
  
  // Industrial Machined Metal Borders
  static const border = Color(0xFF1E2430);
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderHighlight = Color(0x3300E676);
  static const borderMetal = Color(0xFF2D3545);

  // Titanium & Crisp Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF526075);

  // Stealth Metal & Electric Emerald Accents
  static const accent = Color(0xFF00E676); // Tactical Neon Green
  static const accentLight = Color(0xFF69F0AE);
  static const accentGlow = Color(0x3300E676);
  static const accentCyan = Color(0xFF00E5FF);

  static const success = Color(0xFF00E676);
  static const successGlow = Color(0x2600E676);

  static const warning = Color(0xFFFFB300);
  static const warningGlow = Color(0x26FFB300);

  static const danger = Color(0xFFFF5252);
  static const error = danger;
  static const dangerGlow = Color(0x26FF5252);

  static const info = Color(0xFF40C4FF);
  static const neutral = Color(0xFF475569);
  static const primary = accent;

  // Metallic Brushed Gradients
  static const LinearGradient metalCardGradient = LinearGradient(
    colors: [Color(0xFF131720), Color(0xFF0A0C10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient metalHeaderGradient = LinearGradient(
    colors: [Color(0xFF171C26), Color(0xFF0D1016)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenAccentGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = metalCardGradient;
  static const LinearGradient primaryGradient = greenAccentGradient;
}
