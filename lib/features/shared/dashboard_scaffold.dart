import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/notification_providers.dart';
import 'about_screen.dart';
import 'app_footer.dart';
import 'notifications_screen.dart';

/// Ossature commune des dashboards : titre, déconnexion, contenu scrollable.
class DashboardScaffold extends ConsumerWidget {
  final String title;
  final List<Widget> children;
  final Widget? floatingActionButton;
  const DashboardScaffold({
    super.key,
    required this.title,
    required this.children,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _NotifBell(),
          IconButton(
            tooltip: 'A propos & assistance',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: children,
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

/// Cloche de notifications avec badge du nombre de non-lus.
class _NotifBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        ref.invalidate(unreadCountProvider);
      },
    );
  }
}
