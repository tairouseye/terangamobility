import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';

/// Acces CRUD aux vehicules du client (table `vehicles`, protegee par RLS).
class VehicleService {
  final SupabaseClient _client;
  VehicleService(this._client);

  Future<List<Vehicle>> listForUser(String userId) async {
    final rows = await _client
        .from('vehicles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> upsert(Vehicle vehicle) async {
    final row = await _client
        .from('vehicles')
        .upsert(vehicle.toUpsert())
        .select()
        .single();
    return Vehicle.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }
}
