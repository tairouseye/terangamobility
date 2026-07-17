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

/// Espace Client (Lot 2+ : vehicules, demandes, devis, paiement, suivi).
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
        const Text('Commandez vos pièces coréennes en toute confiance.',
            style: TextStyle(color: AppColors.gris)),
        const SizedBox(height: 24),
        // --- Nouveau : import de vehicules depuis la Coree ---
        _FeatureBanner(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const VehicleCatalogScreen(),
          )),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.directions_boat,
          color: AppColors.primary,
          title: 'Mes commandes véhicule',
          subtitle: 'Devis, acompte, suivi maritime',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const MyVehicleOrdersScreen(),
          )),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 4),
          child: Text('Pièces détachées',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.gris)),
        ),
        _MenuCard(
          icon: Icons.directions_car,
          color: AppColors.vert,
          title: 'Mes vehicules',
          subtitle: 'Enregistrer marque, modele, VIN, carte grise',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const VehiclesScreen(),
          )),
        ),
        _MenuCard(
          icon: Icons.add_shopping_cart,
          color: AppColors.primary,
          title: 'Nouvelle demande de piece',
          subtitle: 'Decrivez la piece recherchee + photo',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NewRequestScreen(),
          )),
        ),
        _MenuCard(
          icon: Icons.inventory_2,
          color: AppColors.ambre,
          title: 'Mes demandes',
          subtitle: 'Suivre l\'etat de mes demandes de pieces',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const RequestsScreen(),
          )),
        ),
        _MenuCard(
          icon: Icons.receipt_long,
          color: AppColors.vert,
          title: 'Mes devis',
          subtitle: 'Consulter, valider et payer l\'acompte (70%)',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const MyQuotesScreen(),
          )),
        ),
        _MenuCard(
          icon: Icons.local_shipping,
          color: AppColors.anthracite,
          title: 'Suivi de mes commandes',
          subtitle: 'Suivre les 13 etapes jusqu\'a la livraison',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const MyOrdersScreen(),
          )),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Disponible dans le prochain lot.')),
                ),
      ),
    );
  }
}

/// Banniere mise en avant : import de vehicules depuis la Coree.
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
                    Text('Commandez votre véhicule directement de Corée',
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
