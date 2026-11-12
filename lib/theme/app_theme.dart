import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Los colores principales solicitados por el usuario:
  static const Color cyan = Color(0xFF4EBCE8);
  static const Color teal = Color(0xFF00AFA9);
  static const Color yellow = Color(0xFFFFC400);
  static const Color white = Color(0xFFFFFFFF);

  // Colores complementarios para legibilidad y diseño:
  static const Color darkBlue = Color(0xFF0D3559);
  static const Color antBlue = Color(0xFF0A638B);
  static const Color background = Color(0xFFF3F9FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color softYellow = Color(0xFFFFF9E0);
  static const Color softTeal = Color(0xFFE2F7F6);
  static const Color softCyan = Color(0xFFE7F6FC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color expenseRed = Color(0xFFE53935);
  static const Color incomeGreen = Color(0xFF00AFA9);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.fredokaTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.yellow,
        tertiary: AppColors.cyan,
        surface: AppColors.cardBg,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.darkBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkBlue),
      ),
    );
  }
}

class AhorrantLogoTitle extends StatelessWidget {
  final double fontSize;
  const AhorrantLogoTitle({super.key, this.fontSize = 25});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Borde blanco exterior alrededor del texto
          Text(
            'Ahorrant',
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4.5
                ..color = AppColors.white,
            ),
          ),
          // Texto frontal con el color azul de la hormiga
          Text(
            'Ahorrant',
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

