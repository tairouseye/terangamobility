import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_order.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../../providers/vehicle_order_providers.dart';
import '../shared/vehicle_timeline.dart';
import 'vehicle_order_manage_screen.dart';

/// Admin : liste des commandes vehicule.
class VehicleOrdersAdminScreen extends ConsumerWidget {
  const VehicleOrdersAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehicleOrdersAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes vehicule')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vehicleOrdersAdminProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.directions_boat_outlined,
                    size: 64, color: AppColors.gris),
                SizedBox(height: 16),
                Center(
                    child: Text('Aucune commande vehicule',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final VehicleOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleByRefProvider(order.vehicleReference));
    final title = vehicle.valueOrNull?.title ?? order.vehicleReference;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Formatters.fcfa(order.totalPrice)),
              const SizedBox(height: 6),
              VehicleStatusBadge(order.status),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VehicleOrderManageScreen(order: order),
        )),
      ),
    );
  }
}
