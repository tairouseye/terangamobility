import 'enums.dart';

/// Demande de piece deposee par un client (table `parts_requests`).
/// Contient un instantane du vehicule (fige a la creation) pour que le
/// partenaire Coree puisse sourcer la piece sans acceder a la table vehicles.
class PartsRequest {
  final String? id;
  final String clientId;
  final String? vehicleId;
  final String partName;
  final String? partPhotoUrl;
  final String? notes;
  final OrderStatus status;
  // Instantane vehicule
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleEngine;
  final String? vehicleVin;
  final DateTime? createdAt;

  const PartsRequest({
    this.id,
    required this.clientId,
    this.vehicleId,
    required this.partName,
    this.partPhotoUrl,
    this.notes,
    this.status = OrderStatus.nouvelleDemande,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleEngine,
    this.vehicleVin,
    this.createdAt,
  });

  /// Libelle vehicule lisible : "Hyundai Tucson (2018)".
  String get vehicleLabel {
    final b = [vehicleBrand, vehicleModel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (b.isEmpty) return 'Vehicule non precise';
    return vehicleYear != null ? '$b ($vehicleYear)' : b;
  }

  factory PartsRequest.fromJson(Map<String, dynamic> j) => PartsRequest(
        id: j['id'] as String?,
        clientId: j['client_id'] as String,
        vehicleId: j['vehicle_id'] as String?,
        partName: (j['part_name'] ?? '') as String,
        partPhotoUrl: j['part_photo_url'] as String?,
        notes: j['notes'] as String?,
        status: OrderStatus.fromDb(j['status'] as String?),
        vehicleBrand: j['vehicle_brand'] as String?,
        vehicleModel: j['vehicle_model'] as String?,
        vehicleYear: j['vehicle_year'] as int?,
        vehicleEngine: j['vehicle_engine'] as String?,
        vehicleVin: j['vehicle_vin'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toUpsert() => {
        if (id != null) 'id': id,
        'client_id': clientId,
        'vehicle_id': vehicleId,
        'part_name': partName,
        'part_photo_url': partPhotoUrl,
        'notes': notes,
        'status': status.dbValue,
        'vehicle_brand': vehicleBrand,
        'vehicle_model': vehicleModel,
        'vehicle_year': vehicleYear,
        'vehicle_engine': vehicleEngine,
        'vehicle_vin': vehicleVin,
      };
}
