import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/vehicle.dart';
import '../../../providers/vehicle_providers.dart';
import 'vehicle_form_screen.dart';

/// Liste des véhicules du client (Lot 2).
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  void _openForm(BuildContext context, {Vehicle? existing}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VehicleFormScreen(existing: existing),
    ));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(v.label),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok == true && v.id != null) {
      await ref.read(vehicleServiceProvider).delete(v.id!);
      ref.invalidate(myVehiclesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes véhicules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final v = vehicles[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.grisClair,
                    child: Icon(Icons.directions_car, color: AppColors.vert),
                  ),
                  title: Text(v.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    if (v.engine != null) v.engine,
                    if (v.vin != null) 'VIN ${v.vin}',
                    if (v.carteGriseUrl != null) 'Carte grise ✓',
                  ].whereType<String>().join('  •  ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (a) {
                      if (a == 'edit') _openForm(context, existing: v);
                      if (a == 'delete') _confirmDelete(context, ref, v);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                  onTap: () => _openForm(context, existing: v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: AppColors.gris),
            SizedBox(height: 16),
            Text('Aucun véhicule enregistre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              'Ajoutez votre véhicule pour commander des pièces adaptees.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gris),
            ),
          ],
        ),
      ),
    );
  }
}
