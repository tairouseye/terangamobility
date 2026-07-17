import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_quote.dart';
import '../models/order_view.dart';
import '../models/parts_request.dart';
import '../models/shipment.dart';
import '../services/order_service.dart';
import '../services/quote_service.dart';
import 'auth_providers.dart';

final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService(ref.watch(supabaseClientProvider));
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(supabaseClientProvider));
});

/// Admin : demandes pretes a chiffrer (statut piece_trouvee).
final requestsToQuoteProvider = FutureProvider<List<PartsRequest>>((ref) async {
  return ref.watch(quoteServiceProvider).listRequestsToQuote();
});

/// Client : ses devis.
final myQuotesProvider = FutureProvider<List<CustomerQuote>>((ref) async {
  return ref.watch(quoteServiceProvider).listForClient();
});

/// Client : ses commandes (vue enrichie).
final myOrdersProvider = FutureProvider<List<OrderView>>((ref) async {
  return ref.watch(orderServiceProvider).listForClient();
});

/// Admin : toutes les commandes.
final allOrdersProvider = FutureProvider<List<OrderView>>((ref) async {
  return ref.watch(orderServiceProvider).listAll();
});

/// Expedition liee a une commande.
final shipmentProvider =
    FutureProvider.family<Shipment?, String>((ref, orderId) async {
  return ref.watch(orderServiceProvider).getShipment(orderId);
});
