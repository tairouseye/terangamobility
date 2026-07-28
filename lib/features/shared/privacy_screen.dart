import 'package:flutter/material.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';

/// Politique de confidentialité — requise notamment par le Pixel Facebook.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Politique de confidentialité',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${AppInfo.appName} — éditée par ${AppInfo.publisher}',
                style: const TextStyle(color: AppColors.gris)),
            const SizedBox(height: 20),
            const _Section(
              'Données que nous collectons',
              'Pour traiter vos demandes (véhicules et pièces), nous collectons les '
                  'informations que vous fournissez : nom, numéro WhatsApp, email, '
                  'ville, ainsi que les détails de vos demandes et commandes. Ces '
                  'données sont conservées de façon sécurisée et ne servent qu\'au '
                  'traitement de votre dossier et au suivi de vos commandes.',
            ),
            _Section(
              'Cookies et mesure d\'audience (Pixel Facebook)',
              'Notre site utilise le Pixel Facebook (Meta) pour mesurer l\'audience '
                  'et proposer des publicités pertinentes aux visiteurs. Le Pixel peut '
                  'déposer des cookies et transmettre à Meta des informations sur votre '
                  'navigation (pages vues, véhicules consultés). Vous pouvez gérer vos '
                  'préférences publicitaires depuis les paramètres de votre compte '
                  'Facebook, ou bloquer ces cookies via votre navigateur.',
            ),
            const _Section(
              'Partage des données',
              'Nous ne vendons pas vos données. Elles peuvent être partagées avec nos '
                  'prestataires techniques (hébergement, mesure d\'audience) uniquement '
                  'dans la mesure nécessaire au fonctionnement du service.',
            ),
            const _Section(
              'Vos droits',
              'Vous pouvez demander l\'accès, la correction ou la suppression de vos '
                  'données à tout moment en nous contactant.',
            ),
            _Section(
              'Contact',
              'Pour toute question relative à vos données : ${AppInfo.supportEmail} '
                  '— ${AppInfo.supportPhone}.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.5, fontSize: 13.5)),
        ],
      ),
    );
  }
}
