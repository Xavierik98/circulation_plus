import 'package:flutter/material.dart';

/// Palette du design system Stitch (Material 3, thème clair) — généré pour
/// Circulation+. Ne PAS modifier ces valeurs : elles reproduisent à l'identique
/// le design validé sur Stitch. Toute évolution visuelle doit repartir de Stitch.
class StitchColors {
  StitchColors._();

  static const Color onSecondaryFixedVariant = Color(0xFF524600);
  static const Color error = Color(0xFFba1a1a);
  static const Color onSecondaryContainer = Color(0xFF726200);
  static const Color onTertiaryFixed = Color(0xFF410002);
  static const Color inverseOnSurface = Color(0xFFf0f0f3);
  static const Color onTertiaryContainer = Color(0xFFfffbff);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color outlineVariant = Color(0xFFbdcaba);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color onBackground = Color(0xFF1a1c1e);
  static const Color inverseSurface = Color(0xFF2f3133);
  static const Color onPrimaryContainer = Color(0xFFf7fff3);
  static const Color surfaceBright = Color(0xFFf9f9fc);
  static const Color tertiary = Color(0xFFbb0014);
  static const Color primaryContainer = Color(0xFF00873c);
  static const Color onErrorContainer = Color(0xFF93000a);
  static const Color surfaceDim = Color(0xFFdadadc);
  static const Color surfaceContainerHigh = Color(0xFFe8e8ea);
  static const Color onError = Color(0xFFffffff);
  static const Color tertiaryFixedDim = Color(0xFFffb4ab);
  static const Color tertiaryContainer = Color(0xFFe71420);
  static const Color secondaryFixedDim = Color(0xFFe2c633);
  static const Color secondary = Color(0xFF6d5e00);
  static const Color outline = Color(0xFF6e7a6d);
  static const Color onPrimaryFixedVariant = Color(0xFF005322);
  static const Color primaryFixedDim = Color(0xFF66de82);
  static const Color primary = Color(0xFF006b2e);
  static const Color secondaryFixed = Color(0xFFffe251);
  static const Color inversePrimary = Color(0xFF66de82);
  static const Color surfaceContainer = Color(0xFFeeeef0);
  static const Color background = Color(0xFFf9f9fc);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color onSurface = Color(0xFF1a1c1e);
  static const Color surface = Color(0xFFf9f9fc);
  static const Color surfaceVariant = Color(0xFFe2e2e5);
  static const Color onSecondaryFixed = Color(0xFF211b00);
  static const Color onSurfaceVariant = Color(0xFF3e4a3e);
  static const Color secondaryContainer = Color(0xFFfcdf4b);
  static const Color surfaceTint = Color(0xFF006d2f);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onPrimaryFixed = Color(0xFF002109);
  static const Color onTertiaryFixedVariant = Color(0xFF93000d);
  static const Color surfaceContainerLow = Color(0xFFf3f3f6);
  static const Color tertiaryFixed = Color(0xFFffdad6);
  static const Color primaryFixed = Color(0xFF83fb9c);
  static const Color surfaceContainerHighest = Color(0xFFe2e2e5);

  // Couleurs drapeau Congo utilisées en accents (bandeau, etc.)
  static const Color congoGreen = Color(0xFF009543);
  static const Color congoYellow = Color(0xFFFBDE06);
  static const Color congoRed = Color(0xFFED1B24);

  static const LinearGradient congoFlagGradient = LinearGradient(
    colors: [congoGreen, congoYellow, congoRed],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
