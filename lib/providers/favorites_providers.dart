import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_listing.dart';
import '../services/favorites_service.dart';
import 'auth_providers.dart';

final favoritesServiceProvider = Provider<FavoritesService>(
    (ref) => FavoritesService(ref.watch(supabaseClientProvider)));

/// Ensemble des references aimees par l'utilisateur courant.
/// Recharge quand l'auth change ; sert a colorer les coeurs partout.
final favoriteRefsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(favoritesServiceProvider).myRefs();
});

/// Fiches completes des vehicules aimes (ecran « Mes favoris »).
final favoriteVehiclesProvider =
    FutureProvider.autoDispose<List<VehicleListing>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(favoritesServiceProvider).myVehicles();
});
