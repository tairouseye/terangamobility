import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_request.dart';

/// Demandes de prix de vehicules. La creation passe par la fonction serveur
/// `create_vehicle_request` qui insere la demande ET notifie l'admin de maniere
/// atomique (le client n'a pas le droit d'ecrire dans `notifications`).
class VehicleRequestService {
  final SupabaseClient _client;
  VehicleRequestService(this._client);

  Future<String> submit({
    required String vehicleReference,
    required String customerName,
    required String phone,
    String? whatsapp,
    String? email,
    String? country,
    String? city,
    String? message,
  }) async {
    final res = await _client.rpc('create_vehicle_request', params: {
      'p_vehicle_reference': vehicleReference,
      'p_customer_name': customerName,
      'p_phone': phone,
      'p_whatsapp': whatsapp,
      'p_email': email,
      'p_country': country,
      'p_city': city,
      'p_message': message,
    });
    return res as String;
  }

  /// Demandes du client connecte (RLS : les siennes).
  Future<List<VehicleRequest>> listForClient() async {
    final rows = await _client
        .from('vehicle_requests')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => VehicleRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
