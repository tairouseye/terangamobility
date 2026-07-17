import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_enums.dart';
import '../models/vehicle_order.dart';
import '../models/vehicle_request.dart';
import '../services/vehicle_order_service.dart';
import 'auth_providers.dart';

final vehicleOrderServiceProvider = Provider<VehicleOrderService>((ref) {
  return VehicleOrderService(ref.watch(supabaseClientProvider));
});

// --- Admin ---
final vehicleRequestsAdminProvider =
    FutureProvider<List<VehicleRequest>>((ref) {
  return ref.watch(vehicleOrderServiceProvider).listRequests();
});

final vehicleOrdersAdminProvider = FutureProvider<List<VehicleOrder>>((ref) {
  return ref.watch(vehicleOrderServiceProvider).listAllOrders();
});

// --- Client ---
final myVehicleRequestsProvider = FutureProvider<List<VehicleRequest>>((ref) {
  return ref.watch(vehicleOrderServiceProvider).myRequests();
});

final myVehicleOrdersProvider = FutureProvider<List<VehicleOrder>>((ref) {
  return ref.watch(vehicleOrderServiceProvider).myOrders();
});

final vehicleTrackingProvider =
    FutureProvider.family<List<VehicleTrackingEvent>, String>((ref, orderId) {
  return ref.watch(vehicleOrderServiceProvider).tracking(orderId);
});

/// Statut de commande vehicule courant (pour filtres admin, si besoin).
final vehicleOrderStatusFilterProvider =
    StateProvider<VehicleOrderStatus?>((ref) => null);
