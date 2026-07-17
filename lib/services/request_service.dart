import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parts_request.dart';

/// Acces aux demandes de pieces (table `parts_requests`, protegee par RLS).
class RequestService {
  final SupabaseClient _client;
  RequestService(this._client);

  Future<List<PartsRequest>> listForClient(String clientId) async {
    final rows = await _client
        .from('parts_requests')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => PartsRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PartsRequest> create(PartsRequest request) async {
    final row = await _client
        .from('parts_requests')
        .insert(request.toUpsert())
        .select()
        .single();
    return PartsRequest.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('parts_requests').delete().eq('id', id);
  }
}
