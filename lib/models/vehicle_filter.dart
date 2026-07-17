/// Criteres de recherche du catalogue de vehicules.
class VehicleFilter {
  final String? keyword;
  final String? brand;
  final String? model;
  final int? year;
  final String? fuel;
  final String? transmission;
  final int? maxMileage;
  final String? color;

  const VehicleFilter({
    this.keyword,
    this.brand,
    this.model,
    this.year,
    this.fuel,
    this.transmission,
    this.maxMileage,
    this.color,
  });

  bool get isEmpty =>
      (keyword == null || keyword!.isEmpty) &&
      brand == null &&
      model == null &&
      year == null &&
      fuel == null &&
      transmission == null &&
      maxMileage == null &&
      color == null;

  int get activeCount => [
        brand,
        model,
        year,
        fuel,
        transmission,
        maxMileage,
        color,
      ].where((e) => e != null).length;

  VehicleFilter copyWith({
    String? keyword,
    Object? brand = _sentinel,
    Object? model = _sentinel,
    Object? year = _sentinel,
    Object? fuel = _sentinel,
    Object? transmission = _sentinel,
    Object? maxMileage = _sentinel,
    Object? color = _sentinel,
  }) =>
      VehicleFilter(
        keyword: keyword ?? this.keyword,
        brand: brand == _sentinel ? this.brand : brand as String?,
        model: model == _sentinel ? this.model : model as String?,
        year: year == _sentinel ? this.year : year as int?,
        fuel: fuel == _sentinel ? this.fuel : fuel as String?,
        transmission: transmission == _sentinel
            ? this.transmission
            : transmission as String?,
        maxMileage:
            maxMileage == _sentinel ? this.maxMileage : maxMileage as int?,
        color: color == _sentinel ? this.color : color as String?,
      );

  static const _sentinel = Object();
}
