import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalkfulnessTheme {
  //costanti colore
  static const Color primaryGreen = Color(0xFF012D1C); // Verde scuro
  static const Color secondaryTeal = Color.fromRGBO(24, 77, 79, 1); // Ottanio
  static const Color backgroundLight = Color.fromRGBO(
    248,
    250,
    249,
    1,
  ); // Sfondo chiaro
  static const Color accentMint = Color.fromRGBO(
    238,
    252,
    246,
    1,
  ); // Verde menta

  //tema chiaro
  static ThemeData get lightTheme {
    return ThemeData(
      //usa Material3
      useMaterial3: true,

      //schema dei colori
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: secondaryTeal,
        surface: backgroundLight,
      ),

      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.notoSerif(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: primaryGreen,
        ),
        backgroundColor: accentMint,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: false,
      ),

      // Configurazione NavigationBar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            backgroundLight, // Lo sfondo chiaro che abbiamo definito
        indicatorColor: primaryGreen.withValues(
          alpha: 0.1,
        ), // Il colore della "pillola" di selezione
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 28);
          }
          return IconThemeData(color: Colors.grey.shade600);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.black54,
          );
        }),
      ),

      //configurazione font
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.notoSerif(
          fontSize: 25,
          fontWeight: FontWeight.normal,
          color: primaryGreen,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
      ),

      //configurazione cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      //configurazione bottoni
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}
