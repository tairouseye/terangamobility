import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import 'about_screen.dart';
import 'app_footer.dart';

/// Ossature commune des dashboards : titre, deconnexion, contenu scrollable.
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
          IconButton(
            tooltip: 'A propos & assistance',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Se deconnecter',
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
