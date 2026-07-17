import '../models/customer_quote.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/order_view.dart';
import '../models/parts_request.dart';
import '../models/shipment.dart';
import '../models/supplier_quote.dart';
import '../models/vehicle.dart';

/// Magasin de donnees en memoire pour le MODE DEMO (aucun reseau, aucun
/// Supabase). Reproduit un jeu de donnees realiste et supporte les
/// mutations (ajout vehicule, demande, devis, paiement...) pour que la
/// navigation soit reellement cliquable.
class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  static const clientId = 'demo-client';
  static const partnerId = 'demo-partner';

  int _seq = 100;
  String _id(String prefix) => '$prefix-${_seq++}';

  final List<Vehicle> vehicles = [];
  final List<PartsRequest> requests = [];
  final List<SupplierQuote> supplierQuotes = [];
  final List<CustomerQuote> customerQuotes = [];
  final List<Order> orders = [];
  final Map<String, Shipment> shipments = {};

  bool _seeded = false;

  /// Remplit le magasin avec un scenario complet couvrant tous les ecrans.
  void seed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime(2026, 7, 10, 9, 30);

    // --- Vehicules ---
    final tucson = Vehicle(
      id: 'veh-tucson',
      userId: clientId,
      brand: 'Hyundai',
      model: 'Tucson',
      year: 2018,
      engine: '2.0 CRDi',
      vin: 'KMHJ281ADHU123456',
      carteGriseUrl: 'demo://carte-grise',
      createdAt: now.subtract(const Duration(days: 40)),
    );
    final sportage = Vehicle(
      id: 'veh-sportage',
      userId: clientId,
      brand: 'Kia',
      model: 'Sportage',
      year: 2020,
      engine: 'Essence',
      vin: 'KNAPM81BDL7654321',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    vehicles.addAll([tucson, sportage]);

    // Helper pour figer l'instantane vehicule dans une demande.
    PartsRequest req({
      required String id,
      required Vehicle v,
      required String part,
      required OrderStatus status,
      String? notes,
      required int daysAgo,
    }) =>
        PartsRequest(
          id: id,
          clientId: clientId,
          vehicleId: v.id,
          partName: part,
          notes: notes,
          status: status,
          vehicleBrand: v.brand,
          vehicleModel: v.model,
          vehicleYear: v.year,
          vehicleEngine: v.engine,
          vehicleVin: v.vin,
          createdAt: now.subtract(Duration(days: daysAgo)),
        );

    // --- Demandes couvrant chaque etape du workflow ---
    final r1 = req(
        id: 'req-plaquettes',
        v: tucson,
        part: 'Plaquettes de frein avant',
        status: OrderStatus.commandeConfirmee,
        notes: 'Origine, cote conducteur',
        daysAgo: 12);
    final r2 = req(
        id: 'req-retroviseur',
        v: sportage,
        part: 'Retroviseur droit',
        status: OrderStatus.pieceTrouvee,
        notes: 'Avec clignotant integre',
        daysAgo: 5);
    final r3 = req(
        id: 'req-filtre',
        v: tucson,
        part: 'Filtre a air',
        status: OrderStatus.nouvelleDemande,
        daysAgo: 1);
    final r4 = req(
        id: 'req-embrayage',
        v: tucson,
        part: 'Kit d\'embrayage',
        status: OrderStatus.devisEnvoye,
        daysAgo: 3);
    final r5 = req(
        id: 'req-amortisseur',
        v: sportage,
        part: 'Amortisseur arriere',
        status: OrderStatus.soldeDemande,
        daysAgo: 18);
    requests.addAll([r1, r2, r3, r4, r5]);

    // --- Propositions partenaire ---
    supplierQuotes.addAll([
      SupplierQuote(
        id: 'sq-plaquettes',
        requestId: r1.id!,
        partnerId: partnerId,
        partRef: '58101-D3A00',
        buyPriceKrw: 150000,
        weightKg: 3.0,
        dimensions: '20 x 12 x 6 cm',
        leadTimeDays: 7,
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      SupplierQuote(
        id: 'sq-retroviseur',
        requestId: r2.id!,
        partnerId: partnerId,
        partRef: '87620-F1000',
        buyPriceKrw: 210000,
        weightKg: 1.8,
        dimensions: '25 x 18 x 12 cm',
        leadTimeDays: 10,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      SupplierQuote(
        id: 'sq-embrayage',
        requestId: r4.id!,
        partnerId: partnerId,
        partRef: '41200-3D000',
        buyPriceKrw: 320000,
        weightKg: 8.5,
        leadTimeDays: 14,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      SupplierQuote(
        id: 'sq-amortisseur',
        requestId: r5.id!,
        partnerId: partnerId,
        partRef: '55311-D9000',
        buyPriceKrw: 180000,
        weightKg: 4.0,
        leadTimeDays: 9,
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ]);

    // --- Devis client ---
    CustomerQuote cq({
      required String id,
      required String requestId,
      required String sqId,
      required num part,
      required num fedex,
      required num customs,
      required num commission,
      required String status,
    }) =>
        CustomerQuote(
          id: id,
          requestId: requestId,
          supplierQuoteId: sqId,
          partPrice: part,
          fedexCost: fedex,
          customsCost: customs,
          commission: commission,
          totalFcfa: part + fedex + customs + commission,
          status: status,
          validUntil: now.add(const Duration(days: 7)),
          createdAt: now.subtract(const Duration(days: 2)),
        );

    final cqPlaquettes = cq(
        id: 'cq-plaquettes',
        requestId: r1.id!,
        sqId: 'sq-plaquettes',
        part: 97500,
        fedex: 27000,
        customs: 24900,
        commission: 22410,
        status: 'accepted');
    final cqEmbrayage = cq(
        id: 'cq-embrayage',
        requestId: r4.id!,
        sqId: 'sq-embrayage',
        part: 208000,
        fedex: 76500,
        customs: 56900,
        commission: 51210,
        status: 'sent');
    final cqAmortisseur = cq(
        id: 'cq-amortisseur',
        requestId: r5.id!,
        sqId: 'sq-amortisseur',
        part: 117000,
        fedex: 36000,
        customs: 30600,
        commission: 27540,
        status: 'accepted');
    customerQuotes.addAll([cqPlaquettes, cqEmbrayage, cqAmortisseur]);

    // --- Commandes ---
    orders.addAll([
      Order(
        id: 'ord-plaquettes',
        quoteId: cqPlaquettes.id!,
        clientId: clientId,
        status: OrderStatus.commandeConfirmee,
        depositPaid: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Order(
        id: 'ord-amortisseur',
        quoteId: cqAmortisseur.id!,
        clientId: clientId,
        status: OrderStatus.soldeDemande,
        depositPaid: true,
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ]);

    shipments['ord-amortisseur'] = Shipment(
      id: 'shp-amortisseur',
      orderId: 'ord-amortisseur',
      fedexTracking: '7712 3456 7890',
      transitaire: 'Dakar Transit SARL',
      eta: now.add(const Duration(days: 4)),
    );
  }

  // ---- Lectures ----
  List<Vehicle> vehiclesFor(String userId) =>
      vehicles.where((v) => v.userId == userId).toList().reversed.toList();

  List<PartsRequest> requestsFor(String clientId) =>
      requests.where((r) => r.clientId == clientId).toList().reversed.toList();

  List<PartsRequest> openRequests() => requests
      .where((r) => {
            OrderStatus.nouvelleDemande,
            OrderStatus.rechercheCoree,
            OrderStatus.pieceTrouvee
          }.contains(r.status))
      .toList()
      .reversed
      .toList();

  List<PartsRequest> requestsToQuote() =>
      requests.where((r) => r.status == OrderStatus.pieceTrouvee).toList();

  List<SupplierQuote> quotesForRequest(String requestId) =>
      supplierQuotes.where((q) => q.requestId == requestId).toList();

  List<CustomerQuote> quotesForClient() =>
      customerQuotes.toList().reversed.toList();

  List<OrderView> orderViews() =>
      orders.reversed.map(_toView).toList();

  Shipment? shipmentFor(String orderId) => shipments[orderId];

  OrderView _toView(Order o) {
    final q = customerQuotes.firstWhere((c) => c.id == o.quoteId);
    final r = requests.firstWhere((r) => r.id == q.requestId);
    return OrderView(
      order: o,
      partName: r.partName,
      vehicleLabel: r.vehicleLabel,
      total: q.totalFcfa,
    );
  }

  // ---- Ecritures ----
  Vehicle upsertVehicle(Vehicle v) {
    final withId = v.id != null ? v : _withVehicleId(v);
    final idx = vehicles.indexWhere((e) => e.id == withId.id);
    if (idx >= 0) {
      vehicles[idx] = withId;
    } else {
      vehicles.add(withId);
    }
    return withId;
  }

  Vehicle _withVehicleId(Vehicle v) => Vehicle(
        id: _id('veh'),
        userId: v.userId,
        brand: v.brand,
        model: v.model,
        year: v.year,
        engine: v.engine,
        vin: v.vin,
        carteGriseUrl: v.carteGriseUrl,
        createdAt: DateTime.now(),
      );

  void deleteVehicle(String id) => vehicles.removeWhere((v) => v.id == id);

  PartsRequest createRequest(PartsRequest r) {
    final withId = PartsRequest(
      id: _id('req'),
      clientId: r.clientId,
      vehicleId: r.vehicleId,
      partName: r.partName,
      partPhotoUrl: r.partPhotoUrl,
      notes: r.notes,
      status: OrderStatus.nouvelleDemande,
      vehicleBrand: r.vehicleBrand,
      vehicleModel: r.vehicleModel,
      vehicleYear: r.vehicleYear,
      vehicleEngine: r.vehicleEngine,
      vehicleVin: r.vehicleVin,
      createdAt: DateTime.now(),
    );
    requests.add(withId);
    return withId;
  }

  SupplierQuote submitSupplierQuote(SupplierQuote q) {
    final withId = SupplierQuote(
      id: _id('sq'),
      requestId: q.requestId,
      partnerId: q.partnerId,
      partRef: q.partRef,
      available: q.available,
      buyPriceKrw: q.buyPriceKrw,
      weightKg: q.weightKg,
      dimensions: q.dimensions,
      photoUrl: q.photoUrl,
      leadTimeDays: q.leadTimeDays,
      createdAt: DateTime.now(),
    );
    supplierQuotes.add(withId);
    _setRequestStatus(q.requestId, OrderStatus.pieceTrouvee,
        onlyIfBefore: OrderStatus.pieceTrouvee);
    return withId;
  }

  CustomerQuote sendCustomerQuote(CustomerQuote q) {
    final withId = CustomerQuote(
      id: _id('cq'),
      requestId: q.requestId,
      supplierQuoteId: q.supplierQuoteId,
      partPrice: q.partPrice,
      fedexCost: q.fedexCost,
      customsCost: q.customsCost,
      commission: q.commission,
      totalFcfa: q.totalFcfa,
      status: 'sent',
      validUntil: q.validUntil,
      createdAt: DateTime.now(),
    );
    customerQuotes.add(withId);
    _setRequestStatus(q.requestId, OrderStatus.devisEnvoye);
    return withId;
  }

  String payDeposit(String quoteId) {
    final q = customerQuotes.firstWhere((c) => c.id == quoteId);
    final idx = customerQuotes.indexOf(q);
    customerQuotes[idx] = _copyQuoteStatus(q, 'accepted');
    _setRequestStatus(q.requestId, OrderStatus.acomptePaye);
    final order = Order(
      id: _id('ord'),
      quoteId: quoteId,
      clientId: clientId,
      status: OrderStatus.acomptePaye,
      depositPaid: true,
      createdAt: DateTime.now(),
    );
    orders.add(order);
    return order.id!;
  }

  void payBalance(String orderId) {
    _updateOrder(orderId,
        (o) => _copyOrder(o, status: OrderStatus.payee, balancePaid: true));
  }

  void advanceStatus(String orderId, OrderStatus status) {
    _updateOrder(orderId, (o) => _copyOrder(o, status: status));
  }

  Shipment upsertShipment(Shipment s) {
    final withId = Shipment(
      id: shipments[s.orderId]?.id ?? _id('shp'),
      orderId: s.orderId,
      fedexTracking: s.fedexTracking,
      transitaire: s.transitaire,
      eta: s.eta,
      currentStep: s.currentStep,
      createdAt: DateTime.now(),
    );
    shipments[s.orderId] = withId;
    return withId;
  }

  // ---- Helpers internes ----
  void _setRequestStatus(String id, OrderStatus status,
      {OrderStatus? onlyIfBefore}) {
    final idx = requests.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final r = requests[idx];
    if (onlyIfBefore != null && r.status.index >= onlyIfBefore.index) return;
    requests[idx] = PartsRequest(
      id: r.id,
      clientId: r.clientId,
      vehicleId: r.vehicleId,
      partName: r.partName,
      partPhotoUrl: r.partPhotoUrl,
      notes: r.notes,
      status: status,
      vehicleBrand: r.vehicleBrand,
      vehicleModel: r.vehicleModel,
      vehicleYear: r.vehicleYear,
      vehicleEngine: r.vehicleEngine,
      vehicleVin: r.vehicleVin,
      createdAt: r.createdAt,
    );
  }

  void _updateOrder(String id, Order Function(Order) f) {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx >= 0) orders[idx] = f(orders[idx]);
  }

  Order _copyOrder(Order o, {OrderStatus? status, bool? balancePaid}) => Order(
        id: o.id,
        quoteId: o.quoteId,
        clientId: o.clientId,
        status: status ?? o.status,
        depositPaid: o.depositPaid,
        balancePaid: balancePaid ?? o.balancePaid,
        createdAt: o.createdAt,
      );

  CustomerQuote _copyQuoteStatus(CustomerQuote q, String status) =>
      CustomerQuote(
        id: q.id,
        requestId: q.requestId,
        supplierQuoteId: q.supplierQuoteId,
        partPrice: q.partPrice,
        fedexCost: q.fedexCost,
        customsCost: q.customsCost,
        commission: q.commission,
        totalFcfa: q.totalFcfa,
        status: status,
        validUntil: q.validUntil,
        createdAt: q.createdAt,
      );
}
