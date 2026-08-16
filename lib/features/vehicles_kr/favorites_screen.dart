import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorites_providers.dart';
import '../shared/app_footer.dart';
import 'widgets/vehicle_card.dart';

/// « Mes favoris » : les véhicules aimés par l'utilisateur connecté.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

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
            return LayoutBuilder(
              builder: (context, cns) {
                final w = cns.maxWidth;
                final side = w > 732 ? (w - 700) / 2 : 16.0;
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(side, 12, side, 20),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) =>
                      VehicleCard(vehicle: vehicles[i], isAdmin: isAdmin),
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
