// lib/theme.dart
//
// The app's visual identity in one place ("design tokens").
// Grounded in padel: deep court-green + an optic padel-ball lime accent used
// sparingly, on a clean cool-neutral background. Keeping colors and text styles
// here (not scattered across screens) means we restyle the whole app by editing
// one file.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const court = Color(0xFF0E3A34); // deep petrol green — brand
  static const courtMid = Color(0xFF1C6B5F); // mid teal
  static const ball = Color(0xFFC4F135); // padel-ball lime — sparing accent
  static const surface = Color(0xFFF3F5F3); // app background
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF14312C); // primary text
  static const inkSoft = Color(0xFF5B6B66); // secondary text
  static const win = Color(0xFF2E9E6B);
  static const loss = Color(0xFFC25A45);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.court,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.court, surface: AppColors.surface),
    scaffoldBackgroundColor: AppColors.surface,
  );

  // One display family (Archivo) for headings, one UI family (Inter) for the
  // rest. Two clearly distinct families — no more.
  final text = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    headlineMedium: GoogleFonts.archivo(
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    headlineSmall: GoogleFonts.archivo(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleLarge: GoogleFonts.archivo(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
  );

  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ball,
      foregroundColor: AppColors.court,
    ),
  );
}
