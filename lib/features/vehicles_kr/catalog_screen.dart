import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/fb_pixel.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/vehicle_filter.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../shared/app_footer.dart';
import 'alerts_screen.dart';
import 'favorites_screen.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/vehicle_filter_sheet.dart';

/// Onglet « Véhicules Corée » : catalogue avec recherche + filtres + tri.
class VehicleCatalogScreen extends ConsumerStatefulWidget {
  const VehicleCatalogScreen({super.key});

  @override
  ConsumerState<VehicleCatalogScreen> createState() =>
      _VehicleCatalogScreenState();
}

class _VehicleCatalogScreenState extends ConsumerState<VehicleCatalogScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    fbTrack('ViewContent', {
      'content_type': 'vehicle',
      'content_name': 'Catalogue Véhicules Corée',
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Charge la page suivante quand on approche du bas de la liste.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 500) {
      ref.read(vehicleListingsProvider.notifier).loadMore();
    }
  }

  void _applyKeyword(String v) {
    final f = ref.read(vehicleFilterProvider);
    ref.read(vehicleFilterProvider.notifier).state =
        f.copyWith(keyword: v.trim());
  }

  void _applySort(VehicleSort s) {
    final f = ref.read(vehicleFilterProvider);
    ref.read(vehicleFilterProvider.notifier).state = f.copyWith(sort: s);
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(vehicleListingsProvider);
    final filter = ref.watch(vehicleFilterProvider);
    // Le catalogue est public : un visiteur non connecte peut tout parcourir.
    final isLoggedIn = ref.watch(authServiceProvider).currentUser != null;
    final isAdmin =
        ref.watch(currentProfileProvider).valueOrNull?.role == UserRole.admin;
    final favCount = ref.watch(favoriteRefsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules Corée'),
        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'Mes favoris',
              icon: Badge(
                isLabelVisible: favCount > 0,
                label: Text('$favCount'),
                child: const Icon(Icons.favorite),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const FavoritesScreen())),
            ),
          if (isLoggedIn)
            IconButton(
              tooltip: 'Mes alertes',
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AlertsScreen())),
            ),
          PopupMenuButton<VehicleSort>(
            tooltip: 'Trier',
            icon: const Icon(Icons.sort),
            initialValue: filter.sort,
            onSelected: _applySort,
            itemBuilder: (_) => [
              for (final s in VehicleSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
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
                  // Liste PARESSEUSE (ne construit/charge que les cartes
                  // visibles) : indispensable pour la memoire sur mobile —
                  // un Wrap chargerait les ~100 vehicules + images d'un coup
                  // et fait planter Safari iOS. Centree/bornee sur grand ecran.
                  final hasMore =
                      ref.read(vehicleListingsProvider.notifier).hasMore;
                  return LayoutBuilder(
                    builder: (context, cns) {
                      final w = cns.maxWidth;
                      final side = w > 732 ? (w - 700) / 2 : 16.0;
                      return ListView.separated(
                        controller: _scroll,
                        padding: EdgeInsets.fromLTRB(side, 8, side, 20),
                        itemCount: vehicles.length + (hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          if (i >= vehicles.length) {
                            // Pied de liste : indicateur de chargement.
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                ),
                              ),
                            );
                          }
                          return VehicleCard(
                              vehicle: vehicles[i], isAdmin: isAdmin);
                        },
                      );
                    },
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
