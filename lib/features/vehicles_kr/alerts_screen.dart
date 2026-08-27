import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/alerts_providers.dart';
import '../shared/app_footer.dart';

/// « Mes alertes » : les recherches enregistrées (« Prévenez-moi »).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAlertsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes alertes')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
            child: Text('Impossible de charger vos alertes.',
                style: TextStyle(color: AppColors.gris))),
        data: (alerts) {
          if (alerts.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 100),
              Icon(Icons.notifications_none, size: 64, color: AppColors.gris),
              SizedBox(height: 16),
              Center(
                  child: Text('Aucune alerte',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                    'Dans le catalogue, réglez vos filtres puis touchez '
                    '« M\'alerter pour cette recherche ». Vous serez prévenu '
                    'dès qu\'un véhicule correspondant arrive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gris)),
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = alerts[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.grisClair,
                    child: Icon(Icons.notifications_active,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(a.display,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Vous serez prévenu des nouveautés',
                      style: TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: () async {
                      await ref.read(alertsServiceProvider).remove(a.id);
                      ref.invalidate(myAlertsProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
