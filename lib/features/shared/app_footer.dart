import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import 'about_screen.dart';

/// Pied de page persistant : version de l'app + acces a l'assistance.
/// Affiche en bas des dashboards (et de l'accueil).
class AppFooter extends StatelessWidget {
  final bool onDark;
  const AppFooter({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final muted = onDark ? Colors.white70 : AppColors.gris;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onDark ? Colors.transparent : AppColors.blanc,
          border: onDark
              ? null
              : const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '${AppInfo.appName} • ${AppInfo.appTagline}   —   ${AppInfo.publisher}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
            const SizedBox(width: 10),
            _VersionChip(color: muted),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.help_outline, size: 13, color: muted),
                  const SizedBox(width: 3),
                  Text('Assistance',
                      style: TextStyle(
                          fontSize: 11,
                          color: muted,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puce de version, lue une seule fois depuis le pubspec.
class _VersionChip extends StatelessWidget {
  final Color color;
  const _VersionChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = snap.hasData ? 'v${snap.data!.version}' : 'v…';
        final date =
            AppInfo.buildDate.isEmpty ? '' : ' · ${AppInfo.buildDate}';
        return Text('$v$date',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w700));
      },
    );
  }
}
