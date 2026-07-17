import 'vehicle_enums.dart';

/// Demande de prix d'un vehicule (table `vehicle_requests`).
class VehicleRequest {
  final String? id;
  final String? clientId;
  final String vehicleReference;
  final String customerName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? country;
  final String? city;
  final String? message;
  final VehicleRequestStatus status;
  final DateTime? createdAt;

  const VehicleRequest({
    this.id,
    this.clientId,
    required this.vehicleReference,
    required this.customerName,
    required this.phone,
    this.whatsapp,
    this.email,
    this.country,
    this.city,
    this.message,
    this.status = VehicleRequestStatus.enAttenteDevis,
    this.createdAt,
  });

  factory VehicleRequest.fromJson(Map<String, dynamic> j) => VehicleRequest(
        id: j['id'] as String?,
        clientId: j['client_id'] as String?,
        vehicleReference: (j['vehicle_reference'] ?? '') as String,
        customerName: (j['customer_name'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
        country: j['country'] as String?,
        city: j['city'] as String?,
        message: j['message'] as String?,
        status: VehicleRequestStatus.fromDb(j['status'] as String?),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
