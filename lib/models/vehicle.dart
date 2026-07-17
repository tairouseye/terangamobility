/// Vehicule d'un client (table `vehicles`).
class Vehicle {
  final String? id;
  final String userId;
  final String brand;
  final String model;
  final int? year;
  final String? engine; // motorisation
  final String? vin; // numero de chassis
  final String? carteGriseUrl;
  final DateTime? createdAt;

  const Vehicle({
    this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.year,
    this.engine,
    this.vin,
    this.carteGriseUrl,
    this.createdAt,
  });

  String get label =>
      '$brand $model${year != null ? ' ($year)' : ''}';

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String?,
        userId: j['user_id'] as String,
        brand: (j['brand'] ?? '') as String,
        model: (j['model'] ?? '') as String,
        year: j['year'] as int?,
        engine: j['engine'] as String?,
        vin: j['vin'] as String?,
        carteGriseUrl: j['carte_grise_url'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toUpsert() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'brand': brand,
        'model': model,
        'year': year,
        'engine': engine,
        'vin': vin,
        'carte_grise_url': carteGriseUrl,
      };
}
