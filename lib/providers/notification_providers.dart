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

/// Nombre de notifications non lues (pour le badge de la cloche).
final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationServiceProvider).unreadCount();
});
