import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/facebook_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/download_file.dart';
import '../../core/utils/encar_image.dart';
import '../../core/utils/encar_source.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/open_tab.dart';
import '../../models/vehicle_listing.dart';

/// Lien profond partageable d'un vehicule.
String vehicleShareUrl(String reference) =>
    'https://terangamobility.gesprosn.org/#/vehicule/$reference';

/// Texte de post Facebook pret a coller.
String fbCaption(VehicleListing v) {
  final specs = [v.fuel, v.transmission]
      .where((e) => e != null && e.isNotEmpty)
      .join(' · ');
  final lines = <String>[
    '🚗 ${v.title}',
    if (v.version != null && v.version!.isNotEmpty) v.version!,
    '',
    if (v.mileageLabel != null) '🛣️ ${v.mileageLabel}',
    if (specs.isNotEmpty) '⚙️ $specs',
    if (v.color != null && v.color!.isNotEmpty) '🎨 ${v.color}',
    '',
    v.priceFcfa != null
        ? '💰 ${Formatters.fcfa(v.priceFcfa)} — tout compris (hors dédouanement)'
        : '💰 Prix sur demande',
    '✅ Importé de Corée · Livraison Dakar',
    '',
    '👉 Détails & réservation : ${vehicleShareUrl(v.reference)}',
    '📲 WhatsApp : +221 77 282 17 82',
    '',
    '#TerangaMobility #VoitureCorée #Dakar #Sénégal #${v.brand.replaceAll(' ', '')}',
  ];
  return lines.join('\n');
}

/// Nom de fichier propose au telechargement d'une photo.
String _photoFilename(VehicleListing v, int index) {
  final slug = '${v.brand}_${v.model}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'teranga_${slug}_${v.reference}_${index + 1}.jpg';
}

/// Nom du ZIP « toutes les photos ».
String _zipFilename(VehicleListing v) {
  final slug = '${v.brand}_${v.model}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'teranga_${slug}_${v.reference}_photos.zip';
}

/// Publication assistee : copie le texte, propose de telecharger les photos HD
/// (pour les joindre au post) et d'ouvrir le composeur Facebook. Un bouton
/// « Voir sur Encar » permet de verifier que le vehicule est toujours en vente.
Future<void> prepareFacebookPost(
    BuildContext context, VehicleListing v) async {
  final caption = fbCaption(v);
  await Clipboard.setData(ClipboardData(text: caption));
  if (!context.mounted) return;
  final encarUrl = encarListingUrl(v.reference);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: AppColors.grisClair,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Publier « ${v.title} »',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.vert.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: AppColors.vert, size: 18),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Le texte du post est déjà copié.',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 8),
            const Text(
                '1. Téléchargez les photos ci-dessous.\n'
                '2. Ouvrez Facebook → « Créer une publication ».\n'
                '3. Collez le texte + ajoutez les photos → Publiez.',
                style: TextStyle(fontSize: 12.5, color: AppColors.gris)),
            const SizedBox(height: 14),
            if (v.photos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Photos (${v.photos.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      messenger.showSnackBar(SnackBar(
                          content: Text(
                              'Préparation de ${v.photos.length} photos…')));
                      try {
                        final urls = [
                          for (final p in v.photos)
                            imageProxyUrl(encarPhotoFull(p, height: 1200))
                        ];
                        final names = [
                          for (var i = 0; i < v.photos.length; i++)
                            _photoFilename(v, i)
                        ];
                        await downloadImagesZip(urls, names, _zipFilename(v));
                      } catch (_) {
                        messenger.showSnackBar(const SnackBar(
                            content: Text(
                                'Téléchargement impossible. Touchez chaque photo pour l\'enregistrer.')));
                      }
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Tout télécharger (ZIP)'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                  'Astuce : touchez une photo pour l\'ouvrir en grand '
                  '(dans l\'app) puis la télécharger, ou utilisez le bouton ⬇ '
                  'sur chaque vignette.',
                  style: TextStyle(fontSize: 11, color: AppColors.gris)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < v.photos.length; i++)
                    _PhotoTile(
                      thumbUrl: encarPhoto(v.photos[i], height: 240),
                      fullUrl: encarPhotoFull(v.photos[i], height: 1200),
                      filename: _photoFilename(v, i),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => openInNewTab(FacebookConfig.composerUrl),
                  icon: const Icon(Icons.facebook, size: 18),
                  label: const Text('Ouvrir Facebook'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: caption));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Texte recopié.')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Recopier le texte'),
                ),
                if (encarUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => openInNewTab(encarUrl),
                    icon: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('Voir sur Encar'),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Miniature cliquable : ouvre la photo HD (pour enregistrer) + bouton
/// telechargement direct.
class _PhotoTile extends StatelessWidget {
  final String thumbUrl;
  final String fullUrl;
  final String filename;
  const _PhotoTile(
      {required this.thumbUrl,
      required this.fullUrl,
      required this.filename});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 74,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              // Ouverture EN PLEIN ECRAN DANS L'APP (aucune navigation externe :
              // l'onglet courant n'est jamais remplace, l'app n'est pas
              // rechargee). Un bouton de telechargement est propose dans la vue.
              onTap: () => showPhotoViewer(context, fullUrl, filename),
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => Container(
                    color: AppColors.grisClair,
                    child: const Icon(Icons.directions_car,
                        color: AppColors.gris)),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => downloadImage(
                    imageProxyUrl(fullUrl, download: true, name: filename),
                    filename),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.download, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visionneuse plein ecran EN INTERNE (aucune navigation, l'app reste vivante).
/// Zoom/deplacement + bouton telechargement (via le proxy, en blob local).
void showPhotoViewer(
    BuildContext context, String encarFullUrl, String filename) {
  final viewUrl = imageProxyUrl(encarPhotoFull(encarFullUrl, height: 1200));
  final dlUrl = imageProxyUrl(encarPhotoFull(encarFullUrl, height: 1200),
      download: true, name: filename);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  viewUrl,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 48)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => downloadImage(dlUrl, filename),
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger cette photo'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
