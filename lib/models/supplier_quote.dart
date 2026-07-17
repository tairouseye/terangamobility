/// Proposition du partenaire Coree pour une demande (table `suppliers_quotes`).
class SupplierQuote {
  final String? id;
  final String requestId;
  final String partnerId;
  final String? partRef;
  final bool available;
  final num? buyPriceKrw; // prix d'achat en won coreen
  final num? weightKg;
  final String? dimensions;
  final String? photoUrl;
  final int? leadTimeDays;
  final DateTime? createdAt;

  const SupplierQuote({
    this.id,
    required this.requestId,
    required this.partnerId,
    this.partRef,
    this.available = true,
    this.buyPriceKrw,
    this.weightKg,
    this.dimensions,
    this.photoUrl,
    this.leadTimeDays,
    this.createdAt,
  });

  factory SupplierQuote.fromJson(Map<String, dynamic> j) => SupplierQuote(
        id: j['id'] as String?,
        requestId: j['request_id'] as String,
        partnerId: j['partner_id'] as String,
        partRef: j['part_ref'] as String?,
        available: (j['available'] ?? true) as bool,
        buyPriceKrw: j['buy_price_krw'] as num?,
        weightKg: j['weight_kg'] as num?,
        dimensions: j['dimensions'] as String?,
        photoUrl: j['photo_url'] as String?,
        leadTimeDays: j['lead_time_days'] as int?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toUpsert() => {
        if (id != null) 'id': id,
        'request_id': requestId,
        'partner_id': partnerId,
        'part_ref': partRef,
        'available': available,
        'buy_price_krw': buyPriceKrw,
        'weight_kg': weightKg,
        'dimensions': dimensions,
        'photo_url': photoUrl,
        'lead_time_days': leadTimeDays,
      };
}
