import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/facebook_config.dart';
import '../../core/utils/encar_image.dart';
import '../../core/utils/formatters.dart';
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

/// Publication assistee : copie le texte, propose la photo HD + le composeur.
Future<void> prepareFacebookPost(
    BuildContext context, VehicleListing v) async {
  final caption = fbCaption(v);
  await Clipboard.setData(ClipboardData(text: caption));
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Publier sur Facebook'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✅ Le texte du post est copié.',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
              '1. Enregistre la photo (bouton ci-dessous).\n'
              '2. Ouvre Facebook → « Créer une publication ».\n'
              '3. Colle le texte + ajoute la photo → Publie.',
              style: TextStyle(fontSize: 13)),
        ],
      ),
      actions: [
        if (v.photos.isNotEmpty)
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(
                  encarPhoto(v.photos.first, height: 1080, ratio: 16 / 9)),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.image, size: 18),
            label: const Text('Photo'),
          ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: caption));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Texte recopié.')));
          },
          child: const Text('Copier'),
        ),
        ElevatedButton.icon(
          onPressed: () => launchUrl(Uri.parse(FacebookConfig.composerUrl),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.facebook, size: 18),
          label: const Text('Ouvrir Facebook'),
        ),
      ],
    ),
  );
}
