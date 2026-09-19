import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF090D14);
  static const surface = Color(0xFF0F1520);
  static const surfaceElevated = Color(0xFF151D2A);
  static const surfacePressed = Color(0xFF1C2738);
  static const surfaceGlass = Color(0xCC121A26);
  
  static const border = Color(0xFF222C3D);
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderHighlight = Color(0x406366F1);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const accent = Color(0xFF6366F1);
  static const accentLight = Color(0xFF818CF8);
  static const accentGlow = Color(0x406366F1);
  static const accentCyan = Color(0xFF06B6D4);

  static const success = Color(0xFF10B981);
  static const successGlow = Color(0x3310B981);

  static const warning = Color(0xFFF59E0B);
  static const warningGlow = Color(0x33F59E0B);

  static const danger = Color(0xFFEF4444);
  static const dangerGlow = Color(0x33EF4444);

  static const info = Color(0xFF38BDF8);
  static const neutral = Color(0xFF64748B);
  static const primary = accent;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161E2C), Color(0xFF0F1520)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x331E293B), Color(0x1A0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
