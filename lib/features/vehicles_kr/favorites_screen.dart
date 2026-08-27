import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorites_providers.dart';
import '../shared/app_footer.dart';
import 'widgets/vehicle_card.dart';

/// « Mes favoris » : les véhicules aimés par l'utilisateur connecté.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  bool _available(VehicleListing v) => v.isActive && v.isAvailable;

  Future<void> _removeUnavailable(
      BuildContext context, WidgetRef ref, List<VehicleListing> gone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nettoyer les favoris'),
        content: Text(
            'Retirer ${gone.length} véhicule(s) qui ne sont plus disponibles ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retirer')),
        ],
      ),
    );
    if (ok != true) return;
    final svc = ref.read(favoritesServiceProvider);
    for (final v in gone) {
      await svc.remove(v.reference);
    }
    ref.invalidate(favoriteRefsProvider);
    ref.invalidate(favoriteVehiclesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteVehiclesProvider);
    final isAdmin =
        ref.watch(currentProfileProvider).valueOrNull?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteRefsProvider);
          ref.invalidate(favoriteVehiclesProvider);
          await ref.read(favoriteVehiclesProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: const [
            SizedBox(height: 120),
            Center(
                child: Text('Impossible de charger vos favoris.',
                    style: TextStyle(color: AppColors.gris))),
          ]),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.favorite_border, size: 64, color: AppColors.gris),
                SizedBox(height: 16),
                Center(
                    child: Text('Aucun favori pour le moment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
                SizedBox(height: 8),
                Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                      'Touchez le ❤ sur un véhicule pour le retrouver ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gris)),
                )),
              ]);
            }
            // Disponibles d'abord, indisponibles ensuite (marqués sur la carte).
            final sorted = [...vehicles]..sort((a, b) =>
                (_available(a) ? 0 : 1).compareTo(_available(b) ? 0 : 1));
            final gone = vehicles.where((v) => !_available(v)).toList();

            return LayoutBuilder(
              builder: (context, cns) {
                final w = cns.maxWidth;
                final side = w > 732 ? (w - 700) / 2 : 16.0;
                final hasBanner = gone.isNotEmpty;
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(side, 12, side, 20),
                  itemCount: sorted.length + (hasBanner ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    if (hasBanner && i == 0) {
                      return _UnavailableBanner(
                        count: gone.length,
                        onClean: () => _removeUnavailable(context, ref, gone),
                      );
                    }
                    final v = sorted[i - (hasBanner ? 1 : 0)];
                    return VehicleCard(vehicle: v, isAdmin: isAdmin);
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

/// Bandeau : N favoris ne sont plus disponibles, avec nettoyage en un tap.
class _UnavailableBanner extends StatelessWidget {
  final int count;
  final VoidCallback onClean;
  const _UnavailableBanner({required this.count, required this.onClean});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$count favori(s) ne sont plus disponibles (vendus ou retirés).',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onClean,
          child: const Text('Retirer'),
        ),
      ]),
    );
  }
}
