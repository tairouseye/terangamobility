import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/parts_request.dart';
import '../../providers/partner_providers.dart';
import 'propose_part_screen.dart';

/// Inbox du partenaire Corée : demandes ouvertes a traiter (Lot 4).
class RequestsInboxScreen extends ConsumerWidget {
  const RequestsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes a traiter')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(openRequestsProvider),
        child: requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.gris),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Aucune demande a traiter',
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
              itemBuilder: (context, i) =>
                  _RequestCard(request: requests[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PartsRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProposePartScreen(request: request),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(request.partName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  StatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.directions_car,
                    size: 16, color: AppColors.gris),
                const SizedBox(width: 6),
                Expanded(child: Text(request.vehicleLabel)),
              ]),
              if (request.vehicleVin != null) ...[
                const SizedBox(height: 4),
                Text('VIN ${request.vehicleVin}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reçue le ${Formatters.date(request.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gris)),
                  const Row(children: [
                    Text('Proposer',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: AppColors.primary),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
