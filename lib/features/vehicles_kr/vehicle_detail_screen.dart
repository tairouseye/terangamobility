import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/encar_image.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import 'request_price_screen.dart';
import 'widgets/customs_terms_notice.dart';

/// Fiche detaillee d'un véhicule. Le prix n'est jamais affiche : un bouton
/// « Demander le prix » ouvre le formulaire de demande.
class VehicleDetailScreen extends ConsumerWidget {
  final String reference;
  const VehicleDetailScreen({super.key, required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehicleByRefProvider(reference));
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche véhicule')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (v) {
          if (v == null) {
            return const Center(child: Text('Véhicule introuvable'));
          }
          return _Detail(vehicle: v);
        },
      ),
      bottomNavigationBar: async.valueOrNull == null
          ? null
          : _PriceCta(vehicle: async.value!),
    );
  }
}

/// Bouton « Demander le prix ». C'est ici — et seulement ici — qu'un compte
/// devient necessaire : la consultation du catalogue reste libre.
class _PriceCta extends ConsumerWidget {
  final VehicleListing vehicle;
  const _PriceCta({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authServiceProvider).currentUser != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLoggedIn)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Créez un compte en 1 minute pour lancer votre commande.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.gris),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                if (isLoggedIn) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RequestPriceScreen(vehicle: vehicle),
                  ));
                } else {
                  context.push('/login');
                }
              },
              icon: Icon(isLoggedIn ? Icons.directions_car : Icons.login),
              label: Text(isLoggedIn
                  ? 'Commander ce véhicule'
                  : 'Se connecter pour commander'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final VehicleListing vehicle;
  const _Detail({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Gallery(photos: vehicle.photos),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              if (vehicle.version != null)
                Text(vehicle.version!,
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 15)),
              const SizedBox(height: 12),
              // Prix affiche (converti depuis le prix coréen + marge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vehicle.priceFcfa != null
                        ? Formatters.fcfa(vehicle.priceFcfa)
                        : 'Prix sur demande',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('tout compris (hors dédouanement)',
                        style: TextStyle(fontSize: 11, color: AppColors.gris)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CustomsTermsNotice(),
              const SizedBox(height: 20),
              const Text('Caractéristiques',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _SpecGrid(vehicle: vehicle),
              if (vehicle.options.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Options',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vehicle.options
                      .map((o) => Chip(
                            label: Text(o),
                            backgroundColor: AppColors.grisClair,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
              if (vehicle.description != null &&
                  vehicle.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Description',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(vehicle.description!,
                    style: const TextStyle(height: 1.5)),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecGrid extends StatelessWidget {
  final VehicleListing vehicle;
  const _SpecGrid({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final specs = <(String, String?)>[
      ('Marque', v.brand),
      ('Modèle', v.model),
      ('Année', v.year?.toString()),
      ('Version', v.version),
      ('Motorisation', v.engine),
      ('Cylindrée', v.displacement),
      ('Kilométrage', v.mileageLabel),
      ('Transmission', v.transmission),
      ('Carburant', v.fuel),
      ('Couleur', v.color),
      ('Portes', v.doors?.toString()),
      ('Volant', v.steeringLabel),
      ('Localisation', v.location),
      ('Référence', v.reference),
      ('État', v.condition),
    ].where((e) => e.$2 != null && e.$2!.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < specs.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == specs.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF0F1F3))),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(specs[i].$1,
                        style: const TextStyle(
                            color: AppColors.gris, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(specs[i].$2!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<String> photos;
  const _Gallery({required this.photos});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: AppColors.grisClair,
          child: const Center(
              child: Icon(Icons.directions_car,
                  size: 64, color: AppColors.gris)),
        ),
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _img(
                    // Image principale : haute qualite (recadrage 16:10).
                    encarPhoto(widget.photos[i], height: 900, ratio: 16 / 10),
                    BoxFit.cover),
              ),
              if (widget.photos.length > 1)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.photos.length,
                      (i) => Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              i == _index ? AppColors.primary : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Bande de miniatures (les 4 photos visibles d'un coup).
        if (widget.photos.length > 1)
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _controller.animateToPage(i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut);
                },
                child: Container(
                  width: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == _index
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Miniature : petite version (bande sous la galerie).
                  child: _img(
                      encarPhoto(widget.photos[i], height: 200, ratio: 16 / 10),
                      BoxFit.cover),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _img(String url, BoxFit fit) => Container(
        color: AppColors.grisClair,
        child: Image.network(
          url,
          fit: fit,
          // Images externes (Encar) sans CORS : rendu direct via <img> HTML.
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image, size: 32, color: AppColors.gris)),
          loadingBuilder: (c, child, p) => p == null
              ? child
              : const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
}
