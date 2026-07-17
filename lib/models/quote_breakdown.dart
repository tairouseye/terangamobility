/// Resultat du calcul serveur `compute_customer_quote()`.
/// total = piece + FedEx + douane + commission
class QuoteBreakdown {
  final num partPrice;
  final num fedexCost;
  final num customsCost;
  final num commission;
  final num total;

  const QuoteBreakdown({
    required this.partPrice,
    required this.fedexCost,
    required this.customsCost,
    required this.commission,
    required this.total,
  });

  num get deposit => (total * 0.7).roundToDouble();
  num get balance => total - deposit;

  factory QuoteBreakdown.fromRpc(Map<String, dynamic> j) => QuoteBreakdown(
        partPrice: (j['part_price'] ?? 0) as num,
        fedexCost: (j['fedex_cost'] ?? 0) as num,
        customsCost: (j['customs_cost'] ?? 0) as num,
        commission: (j['commission'] ?? 0) as num,
        total: (j['total_fcfa'] ?? 0) as num,
      );
}
