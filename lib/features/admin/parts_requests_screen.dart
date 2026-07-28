import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/quote_providers.dart';
import 'source_part_screen.dart';

/// Admin : demandes de pièces à sourcer (nouvelle / recherche).
class PartsRequestsScreen extends ConsumerWidget {
  const PartsRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newPartsRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de pièces')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(newPartsRequestsProvider),
        child: async.when(
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
                    child: Text('Aucune demande à sourcer',
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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.grisClair,
                      child: Icon(Icons.search, color: AppColors.primary),
                    ),
                    title: Text(r.partName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${r.vehicleLabel}\nReçue le ${Formatters.date(r.createdAt)}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SourcePartScreen(request: r),
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
