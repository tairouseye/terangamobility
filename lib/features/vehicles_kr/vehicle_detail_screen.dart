import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/auth_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import 'request_price_screen.dart';
import 'widgets/customs_terms_notice.dart';

/// Fiche detaillee d'un vehicule. Le prix n'est jamais affiche : un bouton
/// « Demander le prix » ouvre le formulaire de demande.
class VehicleDetailScreen extends ConsumerWidget {
  final String reference;
  const VehicleDetailScreen({super.key, required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehicleByRefProvider(reference));
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche vehicule')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (v) {
          if (v == null) {
            return const Center(child: Text('Vehicule introuvable'));
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
                  'Creez un compte en 1 minute pour recevoir votre devis.',
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
              icon: Icon(isLoggedIn ? Icons.request_quote : Icons.login),
              label: Text(isLoggedIn
                  ? 'Demander le prix'
                  : 'Se connecter pour demander le prix'),
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
              const SizedBox(height: 16),
              const CustomsTermsNotice(),
              const SizedBox(height: 20),
              const Text('Caracteristiques',
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
      ('Modele', v.model),
      ('Annee', v.year?.toString()),
      ('Version', v.version),
      ('Motorisation', v.engine),
      ('Cylindree', v.displacement),
      ('Kilometrage', v.mileageLabel),
      ('Transmission', v.transmission),
      ('Carburant', v.fuel),
      ('Couleur', v.color),
      ('Portes', v.doors?.toString()),
      ('Volant', v.steeringLabel),
      ('Localisation', v.location),
      ('Reference', v.reference),
      ('Etat', v.condition),
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
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Container(
              color: AppColors.grisClair,
              child: Image.network(
                widget.photos[i],
                fit: BoxFit.cover,
                // Repli <img> HTML pour les images sans CORS (photos Encar).
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image,
                        size: 48, color: AppColors.gris)),
                loadingBuilder: (c, child, p) => p == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
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
                      color: i == _index ? AppColors.primary : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
