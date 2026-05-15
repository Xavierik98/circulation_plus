import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Navy Background
  static const Color background = Color(0xFF060B18);
  static const Color surface = Color(0xFF0D1421);
  static const Color surfaceVariant = Color(0xFF111827);
  static const Color cardBackground = Color(0xFF131C2E);
  static const Color cardBorder = Color(0xFF1E2D47);

  // Brand Electric Blue
  static const Color primary = Color(0xFF4A9EFF);
  static const Color primaryDark = Color(0xFF2D7DD2);
  static const Color primaryLight = Color(0xFF76BCFF);
  static const Color primaryGlow = Color(0x334A9EFF);

  // Accent Colors
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentGlow = Color(0x2200D4FF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successGlow = Color(0x2210B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningGlow = Color(0x22F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorGlow = Color(0x22EF4444);
  static const Color info = Color(0xFF6366F1);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BAD0);
  static const Color textTertiary = Color(0xFF6B7A99);
  static const Color textDisabled = Color(0xFF3D4F6B);

  // Glass / Overlay
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassMedium = Color(0x14FFFFFF);
  static const Color glassStrong = Color(0x1AFFFFFF);
  static const Color overlay = Color(0x80060B18);

  // Divider
  static const Color divider = Color(0xFF1A2540);
  static const Color dividerLight = Color(0xFF243050);

  // Status badges
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusContested = Color(0xFF8B5CF6);
  static const Color statusCancelled = Color(0xFF6B7A99);

  // Congo National Flag Colors
  static const Color congoGreen = Color(0xFF009A44);
  static const Color congoRed = Color(0xFFDC241F);
  static const Color congoYellow = Color(0xFFFCD116);

  // Police Gold / Brass (PNC badge)
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldDark = Color(0xFF9A7830);
  static const Color goldLight = Color(0xFFE8C870);
  static const Color goldGlow = Color(0x33C9A84C);

  // Deep Police Navy (badge backgrounds)
  static const Color policeNavy = Color(0xFF0A1628);
  static const Color policeBlue = Color(0xFF17336B);

  // Gradients — Police
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE8C870), Color(0xFFC9A84C), Color(0xFF9A7830)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient policeGradient = LinearGradient(
    colors: [Color(0xFF17336B), Color(0xFF0A1628)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient congoFlagGradient = LinearGradient(
    colors: [Color(0xFF009A44), Color(0xFFFCD116), Color(0xFFDC241F)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF4A9EFF),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF00D4FF),
  ];

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A9EFF), Color(0xFF2D7DD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF060B18), Color(0xFF0D1421)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131C2E), Color(0xFF0F1828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
