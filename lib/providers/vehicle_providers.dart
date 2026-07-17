import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import 'auth_providers.dart';

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService(ref.watch(supabaseClientProvider));
});

/// Liste des vehicules de l'utilisateur connecte.
final myVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final uid = ref.watch(authServiceProvider).currentUser?.id;
  if (uid == null) return [];
  return ref.watch(vehicleServiceProvider).listForUser(uid);
});
