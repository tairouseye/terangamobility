import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/teranga_logo.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/client/client_dashboard.dart';
import '../features/partner_kr/partner_dashboard.dart';

/// Application en MODE DEMO : pas de connexion, on choisit directement
/// l'espace a explorer. Les donnees sont en memoire (voir DemoStore).
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerangaMobility — Parts & Vehicules (Demo)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _DemoLanding(),
    );
  }
}

class _DemoLanding extends StatelessWidget {
  const _DemoLanding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const TerangaLockup(badgeSize: 88, onDark: true),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('MODE DEMONSTRATION',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 32),
                  const Text('Choisissez un espace a explorer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 16),
                  _RoleButton(
                    icon: Icons.person,
                    title: 'Espace Client',
                    subtitle: 'Vehicules, demandes, devis, suivi',
                    onTap: () => _open(context, const ClientDashboard()),
                  ),
                  const SizedBox(height: 12),
                  _RoleButton(
                    icon: Icons.public,
                    title: 'Partenaire Coree',
                    subtitle: 'Demandes a traiter, propositions',
                    onTap: () => _open(context, const PartnerDashboard()),
                  ),
                  const SizedBox(height: 12),
                  _RoleButton(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Teranga Parts',
                    subtitle: 'Devis, commandes, expeditions',
                    onTap: () => _open(context, const AdminDashboard()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.gris, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gris),
            ],
          ),
        ),
      ),
    );
  }
}
