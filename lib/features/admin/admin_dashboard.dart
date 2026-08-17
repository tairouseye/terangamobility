import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_counts_providers.dart';
import '../../providers/auth_providers.dart';
import '../shared/dashboard_scaffold.dart';
import '../shared/section_group.dart';
import 'parts_requests_screen.dart';
import 'quote_requests_screen.dart';
import 'orders_screen.dart';
import 'clients_screen.dart';
import 'vehicle_requests_admin_screen.dart';
import 'vehicle_orders_admin_screen.dart';
import '../vehicles_kr/catalog_screen.dart';
import 'facebook_selection_screen.dart';

/// Espace Admin Teranga Parts (pilotage global).
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final counts = ref.watch(adminCountsProvider).valueOrNull;
    final toHandle = counts == null
        ? 0
        : counts.vehicleRequests +
            counts.partsNew +
            counts.partsToQuote;

    return DashboardScaffold(
      title: 'Espace Admin',
      children: [
        Text('Bonjour ${profile?.fullName ?? ''} 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        _Summary(toHandle: toHandle, counts: counts),
        const SizedBox(height: 20),
        SectionGroup(
          color: AppColors.primary,
          icon: Icons.directions_car_filled,
          title: 'Véhicules Corée',
          subtitle: 'Catalogue, demandes, commandes & marketing',
          child: _Grid(children: [
            _AdminTile(
                Icons.directions_car_filled, 'Catalogue véhicules',
                AppColors.primary,
                onTap: () => _go(context, ref, const VehicleCatalogScreen())),
            _AdminTile(
                Icons.request_quote, 'Demandes véhicule', AppColors.ambre,
                badge: counts?.vehicleRequests,
                onTap: () =>
                    _go(context, ref, const VehicleRequestsAdminScreen())),
            _AdminTile(
                Icons.directions_boat, 'Commandes véhicule', AppColors.vert,
                badge: counts?.vehicleOrders,
                badgeInfo: true,
                onTap: () =>
                    _go(context, ref, const VehicleOrdersAdminScreen())),
            _AdminTile(Icons.campaign, 'Sélection Facebook', AppColors.anthracite,
                onTap: () => _go(context, ref, const FacebookSelectionScreen())),
          ]),
        ),
        const SizedBox(height: 16),
        SectionGroup(
          color: AppColors.or,
          icon: Icons.build,
          title: 'Pièces détachées',
          subtitle: 'Demandes, devis, commandes & clients',
          child: _Grid(children: [
            _AdminTile(Icons.search, 'Demandes de pièces', AppColors.primary,
                badge: counts?.partsNew,
                onTap: () => _go(context, ref, const PartsRequestsScreen())),
            _AdminTile(Icons.fact_check, 'Valider devis', AppColors.vert,
                badge: counts?.partsToQuote,
                onTap: () => _go(context, ref, const QuoteRequestsScreen())),
            _AdminTile(Icons.inventory_2, 'Commandes', AppColors.ambre,
                badge: counts?.partsOrders,
                badgeInfo: true,
                onTap: () => _go(context, ref, const OrdersScreen())),
            _AdminTile(Icons.people, 'Clients', AppColors.anthracite,
                badge: counts?.clients,
                badgeInfo: true,
                onTap: () => _go(context, ref, const ClientsScreen())),
          ]),
        ),
      ],
    );
  }

  /// Ouvre un écran puis rafraîchit les compteurs au retour.
  Future<void> _go(BuildContext context, WidgetRef ref, Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));
    ref.invalidate(adminCountsProvider);
  }
}

/// Bandeau de synthèse : nombre total d'éléments à traiter.
class _Summary extends StatelessWidget {
  final int toHandle;
  final AdminCounts? counts;
  const _Summary({required this.toHandle, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts == null) {
      return const Text('Chargement du tableau de bord…',
          style: TextStyle(color: AppColors.gris));
    }
    if (toHandle == 0) {
      return Row(children: const [
        Icon(Icons.check_circle, color: AppColors.vert, size: 18),
        SizedBox(width: 6),
        Expanded(
          child: Text('Tout est à jour — rien en attente de votre part.',
              style: TextStyle(color: AppColors.gris)),
        ),
      ]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ambre.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.pending_actions, color: AppColors.ambre, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$toHandle élément${toHandle > 1 ? 's' : ''} à traiter '
            '(demandes & devis).',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: children,
      );
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  /// Nombre affiché en pastille (null = pas de pastille, 0 = masqué).
  final int? badge;

  /// true = pastille neutre (info : totaux, actives) ; false = pastille
  /// d'alerte (à traiter), en rouge.
  final bool badgeInfo;

  const _AdminTile(this.icon, this.label, this.color,
      {this.onTap, this.badge, this.badgeInfo = false});

  @override
  Widget build(BuildContext context) {
    final showBadge = badge != null && badge! > 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Module à venir.')),
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: showBadge,
              label: showBadge ? Text('${badge!}') : null,
              backgroundColor: badgeInfo ? AppColors.gris : AppColors.danger,
              offset: const Offset(10, -6),
              child: Icon(icon, size: 34, color: color),
            ),
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
