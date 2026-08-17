import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

/// Notifications de l'utilisateur connecte. La RLS renvoie automatiquement
/// les bonnes lignes : celles adressees au client (user_id) et, pour l'admin,
/// celles ciblant le role 'admin'.
class NotificationService {
  final SupabaseClient _client;
  NotificationService(this._client);

  Future<List<AppNotification>> list() async {
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('is_read', false);
    return (rows as List).length;
  }

  /// Flux TEMPS RÉEL du nombre de non-lues (badge de la cloche). La RLS limite
  /// le flux aux notifications de l'utilisateur (ou du rôle admin). Émet une
  /// valeur initiale immédiate puis se met à jour à chaque changement.
  Stream<int> unreadCountStream() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((rows) => rows.length);
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('is_read', false);
  }
}
