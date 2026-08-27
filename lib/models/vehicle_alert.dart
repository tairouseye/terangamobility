/// Alerte « Prévenez-moi » : une recherche enregistrée par l'utilisateur.
class VehicleAlert {
  final String id;
  final String? label;
  final String? brand;
  final String? fuel;
  final num? priceMax;
  final int? yearMin;
  final bool active;

  const VehicleAlert({
    required this.id,
    this.label,
    this.brand,
    this.fuel,
    this.priceMax,
    this.yearMin,
    this.active = true,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> j) => VehicleAlert(
        id: j['id'] as String,
        label: j['label'] as String?,
        brand: j['brand'] as String?,
        fuel: j['fuel'] as String?,
        priceMax: j['price_max'] as num?,
        yearMin: j['year_min'] as int?,
        active: (j['active'] ?? true) as bool,
      );

  /// Libellé lisible à partir des critères (si aucun label stocké).
  static String buildLabel({
    String? brand,
    String? fuel,
    num? priceMax,
    int? yearMin,
  }) {
    final parts = <String>[
      ?brand,
      ?fuel,
      if (yearMin != null) '≥ $yearMin',
      if (priceMax != null) '≤ ${(priceMax / 1000000).round()}M',
    ];
    return parts.isEmpty ? 'Toutes les nouveautés' : parts.join(' · ');
  }

  String get display => (label == null || label!.isEmpty)
      ? buildLabel(brand: brand, fuel: fuel, priceMax: priceMax, yearMin: yearMin)
      : label!;
}
