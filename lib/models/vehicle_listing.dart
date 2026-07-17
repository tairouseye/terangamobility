/// Annonce de vehicule importee (table `vehicle_listings`).
///
/// IMPORTANT : ne contient jamais de prix. Le catalogue affiche uniquement les
/// caracteristiques techniques ; le prix est communique via un devis.
class VehicleListing {
  final String id;
  final String reference;
  final String source;
  final String brand;
  final String model;
  final int? year;
  final String? version;
  final String? engine;
  final String? displacement; // cylindree
  final int? mileageKm;
  final String? transmission;
  final String? fuel;
  final String? color;
  final int? doors;
  final String? steering; // 'left' / 'right'
  final String? location;
  final String? condition;
  final List<String> options;
  final String? description;
  final List<String> photos;
  final bool isActive;

  const VehicleListing({
    required this.id,
    required this.reference,
    this.source = 'encar',
    required this.brand,
    required this.model,
    this.year,
    this.version,
    this.engine,
    this.displacement,
    this.mileageKm,
    this.transmission,
    this.fuel,
    this.color,
    this.doors,
    this.steering,
    this.location,
    this.condition,
    this.options = const [],
    this.description,
    this.photos = const [],
    this.isActive = true,
  });

  String get title =>
      '$brand $model${year != null ? ' $year' : ''}';

  String? get steeringLabel => switch (steering) {
        'left' => 'Volant a gauche',
        'right' => 'Volant a droite',
        _ => null,
      };

  String? get mileageLabel =>
      mileageKm == null ? null : '${_thousands(mileageKm!)} km';

  static String _thousands(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static List<String> _strList(dynamic v) => v is List
      ? v.map((e) => e.toString()).toList()
      : const <String>[];

  factory VehicleListing.fromJson(Map<String, dynamic> j) => VehicleListing(
        id: j['id'] as String,
        reference: (j['reference'] ?? '') as String,
        source: (j['source'] ?? 'encar') as String,
        brand: (j['brand'] ?? '') as String,
        model: (j['model'] ?? '') as String,
        year: j['year'] as int?,
        version: j['version'] as String?,
        engine: j['engine'] as String?,
        displacement: j['displacement'] as String?,
        mileageKm: j['mileage_km'] as int?,
        transmission: j['transmission'] as String?,
        fuel: j['fuel'] as String?,
        color: j['color'] as String?,
        doors: j['doors'] as int?,
        steering: j['steering'] as String?,
        location: j['location'] as String?,
        condition: j['condition'] as String?,
        options: _strList(j['options']),
        description: j['description'] as String?,
        photos: _strList(j['photos']),
        isActive: (j['is_active'] ?? true) as bool,
      );
}
