import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'auth_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(supabaseClientProvider));
});

final myNotificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationServiceProvider).list();
});

/// Nombre de notifications non lues (badge de la cloche), EN TEMPS RÉEL.
/// Se met à jour tout seul à l'arrivée d'une notification ou au passage en
/// « lu ». Rebranché à chaque changement d'auth (connexion/déconnexion).
final unreadCountProvider = StreamProvider<int>((ref) {
  ref.watch(authStateProvider);
  final loggedIn = ref.watch(authServiceProvider).currentUser != null;
  if (!loggedIn) return Stream<int>.value(0);
  return ref.watch(notificationServiceProvider).unreadCountStream();
});
