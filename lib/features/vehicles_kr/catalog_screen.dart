import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../shared/app_footer.dart';
import 'vehicle_detail_screen.dart';
import 'widgets/vehicle_filter_sheet.dart';

/// Onglet « Véhicules Corée » : catalogue avec recherche + filtres.
class VehicleCatalogScreen extends ConsumerStatefulWidget {
  const VehicleCatalogScreen({super.key});

  @override
  ConsumerState<VehicleCatalogScreen> createState() =>
      _VehicleCatalogScreenState();
}

class _VehicleCatalogScreenState extends ConsumerState<VehicleCatalogScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applyKeyword(String v) {
    final f = ref.read(vehicleFilterProvider);
    ref.read(vehicleFilterProvider.notifier).state =
        f.copyWith(keyword: v.trim());
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(vehicleListingsProvider);
    final filter = ref.watch(vehicleFilterProvider);
    // Le catalogue est public : un visiteur non connecte peut tout parcourir.
    final isLoggedIn = ref.watch(authServiceProvider).currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules Corée'),
        actions: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Se connecter'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Recherche + bouton filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher (marque, modèle, réf...)',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _search.clear();
                                _applyKeyword('');
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _applyKeyword,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  count: filter.activeCount,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const VehicleFilterSheet(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(vehicleListingsProvider),
              child: listingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Icon(Icons.directions_car_filled_outlined,
                          size: 64, color: AppColors.gris),
                      SizedBox(height: 16),
                      Center(
                          child: Text('Aucun véhicule ne correspond',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600))),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _VehicleCard(vehicle: vehicles[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.primary,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.tune, size: 18),
        label: const Text('Filtres'),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleListing vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VehicleDetailScreen(reference: vehicle.reference),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Photo(vehicle: vehicle),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  if (vehicle.version != null)
                    Text(vehicle.version!,
                        style: const TextStyle(color: AppColors.gris)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (vehicle.mileageLabel != null)
                        _Chip(Icons.speed, vehicle.mileageLabel!),
                      if (vehicle.fuel != null)
                        _Chip(Icons.local_gas_station, vehicle.fuel!),
                      if (vehicle.transmission != null)
                        _Chip(Icons.settings, vehicle.transmission!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ref ${vehicle.reference}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.gris)),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.priceFcfa != null
                                ? Formatters.fcfa(vehicle.priceFcfa)
                                : 'Prix sur demande',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final VehicleListing vehicle;
  const _Photo({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final url = vehicle.photos.isNotEmpty ? vehicle.photos.first : null;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: AppColors.grisClair,
        child: url == null
            ? const Center(
                child: Icon(Icons.directions_car,
                    size: 48, color: AppColors.gris))
            : Image.network(
                url,
                fit: BoxFit.cover,
                // Images externes (Encar) sans en-tete CORS : on affiche
                // directement via un element <img> HTML (pas de fetch bloque).
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.directions_car,
                        size: 48, color: AppColors.gris)),
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.grisClair,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.gris),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
