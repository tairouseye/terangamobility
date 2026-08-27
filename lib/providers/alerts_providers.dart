import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_alert.dart';
import '../services/alerts_service.dart';
import 'auth_providers.dart';

final alertsServiceProvider = Provider<AlertsService>(
    (ref) => AlertsService(ref.watch(supabaseClientProvider)));

/// Alertes de l'utilisateur courant.
final myAlertsProvider = FutureProvider.autoDispose<List<VehicleAlert>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(alertsServiceProvider).myAlerts();
});
