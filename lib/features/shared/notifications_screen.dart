import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_providers.dart';

/// Centre de notifications (client & admin).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myNotificationsProvider);

    Future<void> refresh() async {
      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadCountProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              await refresh();
            },
            child: const Text('Tout lu'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.notifications_none, size: 64, color: AppColors.gris),
                SizedBox(height: 16),
                Center(
                    child: Text('Aucune notification',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _NotifCard(
                notif: items[i],
                onTap: () async {
                  if (!items[i].isRead) {
                    await ref
                        .read(notificationServiceProvider)
                        .markRead(items[i].id);
                    await refresh();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notif.isRead
          ? null
          : notif.color.withValues(alpha: 0.06),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: notif.color.withValues(alpha: 0.12),
          child: Icon(notif.icon, color: notif.color, size: 20),
        ),
        title: Text(notif.title,
            style: TextStyle(
                fontWeight:
                    notif.isRead ? FontWeight.w600 : FontWeight.w800,
                fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notif.body != null) Text(notif.body!),
            const SizedBox(height: 2),
            Text(Formatters.date(notif.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.gris)),
          ],
        ),
        trailing: notif.isRead
            ? null
            : Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
      ),
    );
  }
}
