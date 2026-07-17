import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/request_providers.dart';
import 'new_request_screen.dart';

/// Liste des demandes du client avec leur statut (Lot 3).
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes & devis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const NewRequestScreen(),
        )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Demande'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myRequestsProvider),
        child: requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.gris),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Aucune demande pour le moment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = requests[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(r.partName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                            StatusBadge(r.status),
                          ],
                        ),
                        if (r.notes != null) ...[
                          const SizedBox(height: 6),
                          Text(r.notes!,
                              style: const TextStyle(color: AppColors.gris)),
                        ],
                        const SizedBox(height: 8),
                        Text('Demande du ${Formatters.date(r.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gris)),
                      ],
                    ),
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
