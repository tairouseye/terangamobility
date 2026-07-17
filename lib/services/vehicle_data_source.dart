import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_filter.dart';
import '../models/vehicle_listing.dart';

/// Abstraction de la SOURCE de donnees du catalogue de vehicules.
///
/// L'application ne depend que de cette interface — jamais de la structure du
/// site source (Encar). Pour changer de fournisseur (API officielle, autre
/// site...), il suffit de fournir une nouvelle implementation.
abstract class VehicleDataSource {
  Future<List<VehicleListing>> fetchListings(VehicleFilter filter);
  Future<VehicleListing?> fetchByReference(String reference);

  /// Valeurs distinctes pour alimenter les filtres (marques, carburants...).
  Future<List<String>> distinctValues(String field);

  /// Modeles distincts disponibles pour une marque donnee (listes dependantes).
  Future<List<String>> modelsForBrand(String brand);
}

/// Implementation par defaut : lit la table `vehicle_listings` de Supabase,
/// alimentee en amont par un import independant (voir VehicleImportService).
class SupabaseVehicleDataSource implements VehicleDataSource {
  final SupabaseClient _client;
  SupabaseVehicleDataSource(this._client);

  static const _table = 'vehicle_listings';

  @override
  Future<List<VehicleListing>> fetchListings(VehicleFilter filter) async {
    // Regle metier : uniquement les vehicules de moins de 10 ans.
    final minYear = DateTime.now().year - 10;
    var query = _client
        .from(_table)
        .select()
        .eq('is_active', true)
        .gte('year', minYear);

    if (filter.brand != null) query = query.eq('brand', filter.brand!);
    if (filter.model != null) query = query.eq('model', filter.model!);
    if (filter.year != null) query = query.gte('year', filter.year!); // a partir de
    if (filter.fuel != null) query = query.eq('fuel', filter.fuel!);
    if (filter.transmission != null) {
      query = query.eq('transmission', filter.transmission!);
    }
    if (filter.color != null) query = query.eq('color', filter.color!);
    if (filter.maxMileage != null) {
      query = query.lte('mileage_km', filter.maxMileage!);
    }
    if (filter.keyword != null && filter.keyword!.trim().isNotEmpty) {
      final k = '%${filter.keyword!.trim()}%';
      query = query.or(
        'brand.ilike.$k,model.ilike.$k,version.ilike.$k,reference.ilike.$k',
      );
    }

    final rows = await query.order('imported_at', ascending: false).limit(100);
    return (rows as List)
        .map((e) => VehicleListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VehicleListing?> fetchByReference(String reference) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('reference', reference)
        .maybeSingle();
    return row == null ? null : VehicleListing.fromJson(row);
  }

  @override
  Future<List<String>> distinctValues(String field) async {
    final rows = await _client
        .from(_table)
        .select(field)
        .eq('is_active', true)
        .limit(1000);
    final set = <String>{};
    for (final r in rows as List) {
      final v = (r as Map)[field];
      if (v != null && v.toString().isNotEmpty) set.add(v.toString());
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Future<List<String>> modelsForBrand(String brand) async {
    final rows = await _client
        .from(_table)
        .select('model')
        .eq('is_active', true)
        .eq('brand', brand)
        .limit(1000);
    final set = <String>{};
    for (final r in rows as List) {
      final v = (r as Map)['model'];
      if (v != null && v.toString().isNotEmpty) set.add(v.toString());
    }
    final list = set.toList()..sort();
    return list;
  }
}
