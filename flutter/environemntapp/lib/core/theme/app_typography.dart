import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Poppins, matching the design specification.
class AppTypography {
  AppTypography._();

  static TextStyle heroTitle(Color color) => GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle screenTitle(Color color) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
        letterSpacing: 0.2,
      );

  static TextStyle sectionTitle(Color color) => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
        letterSpacing: 0.1,
      );

  static TextStyle cardTitle(Color color) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      );

  static TextStyle body(Color color) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  static TextStyle caption(Color color) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle button(Color color) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
      );

  static TextStyle label(Color color) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle overline(Color color) => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.2,
        height: 1.5,
      );
}
