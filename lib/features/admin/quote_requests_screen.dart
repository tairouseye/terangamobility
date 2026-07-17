import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/quote_providers.dart';
import 'build_quote_screen.dart';

/// Admin : demandes ayant une proposition partenaire, a chiffrer (Lot 5).
class QuoteRequestsScreen extends ConsumerWidget {
  const QuoteRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestsToQuoteProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Devis a etablir')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(requestsToQuoteProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.fact_check_outlined,
                      size: 64, color: AppColors.gris),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Aucune demande a chiffrer',
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.grisClair,
                      child: Icon(Icons.build, color: AppColors.primary),
                    ),
                    title: Text(r.partName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${r.vehicleLabel}\nRecue le ${Formatters.date(r.createdAt)}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BuildQuoteScreen(request: r),
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
