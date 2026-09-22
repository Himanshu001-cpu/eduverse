import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Eduverse Design System: "Academic Futurist"
/// Derived from Stitch Project ID: 4880358185227461688
class EduverseColors {
  EduverseColors._();

  // Primary: Emerald Green
  static const Color primary = Color(0xFF004C44);
  static const Color primaryContainer = Color(0xFF00665C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF92E1D4);
  static const Color primaryFixed = Color(0xFFA2F1E4);
  static const Color primaryFixedDim = Color(0xFF86D5C8);

  // Secondary: High-tech Cyan / Deep Teal
  static const Color secondary = Color(0xFF006875);
  static const Color secondaryContainer = Color(0xFF00E3FD);
  static const Color secondaryFixed = Color(0xFF9CF0FF);
  static const Color secondaryFixedDim = Color(0xFF00DAF3);

  // Tertiary: Academic Achievement Gold
  static const Color tertiary = Color(0xFF705D00);
  static const Color tertiaryContainer = Color(0xFFC9A900);
  static const Color tertiaryFixed = Color(0xFFFFE16D);
  static const Color tertiaryFixedDim = Color(0xFFE9C400);

  // Accent & Semantics
  static const Color emeraldVivid = Color(0xFF0E9272);
  static const Color deepNavy = Color(0xFF040B14);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF9F9FF);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceBright = Color(0xFFF9F9FF);
  static const Color surfaceDim = Color(0xFFCFDAF2);
  static const Color surfaceGray = Color(0xFFF8F9FA);

  // Container hierarchy
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE8FF);
  static const Color surfaceContainerHighest = Color(0xFFD8E3FB);
  static const Color surfaceVariant = Color(0xFFD8E3FB);

  // Text & Outlines
  static const Color onSurface = Color(0xFF111C2D);
  static const Color onSurfaceVariant = Color(0xFF3F4947);
  static const Color outline = Color(0xFF6F7977);
  static const Color outlineVariant = Color(0xFFBEC9C6);
}

class EduverseTypography {
  EduverseTypography._();

  static TextStyle displayLg({Color color = EduverseColors.onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headlineLg({Color color = EduverseColors.onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle headlineMd({Color color = EduverseColors.onSurface}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  static TextStyle bodyLg({Color color = EduverseColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMd({Color color = EduverseColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle labelLg({Color color = EduverseColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle labelSm({Color color = EduverseColors.outline}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
        color: color,
      );
}
