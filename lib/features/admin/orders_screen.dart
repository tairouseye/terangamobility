import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/quote_providers.dart';
import 'order_manage_screen.dart';

/// Admin : liste de toutes les commandes a piloter (Lot 7).
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allOrdersProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.gris),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Aucune commande',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final v = orders[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(v.partName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${v.vehicleLabel}  •  ${Formatters.fcfa(v.total)}'),
                          const SizedBox(height: 6),
                          StatusBadge(v.status),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OrderManageScreen(orderView: v),
                    )),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
