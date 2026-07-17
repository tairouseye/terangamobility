/// Expedition liee a une commande (table `shipments`).
class Shipment {
  final String? id;
  final String orderId;
  final String? fedexTracking;
  final String? transitaire;
  final DateTime? eta;
  final String? currentStep;
  final DateTime? createdAt;

  const Shipment({
    this.id,
    required this.orderId,
    this.fedexTracking,
    this.transitaire,
    this.eta,
    this.currentStep,
    this.createdAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> j) => Shipment(
        id: j['id'] as String?,
        orderId: j['order_id'] as String,
        fedexTracking: j['fedex_tracking'] as String?,
        transitaire: j['transitaire'] as String?,
        eta: j['eta'] != null ? DateTime.tryParse(j['eta'] as String) : null,
        currentStep: j['current_step'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toUpsert() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'fedex_tracking': fedexTracking,
        'transitaire': transitaire,
        if (eta != null) 'eta': eta!.toIso8601String(),
        'current_step': currentStep,
      };
}
