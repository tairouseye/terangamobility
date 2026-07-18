import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/vehicle_enums.dart';
import '../models/vehicle_listing.dart';
import '../models/vehicle_order.dart';
import '../models/vehicle_request.dart';
import 'pdf/vehicle_documents.dart';

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

  /// Client : declare avoir effectue le paiement (virement/especes) ->
  /// notifie l'admin qui confirmera apres verification. kind = deposit|balance.
  Future<void> declarePayment(String orderId, String kind) async {
    await _client.rpc('declare_vehicle_payment',
        params: {'p_order_id': orderId, 'p_kind': kind});
  }

  // ------------------------------------------------------------------
  // RESERVATION (hold libre 72 h -> acompte 70%)
  // ------------------------------------------------------------------

  /// Client : reserve un vehicule (cree la commande + verrouille le listing 72 h).
  /// Renvoie l'id de la commande creee.
  Future<String> reserveVehicle(String reference) async {
    final id = await _client
        .rpc('reserve_vehicle', params: {'p_reference': reference});
    return id as String;
  }

  /// Client : declare avoir paye l'acompte 70% (methode + n° de transaction) ->
  /// notifie l'admin qui verifie la reception puis confirme.
  Future<void> declareDeposit(
      String orderId, String method, String reference) async {
    await _client.rpc('declare_vehicle_deposit', params: {
      'p_order_id': orderId,
      'p_method': method,
      'p_reference': reference,
    });
  }

  /// Client : choisit un creneau de RDV en agence pour payer l'acompte en especes.
  Future<void> bookDepositAppointment(String orderId, DateTime at) async {
    await _client.from('vehicle_orders').update(
        {'deposit_appointment_at': at.toIso8601String()}).eq('id', orderId);
  }

  /// Admin : relache la reservation (annulation) + libere le vehicule.
  Future<void> releaseReservation(String orderId) async {
    await _client.rpc('admin_release_reservation',
        params: {'p_order_id': orderId});
  }

  // --- ADMIN : confirmation des paiements (apres reception reelle) ---
  Future<void> confirmDeposit(String orderId, String method) async {
    await _client.from('vehicle_orders').update({
      'deposit_paid': true,
      'deposit_method': method,
      'status': 'commande_confirmee',
    }).eq('id', orderId);
  }

  Future<void> confirmBalance(String orderId, String method) async {
    await _client.from('vehicle_orders').update({
      'balance_paid': true,
      'balance_method': method,
      'status': 'pret_recuperation',
    }).eq('id', orderId);
  }

  // --- ADMIN : documents (facture puis contrat) ---
  Future<VehicleListing?> _vehicle(String reference) async {
    final row = await _client
        .from('vehicle_listings')
        .select()
        .eq('reference', reference)
        .maybeSingle();
    return row == null ? null : VehicleListing.fromJson(row);
  }

  Future<VehicleRequest?> _request(String? id) async {
    if (id == null) return null;
    final row = await _client
        .from('vehicle_requests')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : VehicleRequest.fromJson(row);
  }

  Future<void> _saveDoc(
      VehicleOrder order, String field, String name, Uint8List bytes) async {
    final path = '${order.clientId}/$name-${order.id}.pdf';
    await _client.storage.from(SupabaseConfig.bucketContracts).uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'application/pdf'),
        );
    await _client.from('vehicle_orders').update({field: path}).eq('id', order.id!);
  }

  Future<void> generateInvoice(VehicleOrder order) async {
    final vehicle = await _vehicle(order.vehicleReference);
    final request = await _request(order.requestId);
    final bytes = await VehicleDocuments.buildInvoice(
        order: order, vehicle: vehicle, request: request);
    await _saveDoc(order, 'invoice_path', 'facture', bytes);
    await _notifyClient(order, 'Votre facture est disponible');
  }

  Future<void> generateContract(VehicleOrder order) async {
    final vehicle = await _vehicle(order.vehicleReference);
    final request = await _request(order.requestId);
    final bytes = await VehicleDocuments.buildContract(
        order: order, vehicle: vehicle, request: request);
    await _saveDoc(order, 'contract_path', 'contrat', bytes);
    await _notifyClient(order, 'Votre contrat est disponible');
  }

  Future<void> _notifyClient(VehicleOrder order, String title) async {
    if (order.clientId == null) return;
    await _client.from('notifications').insert({
      'user_id': order.clientId,
      'title': title,
      'body': 'Vehicule ${order.vehicleReference}',
      'type': 'quote',
      'related_id': order.id,
    });
  }

  /// URL signee pour ouvrir un document par son chemin Storage.
  /// [expiry] par defaut 1 h (consultation) ; longue duree pour le partage WhatsApp.
  Future<String> documentUrl(String path,
      {Duration expiry = const Duration(hours: 1)}) {
    return _client.storage
        .from(SupabaseConfig.bucketContracts)
        .createSignedUrl(path, expiry.inSeconds);
  }
}
