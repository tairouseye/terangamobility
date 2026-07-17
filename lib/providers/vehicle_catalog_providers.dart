import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_filter.dart';
import '../models/vehicle_listing.dart';
import '../repositories/vehicle_catalog_repository.dart';
import '../services/vehicle_data_source.dart';
import '../services/vehicle_request_service.dart';
import 'auth_providers.dart';

/// Source de donnees du catalogue (Supabase par defaut ; overridee en demo).
final vehicleDataSourceProvider = Provider<VehicleDataSource>((ref) {
  return SupabaseVehicleDataSource(ref.watch(supabaseClientProvider));
});

final vehicleCatalogRepositoryProvider =
    Provider<VehicleCatalogRepository>((ref) {
  return VehicleCatalogRepository(ref.watch(vehicleDataSourceProvider));
});

final vehicleRequestServiceProvider = Provider<VehicleRequestService>((ref) {
  return VehicleRequestService(ref.watch(supabaseClientProvider));
});

/// Filtre courant du catalogue (modifiable par l'UI).
final vehicleFilterProvider =
    StateProvider<VehicleFilter>((ref) => const VehicleFilter());

/// Resultats du catalogue selon le filtre courant.
final vehicleListingsProvider = FutureProvider<List<VehicleListing>>((ref) {
  final filter = ref.watch(vehicleFilterProvider);
  return ref.watch(vehicleCatalogRepositoryProvider).search(filter);
});

/// Une fiche vehicule par reference.
final vehicleByRefProvider =
    FutureProvider.family<VehicleListing?, String>((ref, reference) {
  return ref.watch(vehicleCatalogRepositoryProvider).byReference(reference);
});

/// Valeurs distinctes pour les listes de filtres.
final vehicleBrandsProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(vehicleCatalogRepositoryProvider).brands());

/// Modeles disponibles pour une marque (liste dependante du filtre).
final vehicleModelsProvider = FutureProvider.family<List<String>, String>(
    (ref, brand) =>
        ref.watch(vehicleCatalogRepositoryProvider).modelsForBrand(brand));
final vehicleFuelsProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(vehicleCatalogRepositoryProvider).fuels());
final vehicleTransmissionsProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(vehicleCatalogRepositoryProvider).transmissions());
final vehicleColorsProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(vehicleCatalogRepositoryProvider).colors());
