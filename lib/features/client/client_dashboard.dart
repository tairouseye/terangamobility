import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../shared/dashboard_scaffold.dart';
import 'vehicles/vehicles_screen.dart';
import 'requests/new_request_screen.dart';
import 'requests/requests_screen.dart';
import 'quotes/my_quotes_screen.dart';
import 'orders/my_orders_screen.dart';
import '../vehicles_kr/catalog_screen.dart';
import 'vehicles_kr/my_vehicle_orders_screen.dart';

/// Espace Client : options présentées en tuiles.
class ClientDashboard extends ConsumerWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return DashboardScaffold(
      title: 'Espace Client',
      children: [
        Text('Bonjour ${profile?.fullName ?? ''} 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Commandez vos pièces et véhicules coréens en toute confiance.',
            style: TextStyle(color: AppColors.gris)),
        const SizedBox(height: 20),
        // Mise en avant : catalogue véhicules.
        _FeatureBanner(
          onTap: () => _go(context, const VehicleCatalogScreen()),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Véhicules Corée'),
        _Tiles(items: [
          _TileData(Icons.directions_car_filled, 'Catalogue véhicules',
              AppColors.primary, () => _go(context, const VehicleCatalogScreen())),
          _TileData(Icons.directions_boat, 'Mes commandes véhicule',
              AppColors.ambre, () => _go(context, const MyVehicleOrdersScreen())),
        ]),
        const SizedBox(height: 20),
        const _SectionLabel('Pièces détachées'),
        _Tiles(items: [
          _TileData(Icons.add_shopping_cart, 'Nouvelle demande',
              AppColors.primary, () => _go(context, const NewRequestScreen())),
          _TileData(Icons.inventory_2, 'Mes demandes', AppColors.ambre,
              () => _go(context, const RequestsScreen())),
          _TileData(Icons.receipt_long, 'Mes devis', AppColors.vert,
              () => _go(context, const MyQuotesScreen())),
          _TileData(Icons.local_shipping, 'Suivi commandes',
              AppColors.anthracite, () => _go(context, const MyOrdersScreen())),
          _TileData(Icons.directions_car, 'Mes véhicules', AppColors.vert,
              () => _go(context, const VehiclesScreen())),
        ]),
      ],
    );
  }

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.gris)),
      );
}

class _TileData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _TileData(this.icon, this.title, this.color, this.onTap);
}

/// Grille de tuiles responsive (2 colonnes sur téléphone, 3 sur large).
class _Tiles extends StatelessWidget {
  final List<_TileData> items;
  const _Tiles({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 520 ? 3 : 2;
        final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final it in items)
              SizedBox(
                width: tileW,
                height: 118,
                child: _Tile(data: it),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final _TileData data;
  const _Tile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 26),
              ),
              const Spacer(),
              Text(data.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banniere mise en avant : import de véhicules depuis la Corée.
class _FeatureBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _FeatureBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_filled,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Véhicules Corée',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Réservez votre véhicule directement de Corée',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
