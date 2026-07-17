import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/client_overview.dart';
import '../models/order_view.dart';
import '../models/parts_request.dart';
import '../models/payment.dart';
import '../models/vehicle.dart';

/// Acces admin aux clients (les policies « admin » de la RLS autorisent la
/// lecture globale ; un non-admin ne verra rien via ces requetes).
class AdminClientService {
  final SupabaseClient _client;
  AdminClientService(this._client);

  /// Liste des clients avec leurs compteurs. Recherche sur nom / whatsapp.
  ///
  /// Note : on agrege cote client plutot que via une vue SQL, pour rester
  /// simple tant que les volumes sont faibles (quelques centaines de clients).
  /// Au-dela, il faudra une vue Postgres dediee.
  Future<List<ClientSummary>> listClients({String? search}) async {
    var q = _client.from('profiles').select().eq('role', 'client');
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      q = q.or('full_name.ilike.$s,whatsapp.ilike.$s');
    }
    final rows = await q.order('created_at', ascending: false);
    final users = (rows as List)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
    if (users.isEmpty) return [];

    final ids = users.map((u) => u.id).toList();

    // Compteurs en 3 requetes globales (evite N+1).
    final vehicles = await _client.from('vehicles').select('user_id').inFilter('user_id', ids);
    final requests =
        await _client.from('parts_requests').select('client_id').inFilter('client_id', ids);
    final orders = await _client
        .from('orders')
        .select('client_id, customer_quotes(total_fcfa)')
        .inFilter('client_id', ids);
    final payments = await _client
        .from('payments')
        .select('amount, orders!inner(client_id)');

    int countBy(List rows, String field, String id) =>
        rows.where((r) => (r as Map)[field] == id).length;

    return users.map((u) {
      final myOrders =
          (orders as List).where((o) => (o as Map)['client_id'] == u.id);
      final totalOrdered = myOrders.fold<num>(0, (sum, o) {
        final q = (o as Map)['customer_quotes'] as Map?;
        return sum + ((q?['total_fcfa'] ?? 0) as num);
      });
      final totalPaid = (payments as List).fold<num>(0, (sum, p) {
        final o = (p as Map)['orders'] as Map?;
        if (o?['client_id'] != u.id) return sum;
        return sum + ((p['amount'] ?? 0) as num);
      });
      return ClientSummary(
        user: u,
        vehicleCount: countBy(vehicles as List, 'user_id', u.id),
        requestCount: countBy(requests as List, 'client_id', u.id),
        orderCount: myOrders.length,
        totalOrdered: totalOrdered,
        totalPaid: totalPaid,
      );
    }).toList();
  }

  Future<List<Vehicle>> clientVehicles(String clientId) async {
    final rows = await _client
        .from('vehicles')
        .select()
        .eq('user_id', clientId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PartsRequest>> clientRequests(String clientId) async {
    final rows = await _client
        .from('parts_requests')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PartsRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderView>> clientOrders(String clientId) async {
    final rows = await _client
        .from('orders')
        .select('*, customer_quotes(total_fcfa, request_id, '
            'parts_requests(part_name, vehicle_brand, vehicle_model, vehicle_year))')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> clientPayments(String clientId) async {
    final rows = await _client
        .from('payments')
        .select('*, orders!inner(client_id)')
        .eq('orders.client_id', clientId)
        .order('paid_at', ascending: false);
    return (rows as List)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
