import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_quote.dart';
import '../models/parts_request.dart';
import '../models/quote_breakdown.dart';

/// Gestion des devis client (chiffrage serveur + envoi + consultation).
class QuoteService {
  final SupabaseClient _client;
  QuoteService(this._client);

  /// Appelle la fonction serveur non falsifiable pour chiffrer un devis.
  Future<QuoteBreakdown> compute({
    required String supplierQuoteId,
    String customsCategory = 'general',
  }) async {
    final res = await _client.rpc('compute_customer_quote', params: {
      'p_supplier_quote_id': supplierQuoteId,
      'p_customs_category': customsCategory,
    });
    // La fonction renvoie une table -> liste d'une ligne.
    final row = (res is List && res.isNotEmpty)
        ? res.first as Map<String, dynamic>
        : res as Map<String, dynamic>;
    return QuoteBreakdown.fromRpc(row);
  }

  /// Cree le devis client et fait passer la demande a 'devis_envoye' (admin).
  Future<CustomerQuote> sendQuote({
    required String requestId,
    required String supplierQuoteId,
    required QuoteBreakdown b,
    DateTime? validUntil,
  }) async {
    final inserted = await _client
        .from('customer_quotes')
        .insert({
          'request_id': requestId,
          'supplier_quote_id': supplierQuoteId,
          'part_price': b.partPrice,
          'fedex_cost': b.fedexCost,
          'customs_cost': b.customsCost,
          'commission': b.commission,
          'total_fcfa': b.total,
          'status': 'sent',
          if (validUntil != null)
            'valid_until': validUntil.toIso8601String().split('T').first,
        })
        .select()
        .single();

    await _client
        .from('parts_requests')
        .update({'status': 'devis_envoye'}).eq('id', requestId);

    return CustomerQuote.fromJson(inserted);
  }

  /// Demandes pretes a chiffrer (une proposition partenaire recue).
  Future<List<PartsRequest>> listRequestsToQuote() async {
    final rows = await _client
        .from('parts_requests')
        .select()
        .eq('status', 'piece_trouvee')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PartsRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devis d'un client (RLS : uniquement les siens).
  Future<List<CustomerQuote>> listForClient() async {
    final rows = await _client
        .from('customer_quotes')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => CustomerQuote.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
