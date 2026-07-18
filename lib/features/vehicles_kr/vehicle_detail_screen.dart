import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/encar_image.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_enums.dart';
import '../../models/vehicle_listing.dart';
import '../../models/vehicle_order.dart';
import '../../providers/auth_providers.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../../providers/vehicle_order_providers.dart';
import '../client/vehicles_kr/vehicle_tracking_screen.dart';
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

/// Barre d'action de la fiche : « Réserver » (prix connu), « Demander le prix »
/// (prix sur demande) ou « Déjà réservé » (véhicule non disponible).
/// C'est ici — et seulement ici — qu'un compte devient necessaire.
class _PriceCta extends ConsumerStatefulWidget {
  final VehicleListing vehicle;
  const _PriceCta({required this.vehicle});

  @override
  ConsumerState<_PriceCta> createState() => _PriceCtaState();
}

class _PriceCtaState extends ConsumerState<_PriceCta> {
  bool _busy = false;

  Future<void> _reserve() async {
    final v = widget.vehicle;
    final deposit = ((v.priceFcfa ?? 0) * 0.7).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réserver ce véhicule'),
        content: Text(
            'La réservation est gratuite : le véhicule vous est bloqué 72 h.\n\n'
            '• Vous avez 72 h pour payer l\'acompte de 70 % '
            '(${Formatters.fcfa(deposit)}) et confirmer la commande.\n'
            '• Paiement : espèces (RDV agence), virement ou mobile money.\n'
            '• Sous réserve de disponibilité chez le fournisseur.\n\n'
            'Passé 72 h sans paiement, le véhicule est remis au catalogue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Réserver')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final svc = ref.read(vehicleOrderServiceProvider);
      final orderId = await svc.reserveVehicle(v.reference);
      ref.invalidate(vehicleListingsProvider);
      ref.invalidate(vehicleByRefProvider(v.reference));
      ref.invalidate(myVehicleOrdersProvider);
      if (!mounted) return;
      // Commande locale minimale pour ouvrir directement le suivi (paiement 70%).
      final order = VehicleOrder(
        id: orderId,
        clientId: ref.read(authServiceProvider).currentUser?.id,
        vehicleReference: v.reference,
        totalPrice: v.priceFcfa,
        depositAmount: deposit,
        balanceAmount: ((v.priceFcfa ?? 0) * 0.3).round(),
        status: VehicleOrderStatus.enAttenteAcompte,
        reservationDeadline: DateTime.now().add(const Duration(hours: 72)),
      );
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VehicleTrackingScreen(order: order),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Réservation impossible : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final isLoggedIn = ref.watch(authServiceProvider).currentUser != null;
    final hasPrice = v.priceFcfa != null;

    // Barre compacte : un seul bouton pleine largeur. PAS de Center ici :
    // dans un bottomNavigationBar, Center s'etire sur toute la hauteur et
    // ecrase le corps.
    Widget button;
    if (!v.isAvailable) {
      button = ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Déjà réservé'),
      );
    } else if (!isLoggedIn) {
      button = ElevatedButton.icon(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.login),
        label: Text(hasPrice
            ? 'Se connecter pour réserver'
            : 'Se connecter pour commander'),
      );
    } else if (hasPrice) {
      button = ElevatedButton.icon(
        onPressed: _busy ? null : _reserve,
        icon: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.lock_clock),
        label: Text(_busy ? 'Réservation…' : 'Réserver ce véhicule'),
      );
    } else {
      button = ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RequestPriceScreen(vehicle: v),
        )),
        icon: const Icon(Icons.directions_car),
        label: const Text('Demander le prix'),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: SizedBox(width: double.infinity, child: button),
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
              const SizedBox(height: 12),
              if (!vehicle.isAvailable)
                _banner(
                  icon: Icons.lock_outline,
                  color: AppColors.gris,
                  text: 'Ce véhicule est déjà réservé par un autre client.',
                )
              else if (vehicle.priceFcfa != null)
                _banner(
                  icon: Icons.bolt,
                  color: AppColors.ambre,
                  text:
                      'Ces véhicules partent vite. Réservez-le gratuitement : '
                      'il vous est bloqué 72 h pour payer l\'acompte de 70 %.',
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

  Widget _banner(
      {required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.anthracite)),
          ),
        ],
      ),
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
  int _index = 0;

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
    // Index securise (au cas ou la liste changerait).
    final index = _index.clamp(0, widget.photos.length - 1);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        // Image principale unique (pas de PageView : evite le bug de
        // composition des <img> HTML dans un viewport scrollable sur web).
        AspectRatio(
          aspectRatio: 16 / 10,
          child: _img(
              encarPhotoAdaptive(widget.photos[index],
                  logicalWidth: w, devicePixelRatio: dpr, ratio: 16 / 10),
              BoxFit.cover),
        ),
        // Bande de miniatures en Wrap (non scrollable) : on change l'image
        // principale au clic.
        if (widget.photos.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < widget.photos.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      width: 74,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i == index
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _img(
                          encarPhoto(widget.photos[i],
                              height: 200, ratio: 16 / 10),
                          BoxFit.cover),
                    ),
                  ),
              ],
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
