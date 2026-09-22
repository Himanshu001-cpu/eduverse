import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens and typography for the Academic Futurist design system.
/// Based on stitch/DESIGN.md for The Eduverse.
class EduverseTheme {
  EduverseTheme._();

  // Colors
  static const Color primary = Color(0xFF004C44);
  static const Color primaryContainer = Color(0xFF00665C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF92E1D4);
  static const Color primaryFixed = Color(0xFFA2F1E4);
  static const Color primaryFixedDim = Color(0xFF86D5C8);
  static const Color emeraldVivid = Color(0xFF0E9272);

  static const Color secondary = Color(0xFF006875);
  static const Color secondaryContainer = Color(0xFF00E3FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFF9CF0FF);
  static const Color secondaryFixedDim = Color(0xFF00DAF3);

  static const Color tertiary = Color(0xFF705D00);
  static const Color tertiaryContainer = Color(0xFFC9A900);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryFixed = Color(0xFFFFE16D);
  static const Color tertiaryFixedDim = Color(0xFFE9C400);
  static const Color onTertiaryFixed = Color(0xFF221B00);

  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE8FF);
  static const Color surfaceContainerHighest = Color(0xFFD8E3FB);
  static const Color surfaceGray = Color(0xFFF8F9FA);

  static const Color onSurface = Color(0xFF111C2D);
  static const Color onSurfaceVariant = Color(0xFF3F4947);
  static const Color outline = Color(0xFF6F7977);
  static const Color outlineVariant = Color(0xFFBEC9C6);
  static const Color deepNavy = Color(0xFF040B14);

  // Spacing
  static const double containerMax = 1280.0;
  static const double gutter = 24.0;
  static const double marginMobile = 16.0;
  static const double marginDesktop = 48.0;
  static const double sectionGap = 80.0;

  // Typography
  static TextStyle displayLg({Color color = onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
        color: color,
      );

  static TextStyle displayLgMobile({Color color = onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headlineLg({Color color = onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle headlineMd({Color color = onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bodyLg({Color color = onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMd({Color color = onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle labelLg({Color color = onSurface, double letterSpacing = 0.5}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle labelSm({Color color = onSurfaceVariant, double letterSpacing = 0.3}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: color,
      );
}
