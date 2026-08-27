import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_alert.dart';

/// Gestion des alertes « Prévenez-moi » de l'utilisateur connecté (RLS : chacun
/// ne voit que les siennes).
class AlertsService {
  final SupabaseClient _client;
  AlertsService(this._client);

  static const _table = 'vehicle_alerts';
  String? get _uid => _client.auth.currentUser?.id;

  Future<List<VehicleAlert>> myAlerts() async {
    if (_uid == null) return const [];
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    String? brand,
    String? fuel,
    num? priceMax,
    int? yearMin,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from(_table).insert({
      'created_by': uid,
      'brand': brand,
      'fuel': fuel,
      'price_max': priceMax,
      'year_min': yearMin,
      'label': VehicleAlert.buildLabel(
          brand: brand, fuel: fuel, priceMax: priceMax, yearMin: yearMin),
    });
  }

  Future<void> remove(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
