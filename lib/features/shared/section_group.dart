import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Bloc de section visuellement distinct : un fond teinte + un bandeau
/// (icone + titre + sous-titre) dans une couleur propre au domaine.
///
/// Objectif : differencier d'un coup d'oeil les deux univers de l'app —
/// **Vehicules Coree** (bleu nuit) et **Pieces detachees** (or) — pour que
/// l'utilisateur repere immediatement la bonne zone.
class SectionGroup extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionGroup({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: color)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.gris)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
