import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client_overview.dart';
import '../models/order_view.dart';
import '../models/parts_request.dart';
import '../models/payment.dart';
import '../models/vehicle.dart';
import '../services/admin_client_service.dart';
import 'auth_providers.dart';

final adminClientServiceProvider = Provider<AdminClientService>((ref) {
  return AdminClientService(ref.watch(supabaseClientProvider));
});

/// Terme de recherche de la liste des clients.
final clientSearchProvider = StateProvider<String>((ref) => '');

/// Liste des clients (admin) filtree par la recherche.
final adminClientsProvider = FutureProvider<List<ClientSummary>>((ref) {
  final search = ref.watch(clientSearchProvider);
  return ref.watch(adminClientServiceProvider).listClients(search: search);
});

// --- Fiche client 360 ---
final clientVehiclesProvider =
    FutureProvider.family<List<Vehicle>, String>((ref, id) {
  return ref.watch(adminClientServiceProvider).clientVehicles(id);
});

final clientRequestsProvider =
    FutureProvider.family<List<PartsRequest>, String>((ref, id) {
  return ref.watch(adminClientServiceProvider).clientRequests(id);
});

final clientOrdersProvider =
    FutureProvider.family<List<OrderView>, String>((ref, id) {
  return ref.watch(adminClientServiceProvider).clientOrders(id);
});

final clientPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, id) {
  return ref.watch(adminClientServiceProvider).clientPayments(id);
});
