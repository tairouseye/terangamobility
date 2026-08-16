import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_listing.dart';

/// Gestion des favoris (« J'aime ») de l'utilisateur connecte.
/// La RLS garantit que chacun ne voit et ne modifie QUE ses propres favoris.
class FavoritesService {
  final SupabaseClient _client;
  FavoritesService(this._client);

  static const _table = 'vehicle_favorites';

  String? get _uid => _client.auth.currentUser?.id;

  /// References des vehicules aimes par l'utilisateur courant.
  Future<Set<String>> myRefs() async {
    if (_uid == null) return <String>{};
    final rows = await _client.from(_table).select('reference');
    return (rows as List)
        .map((e) => (e as Map)['reference'].toString())
        .toSet();
  }

  /// Ajoute un favori (idempotent).
  Future<void> add(String reference) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from(_table).upsert(
      {'reference': reference, 'created_by': uid},
      onConflict: 'reference,created_by',
    );
  }

  /// Retire un favori.
  Future<void> remove(String reference) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from(_table)
        .delete()
        .eq('reference', reference)
        .eq('created_by', uid);
  }

  /// Bascule le favori et renvoie le nouvel etat (true = desormais aime).
  Future<bool> toggle(String reference, bool currentlyLiked) async {
    if (currentlyLiked) {
      await remove(reference);
      return false;
    }
    await add(reference);
    return true;
  }

  /// Vehicules aimes (fiches completes), pour l'ecran « Mes favoris ».
  Future<List<VehicleListing>> myVehicles() async {
    final refs = await myRefs();
    if (refs.isEmpty) return const [];
    final rows = await _client
        .from('vehicle_listings')
        .select()
        .inFilter('reference', refs.toList());
    return (rows as List)
        .map((e) => VehicleListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
