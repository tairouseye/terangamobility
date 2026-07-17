import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/order_view.dart';
import '../models/shipment.dart';

/// Commandes : consultation (client/admin), pilotage des statuts (admin),
/// expedition, et paiements acompte/solde via fonctions serveur.
class OrderService {
  final SupabaseClient _client;
  OrderService(this._client);

  static const _selectWithDetails =
      '*, customer_quotes(total_fcfa, request_id, '
      'parts_requests(part_name, vehicle_brand, vehicle_model, vehicle_year))';

  /// Commandes du client connecte (RLS : les siennes).
  Future<List<OrderView>> listForClient() async {
    final rows = await _client
        .from('orders')
        .select(_selectWithDetails)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Toutes les commandes (admin, via RLS).
  Future<List<OrderView>> listAll() => listForClient();

  /// Valide le devis + paie l'acompte 70% (fonction serveur securisee).
  Future<String> payDeposit({
    required String quoteId,
    String? method,
    String? reference,
  }) async {
    final res = await _client.rpc('pay_deposit', params: {
      'p_quote_id': quoteId,
      'p_method': method,
      'p_reference': reference,
    });
    return res as String;
  }

  /// Paie le solde 30% quand la commande est en 'solde_demande'.
  Future<void> payBalance({
    required String orderId,
    String? method,
    String? reference,
  }) async {
    await _client.rpc('pay_balance', params: {
      'p_order_id': orderId,
      'p_method': method,
      'p_reference': reference,
    });
  }

  /// Admin : fait avancer le statut d'une commande (trigger d'audit).
  Future<void> advanceStatus(String orderId, OrderStatus status) async {
    await _client
        .from('orders')
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  /// Recupere l'expedition liee a une commande (si existe).
  Future<Shipment?> getShipment(String orderId) async {
    final row = await _client
        .from('shipments')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return row == null ? null : Shipment.fromJson(row);
  }

  /// Admin : cree ou met a jour l'expedition (FedEx, transitaire, ETA).
  Future<Shipment> upsertShipment(Shipment shipment) async {
    final existing = await getShipment(shipment.orderId);
    final payload = shipment.toUpsert();
    if (existing?.id != null) payload['id'] = existing!.id;
    final row = await _client
        .from('shipments')
        .upsert(payload)
        .select()
        .single();
    return Shipment.fromJson(row);
  }
}
