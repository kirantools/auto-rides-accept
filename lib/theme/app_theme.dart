import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color oledBlack = Color(0xFF000000);
  static const Color safetyOrange = Color(0xFFFF00FF); // NEON PINK
  static const Color brightGreen = Color(0xFF39FF14);
  static const Color highContrastWhite = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF1A1A1A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oledBlack,
      primaryColor: safetyOrange,
      colorScheme: const ColorScheme.dark(
        primary: safetyOrange,
        secondary: brightGreen,
        surface: darkGrey,
        background: oledBlack,
        onPrimary: highContrastWhite,
        onSecondary: oledBlack,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: highContrastWhite,
        displayColor: highContrastWhite,
      ),
      cardTheme: CardThemeData(
        color: darkGrey,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: safetyOrange,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: safetyOrange,
        overlayColor: safetyOrange.withOpacity(0.2),
        valueIndicatorColor: safetyOrange,
        valueIndicatorTextStyle: const TextStyle(color: highContrastWhite),
      ),
    );
  }
}
