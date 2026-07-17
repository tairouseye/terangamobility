import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parts_request.dart';
import '../models/supplier_quote.dart';

/// Acces cote partenaire Coree : demandes a traiter + propositions de pieces.
class SupplierQuoteService {
  final SupabaseClient _client;
  SupplierQuoteService(this._client);

  /// Demandes ouvertes visibles par le partenaire (en amont du devis).
  Future<List<PartsRequest>> listOpenRequests() async {
    final rows = await _client
        .from('parts_requests')
        .select()
        .inFilter('status',
            ['nouvelle_demande', 'recherche_coree', 'piece_trouvee'])
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PartsRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Propositions deja soumises par le partenaire pour une demande.
  Future<List<SupplierQuote>> listQuotesForRequest(String requestId) async {
    final rows = await _client
        .from('suppliers_quotes')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => SupplierQuote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierQuote> submit(SupplierQuote quote) async {
    final row = await _client
        .from('suppliers_quotes')
        .insert(quote.toUpsert())
        .select()
        .single();
    return SupplierQuote.fromJson(row);
  }
}
