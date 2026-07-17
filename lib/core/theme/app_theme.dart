import 'package:flutter/material.dart';

/// Identite visuelle TerangaMobility — Parts & Vehicules.
/// Palette « Bleu nuit & or » : premium automobile, confiance, sobre.
///   primary  = bleu nuit (couleur d'action principale)
///   or       = accent dore (prestige, mises en avant)
///   vert     = succes (paye / valide)
///   ambre    = alertes / etapes en cours
class AppColors {
  const AppColors._();

  // Couleur principale (ex-rouge) : bleu nuit premium.
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryDark = Color(0xFF15293F);
  // Accent dore.
  static const Color or = Color(0xFFC9A24B);
  static const Color orDark = Color(0xFFA9853A);
  // Succes (paye / valide).
  static const Color vert = Color(0xFF2E7D5B);
  static const Color vertDark = Color(0xFF245F47);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color anthracite = Color(0xFF1C1C1E); // texte principal
  static const Color gris = Color(0xFF6B7280);
  static const Color grisClair = Color(0xFFF4F6F8); // fonds de cartes / app
  static const Color ambre = Color(0xFFE4A11B); // alertes / etapes en cours
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.vert,
      surface: AppColors.blanc,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.grisClair,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.anthracite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.anthracite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.blanc,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
