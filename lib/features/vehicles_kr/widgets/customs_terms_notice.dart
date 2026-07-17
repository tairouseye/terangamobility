import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Encadre rappelant les conditions d'import vehicule :
/// paiement 70/30 et dedouanement a la charge du client.
/// Affiche sur la fiche, la demande de prix et avant validation de commande.
class CustomsTermsNotice extends StatelessWidget {
  final bool dense;
  const CustomsTermsNotice({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.ambre.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ambre.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFFB07C00), size: 20),
              SizedBox(width: 8),
              Text('Conditions d\'importation',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF7A5A00))),
            ],
          ),
          const SizedBox(height: 8),
          const _Point('Acompte de 70% a la commande, solde de 30% avant remise du vehicule.'),
          const _Point('Expedition par container maritime : delai estime de 60 a 90 jours.'),
          const _Point('Le dedouanement est entierement a la charge du client.'),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String text;
  const _Point(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF7A5A00))),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF7A5A00), fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
