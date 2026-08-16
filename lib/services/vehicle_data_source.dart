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

  /// Vehicules candidats a la selection Facebook : disponibles, prix 3M-15M,
  /// km <= maxKm. Le regroupement par tranche + score se fait cote UI.
  Future<List<VehicleListing>> fetchForSelection({int maxKm});

  /// TOUS les vehicules electriques disponibles (pour la selection Facebook).
  Future<List<VehicleListing>> fetchElectric();

  /// Nombre de vehicules disponibles AJOUTES recemment (fenetre par defaut 24 h).
  Future<int> countRecentlyAdded({Duration window});

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
        .eq('availability', 'available') // masque reserves / vendus / retires
        .gte('year', minYear);

    if (filter.brand != null) query = query.eq('brand', filter.brand!);
    if (filter.model != null) query = query.eq('model', filter.model!);
    if (filter.year != null) query = query.gte('year', filter.year!); // a partir de
    if (filter.yearMax != null) query = query.lte('year', filter.yearMax!);
    if (filter.priceMin != null) {
      query = query.gte('price_fcfa', filter.priceMin!);
    }
    if (filter.priceMax != null) {
      query = query.lte('price_fcfa', filter.priceMax!);
    }
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

    // Tri demande par l'utilisateur (defaut : plus recemment ajoutes).
    final rows = await switch (filter.sort) {
      VehicleSort.recent => query.order('imported_at', ascending: false),
      VehicleSort.priceAsc =>
        query.order('price_fcfa', ascending: true, nullsFirst: false),
      VehicleSort.priceDesc =>
        query.order('price_fcfa', ascending: false, nullsFirst: false),
      VehicleSort.yearDesc => query.order('year', ascending: false),
      VehicleSort.mileageAsc =>
        query.order('mileage_km', ascending: true, nullsFirst: false),
    }
        .limit(100);
    return (rows as List)
        .map((e) => VehicleListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VehicleListing>> fetchForSelection({int maxKm = 120000}) async {
    var query = _client
        .from(_table)
        .select()
        .eq('is_active', true)
        .eq('availability', 'available')
        .gte('price_fcfa', 3000000)
        .lt('price_fcfa', 15000000)
        .not('mileage_km', 'is', null)
        .lte('mileage_km', maxKm);
    final rows = await query.order('price_fcfa', ascending: true).limit(500);
    return (rows as List)
        .map((e) => VehicleListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VehicleListing>> fetchElectric() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('is_active', true)
        .eq('availability', 'available')
        .ilike('fuel', 'electri%') // « Electrique » (import) + variantes
        .order('year', ascending: false)
        .order('mileage_km', ascending: true, nullsFirst: false)
        .limit(200);
    return (rows as List)
        .map((e) => VehicleListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> countRecentlyAdded(
      {Duration window = const Duration(hours: 24)}) async {
    final since = DateTime.now().toUtc().subtract(window).toIso8601String();
    final rows = await _client
        .from(_table)
        .select('reference')
        .eq('is_active', true)
        .eq('availability', 'available')
        .gte('imported_at', since)
        .limit(2000);
    return (rows as List).length;
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
