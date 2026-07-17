import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/quote_breakdown.dart';

/// Carte de detail chiffre d'un devis (pièce + FedEx + douane + commission)
/// avec le total et la ventilation acompte 70% / solde 30%.
class QuoteBreakdownCard extends StatelessWidget {
  final QuoteBreakdown breakdown;
  const QuoteBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Prix de la piece', b.partPrice),
            _row('Transport FedEx', b.fedexCost),
            _row('Douane estimee', b.customsCost),
            _row('Commission Teranga Parts', b.commission),
            const Divider(height: 24),
            _row('TOTAL', b.total, bold: true, color: AppColors.anthracite),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grisClair,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _row('Acompte a payer (70%)', b.deposit,
                      color: AppColors.primary, bold: true),
                  const SizedBox(height: 4),
                  _row('Solde avant livraison (30%)', b.balance,
                      color: AppColors.vert),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, num value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color ?? AppColors.gris,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text(Formatters.fcfa(value), style: style),
        ],
      ),
    );
  }
}
