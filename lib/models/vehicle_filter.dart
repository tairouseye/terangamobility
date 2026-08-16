/// Tri du catalogue de vehicules.
enum VehicleSort {
  recent, // plus recemment ajoutes (defaut)
  priceAsc, // prix croissant
  priceDesc, // prix decroissant
  yearDesc, // annee la plus recente
  mileageAsc, // kilometrage croissant
}

extension VehicleSortLabel on VehicleSort {
  String get label => switch (this) {
        VehicleSort.recent => 'Plus récents',
        VehicleSort.priceAsc => 'Prix croissant',
        VehicleSort.priceDesc => 'Prix décroissant',
        VehicleSort.yearDesc => 'Année récente',
        VehicleSort.mileageAsc => 'Km croissant',
      };
}

/// Criteres de recherche du catalogue de vehicules.
class VehicleFilter {
  final String? keyword;
  final String? brand;
  final String? model;
  final int? year; // annee MINIMUM (« a partir de »)
  final int? yearMax; // annee MAXIMUM (« jusqu'a »)
  final int? priceMin; // prix FCFA minimum
  final int? priceMax; // prix FCFA maximum
  final String? fuel;
  final String? transmission;
  final int? maxMileage;
  final String? color;
  final VehicleSort sort;

  const VehicleFilter({
    this.keyword,
    this.brand,
    this.model,
    this.year,
    this.yearMax,
    this.priceMin,
    this.priceMax,
    this.fuel,
    this.transmission,
    this.maxMileage,
    this.color,
    this.sort = VehicleSort.recent,
  });

  bool get isEmpty =>
      (keyword == null || keyword!.isEmpty) &&
      brand == null &&
      model == null &&
      year == null &&
      yearMax == null &&
      priceMin == null &&
      priceMax == null &&
      fuel == null &&
      transmission == null &&
      maxMileage == null &&
      color == null;

  /// Nombre de filtres actifs (le tri n'est pas un filtre). La plage de prix et
  /// la plage d'annee comptent chacune pour 1.
  int get activeCount =>
      [brand, model, fuel, transmission, maxMileage, color]
          .where((e) => e != null)
          .length +
      ((year != null || yearMax != null) ? 1 : 0) +
      ((priceMin != null || priceMax != null) ? 1 : 0);

  VehicleFilter copyWith({
    String? keyword,
    Object? brand = _sentinel,
    Object? model = _sentinel,
    Object? year = _sentinel,
    Object? yearMax = _sentinel,
    Object? priceMin = _sentinel,
    Object? priceMax = _sentinel,
    Object? fuel = _sentinel,
    Object? transmission = _sentinel,
    Object? maxMileage = _sentinel,
    Object? color = _sentinel,
    VehicleSort? sort,
  }) =>
      VehicleFilter(
        keyword: keyword ?? this.keyword,
        brand: brand == _sentinel ? this.brand : brand as String?,
        model: model == _sentinel ? this.model : model as String?,
        year: year == _sentinel ? this.year : year as int?,
        yearMax: yearMax == _sentinel ? this.yearMax : yearMax as int?,
        priceMin: priceMin == _sentinel ? this.priceMin : priceMin as int?,
        priceMax: priceMax == _sentinel ? this.priceMax : priceMax as int?,
        fuel: fuel == _sentinel ? this.fuel : fuel as String?,
        transmission: transmission == _sentinel
            ? this.transmission
            : transmission as String?,
        maxMileage:
            maxMileage == _sentinel ? this.maxMileage : maxMileage as int?,
        color: color == _sentinel ? this.color : color as String?,
        sort: sort ?? this.sort,
      );

  static const _sentinel = Object();
}
