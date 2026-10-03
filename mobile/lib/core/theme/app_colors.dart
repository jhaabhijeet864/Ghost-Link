import 'package:flutter/material.dart';

class AppColors {
  // Professional Neutral Dark Palette
  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF16181D);
  static const surfaceElevated = Color(0xFF1E2128);
  static const surfacePressed = Color(0xFF262A33);
  static const surfaceGlass = Color(0xF216181D);
  
  // Neutral Borders
  static const border = Color(0xFF2A2E37);
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderHighlight = Color(0x333B82F6);
  static const borderMetal = Color(0xFF2A2E37);

  // Clean Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  // Trustworthy Blue Accents
  static const accent = Color(0xFF3B82F6); // Professional Blue
  static const accentLight = Color(0xFF60A5FA);
  static const accentGlow = Color(0x333B82F6);
  static const accentCyan = Color(0xFF38BDF8);

  static const success = Color(0xFF10B981);
  static const successGlow = Color(0x2610B981);

  static const warning = Color(0xFFF59E0B);
  static const warningGlow = Color(0x26F59E0B);

  static const danger = Color(0xFFEF4444);
  static const error = danger;
  static const dangerGlow = Color(0x26EF4444);

  static const info = Color(0xFF3B82F6);
  static const neutral = Color(0xFF475569);
  static const primary = accent;

  // Professional Gradients
  static const LinearGradient metalCardGradient = LinearGradient(
    colors: [Color(0xFF1A1D24), Color(0xFF13151A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient metalHeaderGradient = LinearGradient(
    colors: [Color(0xFF1A1D24), Color(0xFF13151A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenAccentGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = metalCardGradient;
  static const LinearGradient primaryGradient = greenAccentGradient;
}
