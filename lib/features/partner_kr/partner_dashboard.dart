import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../shared/dashboard_scaffold.dart';
import 'requests_inbox_screen.dart';

/// Espace Partenaire Coree (Lot 4 : inbox demandes, proposer pieces).
class PartnerDashboard extends ConsumerWidget {
  const PartnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return DashboardScaffold(
      title: 'Partenaire Coree',
      children: [
        Text('Annyeong ${profile?.fullName ?? ''} 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Consultez les demandes et proposez vos pieces.',
            style: TextStyle(color: AppColors.gris)),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.inbox, color: AppColors.primary),
            ),
            title: const Text('Demandes a traiter',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Reference, prix (KRW), poids, dimensions, photo, delai'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RequestsInboxScreen(),
            )),
          ),
        ),
      ],
    );
  }
}
