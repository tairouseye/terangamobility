import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/encar_image.dart';
import '../../../core/utils/encar_price.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/vehicle_listing.dart';
import '../facebook_post_helper.dart';
import '../vehicle_detail_screen.dart';
import 'favorite_button.dart';

/// Libellé d'indisponibilité (ou null si le véhicule est bien disponible).
String? _statusLabel(VehicleListing v) {
  if (v.isActive && v.isAvailable) return null;
  return switch (v.availability) {
    'sold' => 'Vendu',
    'reserved' => 'Réservé',
    _ => 'Plus disponible',
  };
}

/// Carte vehicule reutilisable (catalogue, favoris...). Photo + infos + prix,
/// coeur « J'aime » en surimpression, et action Facebook cote admin.
class VehicleCard extends StatelessWidget {
  final VehicleListing vehicle;
  final bool isAdmin;
  const VehicleCard({super.key, required this.vehicle, this.isAdmin = false});

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
            Stack(
              children: [
                _Photo(vehicle: vehicle),
                // Voile + badge quand le véhicule n'est plus disponible
                // (retiré du catalogue, réservé ou vendu) — utile dans « Mes
                // favoris » où l'on garde des véhicules qui ont pu partir.
                if (_statusLabel(vehicle) case final label?) ...[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteButton(
                      reference: vehicle.reference, onPhoto: true),
                ),
              ],
            ),
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
                  if (vehicle.importedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.event_available,
                          size: 13, color: AppColors.gris),
                      const SizedBox(width: 4),
                      Text('Ajouté le ${Formatters.date(vehicle.importedAt)}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.gris)),
                    ]),
                  ],
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
                          if (estimatedEncarPrice(vehicle.priceFcfa)
                              case final e? when isAdmin)
                            Text('Encar ≈ ${Formatters.fcfa(e.fcfa)} brut',
                                style: const TextStyle(
                                    fontSize: 10.5, color: Color(0xFF7A5A00))),
                        ],
                      ),
                      if (isAdmin)
                        IconButton(
                          tooltip: 'Poster sur Facebook',
                          icon: const Icon(Icons.campaign,
                              color: AppColors.primary),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => prepareFacebookPost(context, vehicle),
                        )
                      else
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary),
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
    final raw = vehicle.photos.isNotEmpty ? vehicle.photos.first : null;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, c) {
          final url = raw == null
              ? null
              : encarPhotoAdaptive(raw,
                  logicalWidth: c.maxWidth,
                  devicePixelRatio: dpr,
                  ratio: 16 / 9,
                  maxHeight: 640);
          return Container(
            color: AppColors.grisClair,
            child: url == null
                ? const Center(
                    child: Icon(Icons.directions_car,
                        size: 48, color: AppColors.gris))
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.directions_car,
                            size: 48, color: AppColors.gris)),
                    loadingBuilder: (c, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                  ),
          );
        },
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
