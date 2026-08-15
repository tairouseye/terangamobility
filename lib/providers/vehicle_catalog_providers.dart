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

/// Candidats a la selection Facebook (km <= param), regroupes cote UI.
///
/// `autoDispose` : la selection est RECALCULEE a chaque ouverture de l'ecran
/// (plus de cache fige) — elle reflete donc l'etat courant du catalogue.
final facebookSelectionProvider =
    FutureProvider.autoDispose.family<List<VehicleListing>, int>((ref, maxKm) {
  return ref.watch(vehicleCatalogRepositoryProvider).forSelection(maxKm: maxKm);
});

/// TOUS les vehicules electriques disponibles (recalcules a chaque ouverture).
final electricVehiclesProvider =
    FutureProvider.autoDispose<List<VehicleListing>>(
        (ref) => ref.watch(vehicleCatalogRepositoryProvider).electric());

/// Nombre de vehicules disponibles ajoutes dans les dernieres 24 h.
final recentlyAddedCountProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(vehicleCatalogRepositoryProvider).recentlyAddedCount());

/// Verifie en direct sur Encar quelles references `EC-nnn` ont disparu.
/// L'argument est la liste de references jointe par des virgules (cle de cache).
/// Retourne l'ensemble des references « mortes » (annonce retiree d'Encar).
/// En cas d'erreur reseau ou de reponse invalide : ensemble vide (on affiche
/// tout — jamais de suppression a tort).
final deadEncarRefsProvider =
    FutureProvider.autoDispose.family<Set<String>, String>((ref, refsCsv) async {
  final refs = refsCsv.split(',').where((r) => r.isNotEmpty).toList();
  if (refs.isEmpty) return <String>{};
  try {
    final res = await ref
        .watch(supabaseClientProvider)
        .functions
        .invoke('encar-status', body: {'refs': refs});
    final data = res.data;
    final dead = (data is Map && data['dead'] is List)
        ? (data['dead'] as List).map((e) => e.toString()).toSet()
        : <String>{};
    return dead;
  } catch (_) {
    return <String>{};
  }
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
