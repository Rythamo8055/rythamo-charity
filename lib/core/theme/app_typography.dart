import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Section Headers: UPPERCASE, Geometric, Wide Tracking
  static TextStyle sectionHeader(BuildContext context) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.getTextSecondary(context),
      );

  // Data/Metrics: Oversized and Bold
  static TextStyle bigData(BuildContext context) => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.0,
        color: AppColors.getTextPrimary(context),
      );

  // Standard Body Text
  static TextStyle body(BuildContext context) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.getTextPrimary(context),
      );

  // Button Text
  static TextStyle button(BuildContext context) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.getTextPrimary(context),
      );
}
