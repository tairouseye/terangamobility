import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/client_overview.dart';
import '../models/customer_quote.dart';
import '../models/enums.dart';
import '../models/order_view.dart';
import '../models/parts_request.dart';
import '../models/payment.dart';
import '../models/quote_breakdown.dart';
import '../models/shipment.dart';
import '../models/supplier_quote.dart';
import '../models/vehicle.dart';
import '../services/admin_client_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/quote_service.dart';
import '../services/request_service.dart';
import '../services/storage_service.dart';
import '../services/supplier_quote_service.dart';
import '../services/vehicle_service.dart';
import 'demo_store.dart';

/// Profil affiche dans les dashboards en mode demo.
final demoProfile = AppUser(
  id: DemoStore.clientId,
  fullName: 'Awa',
  whatsapp: '221770000000',
  role: UserRole.client,
);

/// Utilisateur factice (uniquement pour recuperer un id dans les ecrans).
final demoUser = User.fromJson({
  'id': DemoStore.clientId,
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00.000Z',
});

class DemoAuthService extends AuthService {
  DemoAuthService(super.client);
  @override
  User? get currentUser => demoUser;
  @override
  Future<void> signOut() async {}
  @override
  Future<AppUser?> fetchProfile() async => demoProfile;
}

class DemoVehicleService extends VehicleService {
  final DemoStore _s;
  DemoVehicleService(super.client, this._s);
  @override
  Future<List<Vehicle>> listForUser(String userId) async =>
      _s.vehiclesFor(userId);
  @override
  Future<Vehicle> upsert(Vehicle vehicle) async => _s.upsertVehicle(vehicle);
  @override
  Future<void> delete(String id) async => _s.deleteVehicle(id);
}

class DemoRequestService extends RequestService {
  final DemoStore _s;
  DemoRequestService(super.client, this._s);
  @override
  Future<List<PartsRequest>> listForClient(String clientId) async =>
      _s.requestsFor(clientId);
  @override
  Future<PartsRequest> create(PartsRequest request) async =>
      _s.createRequest(request);
  @override
  Future<void> delete(String id) async {}
}

class DemoSupplierQuoteService extends SupplierQuoteService {
  final DemoStore _s;
  DemoSupplierQuoteService(super.client, this._s);
  @override
  Future<List<PartsRequest>> listOpenRequests() async => _s.openRequests();
  @override
  Future<List<SupplierQuote>> listQuotesForRequest(String requestId) async =>
      _s.quotesForRequest(requestId);
  @override
  Future<SupplierQuote> submit(SupplierQuote quote) async =>
      _s.submitSupplierQuote(quote);
}

class DemoQuoteService extends QuoteService {
  final DemoStore _s;
  DemoQuoteService(super.client, this._s);

  // Reproduit compute_customer_quote() cote client, pour la demo.
  static const _krwToFcfa = 0.65;
  static const _fedexPerKg = 9000;
  static const _commissionPct = 15;
  static const _rates = {
    'general': [20, 5000],
    'carrosserie': [25, 5000],
    'electronique': [30, 8000],
    'mecanique': [20, 5000],
  };

  @override
  Future<QuoteBreakdown> compute({
    required String supplierQuoteId,
    String customsCategory = 'general',
  }) async {
    final sq = _s.supplierQuotes.firstWhere((q) => q.id == supplierQuoteId);
    final rate = _rates[customsCategory] ?? _rates['general']!;
    final part = ((sq.buyPriceKrw ?? 0) * _krwToFcfa).round();
    final fedex = ((sq.weightKg ?? 0) * _fedexPerKg).round();
    final customs =
        ((part + fedex) * (rate[0]) / 100).round().clamp(rate[1], 1 << 62);
    final commission = ((part + fedex + customs) * _commissionPct / 100).round();
    return QuoteBreakdown(
      partPrice: part,
      fedexCost: fedex,
      customsCost: customs,
      commission: commission,
      total: part + fedex + customs + commission,
    );
  }

  @override
  Future<CustomerQuote> sendQuote({
    required String requestId,
    required String supplierQuoteId,
    required QuoteBreakdown b,
    DateTime? validUntil,
  }) async {
    return _s.sendCustomerQuote(CustomerQuote(
      requestId: requestId,
      supplierQuoteId: supplierQuoteId,
      partPrice: b.partPrice,
      fedexCost: b.fedexCost,
      customsCost: b.customsCost,
      commission: b.commission,
      totalFcfa: b.total,
      status: 'sent',
      validUntil: validUntil,
    ));
  }

  @override
  Future<List<PartsRequest>> listRequestsToQuote() async =>
      _s.requestsToQuote();
  @override
  Future<List<CustomerQuote>> listForClient() async => _s.quotesForClient();
}

class DemoOrderService extends OrderService {
  final DemoStore _s;
  DemoOrderService(super.client, this._s);
  @override
  Future<List<OrderView>> listForClient() async => _s.orderViews();
  @override
  Future<List<OrderView>> listAll() async => _s.orderViews();
  @override
  Future<String> payDeposit({
    required String quoteId,
    String? method,
    String? reference,
  }) async =>
      _s.payDeposit(quoteId);
  @override
  Future<void> payBalance({
    required String orderId,
    String? method,
    String? reference,
  }) async =>
      _s.payBalance(orderId);
  @override
  Future<void> advanceStatus(String orderId, OrderStatus status) async =>
      _s.advanceStatus(orderId, status);
  @override
  Future<Shipment?> getShipment(String orderId) async =>
      _s.shipmentFor(orderId);
  @override
  Future<Shipment> upsertShipment(Shipment shipment) async =>
      _s.upsertShipment(shipment);
}

/// Admin clients en mode demo : un seul client (le profil de demo), avec des
/// compteurs et des paiements reconstitues depuis le DemoStore.
class DemoAdminClientService extends AdminClientService {
  final DemoStore _s;
  DemoAdminClientService(super.client, this._s);

  @override
  Future<List<ClientSummary>> listClients({String? search}) async {
    if (search != null &&
        search.trim().isNotEmpty &&
        !demoProfile.fullName.toLowerCase().contains(search.toLowerCase()) &&
        !demoProfile.whatsapp.contains(search)) {
      return [];
    }
    final orders = _s.orderViews();
    final ordered = orders.fold<num>(0, (sum, o) => sum + o.total);
    final paid = orders.fold<num>(0, (sum, o) {
      var p = 0.0;
      if (o.order.depositPaid) p += o.deposit;
      if (o.order.balancePaid) p += o.balance;
      return sum + p;
    });
    return [
      ClientSummary(
        user: demoProfile,
        vehicleCount: _s.vehiclesFor(DemoStore.clientId).length,
        requestCount: _s.requestsFor(DemoStore.clientId).length,
        orderCount: orders.length,
        totalOrdered: ordered,
        totalPaid: paid,
      ),
    ];
  }

  @override
  Future<List<Vehicle>> clientVehicles(String clientId) async =>
      _s.vehiclesFor(clientId);

  @override
  Future<List<PartsRequest>> clientRequests(String clientId) async =>
      _s.requestsFor(clientId);

  @override
  Future<List<OrderView>> clientOrders(String clientId) async =>
      _s.orderViews();

  /// Le DemoStore ne stocke pas les paiements : on les reconstitue a partir
  /// des drapeaux acompte/solde des commandes.
  @override
  Future<List<Payment>> clientPayments(String clientId) async {
    final out = <Payment>[];
    for (final o in _s.orderViews()) {
      if (o.order.depositPaid) {
        out.add(Payment(
          orderId: o.order.id!,
          type: PaymentType.deposit,
          amount: o.deposit,
          method: 'Wave',
          paidAt: o.order.createdAt,
        ));
      }
      if (o.order.balancePaid) {
        out.add(Payment(
          orderId: o.order.id!,
          type: PaymentType.balance,
          amount: o.balance,
          method: 'Orange Money',
          paidAt: o.order.createdAt,
        ));
      }
    }
    return out;
  }
}

class DemoStorageService extends StorageService {
  DemoStorageService(super.client);
  @override
  Future<String> uploadCarteGrise(String userId, Uint8List bytes,
          {String ext = 'jpg'}) async =>
      'demo://carte-grise';
  @override
  Future<String> uploadPartPhoto(String ownerId, Uint8List bytes,
          {String ext = 'jpg'}) async =>
      'demo://part-photo';
}
