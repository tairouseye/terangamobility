import 'vehicle_enums.dart';

/// Commande de vehicule (table `vehicle_orders`).
class VehicleOrder {
  final String? id;
  final String? requestId;
  final String? clientId;
  final String vehicleReference;
  final num? totalPrice;
  final num? depositAmount; // 70%
  final num? balanceAmount; // 30%
  final bool depositPaid;
  final bool balancePaid;
  final String? trackingNumber;
  final String? shippingCompany;
  final DateTime? estimatedDeparture;
  final DateTime? estimatedArrival;
  final VehicleOrderStatus status;
  final bool termsAccepted;
  final DateTime? createdAt;

  const VehicleOrder({
    this.id,
    this.requestId,
    this.clientId,
    required this.vehicleReference,
    this.totalPrice,
    this.depositAmount,
    this.balanceAmount,
    this.depositPaid = false,
    this.balancePaid = false,
    this.trackingNumber,
    this.shippingCompany,
    this.estimatedDeparture,
    this.estimatedArrival,
    this.status = VehicleOrderStatus.enAttenteAcompte,
    this.termsAccepted = false,
    this.createdAt,
  });

  factory VehicleOrder.fromJson(Map<String, dynamic> j) => VehicleOrder(
        id: j['id'] as String?,
        requestId: j['request_id'] as String?,
        clientId: j['client_id'] as String?,
        vehicleReference: (j['vehicle_reference'] ?? '') as String,
        totalPrice: j['total_price'] as num?,
        depositAmount: j['deposit_amount'] as num?,
        balanceAmount: j['balance_amount'] as num?,
        depositPaid: (j['deposit_paid'] ?? false) as bool,
        balancePaid: (j['balance_paid'] ?? false) as bool,
        trackingNumber: j['tracking_number'] as String?,
        shippingCompany: j['shipping_company'] as String?,
        estimatedDeparture: j['estimated_departure'] != null
            ? DateTime.tryParse(j['estimated_departure'] as String)
            : null,
        estimatedArrival: j['estimated_arrival'] != null
            ? DateTime.tryParse(j['estimated_arrival'] as String)
            : null,
        status: VehicleOrderStatus.fromDb(j['status'] as String?),
        termsAccepted: (j['terms_accepted'] ?? false) as bool,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}

/// Une etape du suivi maritime (table `vehicle_tracking`).
class VehicleTrackingEvent {
  final String? id;
  final String orderId;
  final VehicleOrderStatus status;
  final String? description;
  final String? location;
  final DateTime? createdAt;

  const VehicleTrackingEvent({
    this.id,
    required this.orderId,
    required this.status,
    this.description,
    this.location,
    this.createdAt,
  });

  factory VehicleTrackingEvent.fromJson(Map<String, dynamic> j) =>
      VehicleTrackingEvent(
        id: j['id'] as String?,
        orderId: j['order_id'] as String,
        status: VehicleOrderStatus.fromDb(j['status'] as String?),
        description: j['description'] as String?,
        location: j['location'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
