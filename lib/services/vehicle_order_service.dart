import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_enums.dart';
import '../models/vehicle_order.dart';
import '../models/vehicle_request.dart';

/// Flux commande vehicule cote admin ET client.
class VehicleOrderService {
  final SupabaseClient _client;
  VehicleOrderService(this._client);

  // ------------------------------------------------------------------
  // ADMIN
  // ------------------------------------------------------------------

  /// Demandes de prix (admin voit tout via RLS). Filtrable par statut.
  Future<List<VehicleRequest>> listRequests({VehicleRequestStatus? status}) async {
    var q = _client.from('vehicle_requests').select();
    if (status != null) q = q.eq('status', status.dbValue);
    final rows = await q.order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Envoie un devis : cree la commande (acompte 70% / solde 30%), passe la
  /// demande a "devis_envoye" et notifie le client.
  Future<VehicleOrder> sendQuote({
    required VehicleRequest request,
    required num totalPrice,
  }) async {
    final deposit = (totalPrice * 0.7).roundToDouble();
    final balance = totalPrice - deposit;

    final row = await _client
        .from('vehicle_orders')
        .insert({
          'request_id': request.id,
          'client_id': request.clientId,
          'vehicle_reference': request.vehicleReference,
          'total_price': totalPrice,
          'deposit_amount': deposit,
          'balance_amount': balance,
          'status': 'en_attente_acompte',
        })
        .select()
        .single();

    await _client
        .from('vehicle_requests')
        .update({'status': 'devis_envoye'}).eq('id', request.id!);

    if (request.clientId != null) {
      await _client.from('notifications').insert({
        'user_id': request.clientId,
        'title': 'Votre devis est pret',
        'body': 'Vehicule ${request.vehicleReference} — consultez votre devis.',
        'type': 'quote',
        'related_id': row['id'],
      });
    }
    return VehicleOrder.fromJson(row);
  }

  /// Toutes les commandes vehicule (admin).
  Future<List<VehicleOrder>> listAllOrders() async {
    final rows = await _client
        .from('vehicle_orders')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin : fait avancer le statut (le trigger journalise + notifie le client).
  Future<void> advanceStatus(String orderId, VehicleOrderStatus status) async {
    await _client
        .from('vehicle_orders')
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  /// Admin : renseigne les infos d'expedition maritime.
  Future<void> setShipping({
    required String orderId,
    String? trackingNumber,
    String? shippingCompany,
    DateTime? departure,
    DateTime? arrival,
  }) async {
    await _client.from('vehicle_orders').update({
      'tracking_number': trackingNumber,
      'shipping_company': shippingCompany,
      'estimated_departure': departure?.toIso8601String().split('T').first,
      'estimated_arrival': arrival?.toIso8601String().split('T').first,
    }).eq('id', orderId);
  }

  // ------------------------------------------------------------------
  // CLIENT
  // ------------------------------------------------------------------

  Future<List<VehicleRequest>> myRequests() async {
    final rows = await _client
        .from('vehicle_requests')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VehicleOrder>> myOrders() async {
    final rows = await _client
        .from('vehicle_orders')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VehicleTrackingEvent>> tracking(String orderId) async {
    final rows = await _client
        .from('vehicle_tracking')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => VehicleTrackingEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> payDeposit(String orderId, {String? method}) async {
    await _client.rpc('pay_vehicle_deposit',
        params: {'p_order_id': orderId, 'p_method': method});
  }

  Future<void> payBalance(String orderId, {String? method}) async {
    await _client.rpc('pay_vehicle_balance',
        params: {'p_order_id': orderId, 'p_method': method});
  }
}
