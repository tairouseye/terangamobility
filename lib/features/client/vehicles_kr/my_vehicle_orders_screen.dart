import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/vehicle_enums.dart';
import '../../../models/vehicle_order.dart';
import '../../../providers/vehicle_catalog_providers.dart';
import '../../../providers/vehicle_order_providers.dart';
import '../../shared/vehicle_timeline.dart';
import 'vehicle_tracking_screen.dart';

/// Client : ses demandes de prix (en attente) et ses commandes véhicule.
class MyVehicleOrdersScreen extends ConsumerWidget {
  const MyVehicleOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myVehicleRequestsProvider);
    final orders = ref.watch(myVehicleOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes véhicules Corée')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myVehicleRequestsProvider);
          ref.invalidate(myVehicleOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Demandes encore en attente de devis
            requests.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                final pending = list
                    .where((r) =>
                        r.status == VehicleRequestStatus.enAttenteDevis)
                    .toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('En attente de devis',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.gris)),
                    const SizedBox(height: 8),
                    ...pending.map((r) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.hourglass_top,
                                color: AppColors.ambre),
                            title: Text(r.vehicleReference),
                            subtitle: Text(
                                'Demande du ${Formatters.date(r.createdAt)}'),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            // Commandes
            const Text('Mes commandes',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.gris)),
            const SizedBox(height: 8),
            orders.when(
              loading: () =>
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Erreur : $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text('Aucune commande véhicule',
                            style: TextStyle(color: AppColors.gris))),
                  );
                }
                return Column(
                  children:
                      list.map((o) => _OrderCard(order: o)).toList(),
                );
              },
            ),
          ],
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
    final needsDeposit =
        order.status == VehicleOrderStatus.enAttenteAcompte && !order.depositPaid;
    final needsBalance =
        order.status == VehicleOrderStatus.arrivePort && !order.balancePaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VehicleTrackingScreen(order: order),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(Formatters.fcfa(order.totalPrice),
                  style: const TextStyle(color: AppColors.gris)),
              const SizedBox(height: 8),
              VehicleStatusBadge(order.status),
              if (needsDeposit || needsBalance) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    needsDeposit
                        ? 'Action : payer l\'acompte de ${Formatters.fcfa(order.depositAmount)}'
                        : 'Action : payer le solde de ${Formatters.fcfa(order.balanceAmount)}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
