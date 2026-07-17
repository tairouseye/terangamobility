import '../models/vehicle_filter.dart';
import '../models/vehicle_listing.dart';
import '../services/vehicle_data_source.dart';

/// Repository du catalogue de vehicules. Fait le pont entre l'UI et la
/// [VehicleDataSource], de sorte que changer de source (Supabase, API...)
/// n'impacte ni les providers ni les ecrans.
class VehicleCatalogRepository {
  final VehicleDataSource _source;
  VehicleCatalogRepository(this._source);

  Future<List<VehicleListing>> search(VehicleFilter filter) =>
      _source.fetchListings(filter);

  Future<VehicleListing?> byReference(String reference) =>
      _source.fetchByReference(reference);

  Future<List<String>> brands() => _source.distinctValues('brand');
  Future<List<String>> modelsForBrand(String brand) =>
      _source.modelsForBrand(brand);
  Future<List<String>> fuels() => _source.distinctValues('fuel');
  Future<List<String>> transmissions() =>
      _source.distinctValues('transmission');
  Future<List<String>> colors() => _source.distinctValues('color');
}
