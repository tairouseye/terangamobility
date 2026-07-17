import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/teranga_logo.dart';

/// Ecran « A propos & Assistance » : version de l'application, éditeur et
/// contacts de support cliquables.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  /// La version vient du pubspec (via package_info_plus), pas d'une constante
  /// codee en dur : impossible qu'elle se desynchronise du build.
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = 'v${info.version} (build ${info.buildNumber})');
    } catch (_) {
      if (mounted) setState(() => _version = 'version indisponible');
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir : $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A propos & Assistance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            const Center(child: TerangaLockup(badgeSize: 84)),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _version,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- Assistance ---
            const Text('Besoin d\'aide ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Notre equipe vous repond du lundi au samedi, de 9h a 19h.',
              style: TextStyle(color: AppColors.gris, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _ContactTile(
              icon: Icons.chat,
              color: AppColors.vert,
              title: 'WhatsApp',
              subtitle: AppInfo.supportPhone,
              trailing: 'Le plus rapide',
              onTap: () => _open(AppInfo.whatsappUrl()),
            ),
            _ContactTile(
              icon: Icons.call,
              color: AppColors.primary,
              title: 'Téléphone',
              subtitle: AppInfo.supportPhone,
              onTap: () => _open(AppInfo.telUrl),
            ),
            if (AppInfo.supportEmail.isNotEmpty)
              _ContactTile(
                icon: Icons.mail_outline,
                color: AppColors.anthracite,
                title: 'Email',
                subtitle: AppInfo.supportEmail,
                onTap: () => _open('mailto:${AppInfo.supportEmail}'),
              ),
            _ContactTile(
              icon: Icons.language,
              color: AppColors.or,
              title: 'Site web',
              subtitle: AppInfo.publisherSite.replaceFirst('https://', ''),
              onTap: () => _open(AppInfo.publisherSite),
            ),

            const SizedBox(height: 28),

            // --- Editeur ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grisClair,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('Application éditée par',
                      style: TextStyle(fontSize: 12, color: AppColors.gris)),
                  const SizedBox(height: 4),
                  Text(
                    AppInfo.publisher,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.anthracite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Solutions de gestion pour les entreprises sénégalaises',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.gris),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} ${AppInfo.publisher} — '
              'Tous droits reserves',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.gris),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle),
        trailing: trailing == null
            ? const Icon(Icons.chevron_right, color: AppColors.gris)
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.vert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trailing!,
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.vert,
                        fontWeight: FontWeight.w700)),
              ),
        onTap: onTap,
      ),
    );
  }
}
