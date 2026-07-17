import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';

/// Bloc « Developpe par GesPro » affiche en bas de l'accueil : editeur,
/// email et WhatsApp cliquables, + version de deploiement.
class GesProCredit extends StatelessWidget {
  final bool onDark;
  const GesProCredit({super.key, this.onDark = false});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final base = onDark ? Colors.white : AppColors.anthracite;
    final muted = onDark ? Colors.white70 : AppColors.gris;
    final link = onDark ? AppColors.or : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Developpe par ${AppInfo.publisherShort}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: base)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _open('mailto:${AppInfo.supportEmail}'),
          child: Text(AppInfo.supportEmail,
              style: TextStyle(
                  fontSize: 12.5,
                  color: link,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _open(AppInfo.whatsappUrl()),
          child: Text('💬 Assistance WhatsApp : ${AppInfo.supportPhone}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: muted)),
        ),
        const SizedBox(height: 10),
        const _VersionLine(),
      ],
    );
  }
}

/// Version de deploiement : version du pubspec + date de build si fournie.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = snap.hasData ? 'v${snap.data!.version}' : 'v…';
        final date = AppInfo.buildDate.isEmpty ? '' : ' · ${AppInfo.buildDate}';
        return Text('$v$date',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.gris,
                fontWeight: FontWeight.w600));
      },
    );
  }
}
