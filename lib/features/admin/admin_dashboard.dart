import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../shared/dashboard_scaffold.dart';
import 'quote_requests_screen.dart';
import 'orders_screen.dart';
import 'clients_screen.dart';

/// Espace Admin Teranga Parts (pilotage global).
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return DashboardScaffold(
      title: 'Admin Teranga Parts',
      children: [
        Text('Bonjour ${profile?.fullName ?? ''} 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _AdminTile(
              Icons.people,
              'Clients',
              AppColors.vert,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ClientsScreen(),
              )),
            ),
            _AdminTile(
              Icons.fact_check,
              'Valider devis',
              AppColors.primary,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const QuoteRequestsScreen(),
              )),
            ),
            _AdminTile(
              Icons.inventory_2,
              'Commandes',
              AppColors.ambre,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const OrdersScreen(),
              )),
            ),
            const _AdminTile(Icons.payments, 'Paiements', AppColors.vert),
            const _AdminTile(
                Icons.local_shipping, 'Expeditions', AppColors.anthracite),
            const _AdminTile(Icons.tune, 'Douane & commission', AppColors.gris),
          ],
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _AdminTile(this.icon, this.label, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Module a venir.')),
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
