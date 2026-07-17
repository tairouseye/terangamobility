/// Devis client chiffre (table `customer_quotes`).
/// total = partPrice + fedexCost + customsCost + commission
class CustomerQuote {
  final String? id;
  final String requestId;
  final String? supplierQuoteId;
  final num partPrice; // prix piece converti en FCFA
  final num fedexCost; // transport FedEx selon poids
  final num customsCost; // douane estimee
  final num commission; // commission Teranga Parts
  final num totalFcfa;
  final String status; // draft / sent / accepted / rejected
  final DateTime? validUntil;
  final DateTime? createdAt;

  const CustomerQuote({
    this.id,
    required this.requestId,
    this.supplierQuoteId,
    required this.partPrice,
    required this.fedexCost,
    required this.customsCost,
    required this.commission,
    required this.totalFcfa,
    this.status = 'draft',
    this.validUntil,
    this.createdAt,
  });

  /// Acompte de 70% du modele de paiement.
  num get deposit => (totalFcfa * 0.7).roundToDouble();

  /// Solde de 30% a payer avant livraison.
  num get balance => totalFcfa - deposit;

  factory CustomerQuote.fromJson(Map<String, dynamic> j) => CustomerQuote(
        id: j['id'] as String?,
        requestId: j['request_id'] as String,
        supplierQuoteId: j['supplier_quote_id'] as String?,
        partPrice: (j['part_price'] ?? 0) as num,
        fedexCost: (j['fedex_cost'] ?? 0) as num,
        customsCost: (j['customs_cost'] ?? 0) as num,
        commission: (j['commission'] ?? 0) as num,
        totalFcfa: (j['total_fcfa'] ?? 0) as num,
        status: (j['status'] ?? 'draft') as String,
        validUntil: j['valid_until'] != null
            ? DateTime.tryParse(j['valid_until'] as String)
            : null,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
