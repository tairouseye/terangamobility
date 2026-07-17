import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parts_request.dart';
import '../models/supplier_quote.dart';
import '../services/supplier_quote_service.dart';
import 'auth_providers.dart';

final supplierQuoteServiceProvider = Provider<SupplierQuoteService>((ref) {
  return SupplierQuoteService(ref.watch(supabaseClientProvider));
});

/// Demandes ouvertes a traiter par le partenaire Coree.
final openRequestsProvider = FutureProvider<List<PartsRequest>>((ref) async {
  return ref.watch(supplierQuoteServiceProvider).listOpenRequests();
});

/// Propositions deja soumises pour une demande donnee.
final quotesForRequestProvider =
    FutureProvider.family<List<SupplierQuote>, String>((ref, requestId) async {
  return ref.watch(supplierQuoteServiceProvider).listQuotesForRequest(requestId);
});
