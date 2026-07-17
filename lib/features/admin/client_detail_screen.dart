import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/client_overview.dart';
import '../../providers/admin_client_providers.dart';
import 'order_manage_screen.dart';

/// Admin : fiche client 360 (identite, vehicules, demandes, commandes,
/// paiements) avec la distinction commande / encaisse.
class ClientDetailScreen extends ConsumerWidget {
  final ClientSummary summary;
  const ClientDetailScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = summary.user.id;
    final vehicles = ref.watch(clientVehiclesProvider(id));
    final requests = ref.watch(clientRequestsProvider(id));
    final orders = ref.watch(clientOrdersProvider(id));
    final payments = ref.watch(clientPaymentsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.user.fullName.isEmpty
            ? 'Client'
            : summary.user.fullName),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientVehiclesProvider(id));
          ref.invalidate(clientRequestsProvider(id));
          ref.invalidate(clientOrdersProvider(id));
          ref.invalidate(clientPaymentsProvider(id));
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Identity(summary: summary),
            const SizedBox(height: 16),
            _Money(summary: summary),
            const SizedBox(height: 20),

            // --- Vehicules ---
            _Section(
              icon: Icons.directions_car,
              color: AppColors.vert,
              title: 'Vehicules',
              child: vehicles.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur : $e'),
                data: (list) => list.isEmpty
                    ? const _Empty('Aucun vehicule enregistre')
                    : Column(
                        children: list
                            .map((v) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.directions_car,
                                      size: 20, color: AppColors.gris),
                                  title: Text(v.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  subtitle: Text([
                                    if (v.engine != null) v.engine,
                                    if (v.vin != null) 'VIN ${v.vin}',
                                  ].whereType<String>().join('  •  ')),
                                ))
                            .toList(),
                      ),
              ),
            ),

            // --- Demandes ---
            _Section(
              icon: Icons.inventory_2,
              color: AppColors.ambre,
              title: 'Demandes de pieces',
              child: requests.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur : $e'),
                data: (list) => list.isEmpty
                    ? const _Empty('Aucune demande')
                    : Column(
                        children: list
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(r.partName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 14)),
                                            Text(
                                                '${r.vehicleLabel}  •  ${Formatters.date(r.createdAt)}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.gris)),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(r.status),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ),

            // --- Commandes ---
            _Section(
              icon: Icons.local_shipping,
              color: AppColors.primary,
              title: 'Commandes',
              child: orders.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur : $e'),
                data: (list) => list.isEmpty
                    ? const _Empty('Aucune commande')
                    : Column(
                        children: list
                            .map((o) => InkWell(
                                  onTap: () =>
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  OrderManageScreen(
                                                      orderView: o))),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(o.partName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14)),
                                              Text(Formatters.fcfa(o.total),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.gris)),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(o.status),
                                        const Icon(Icons.chevron_right,
                                            color: AppColors.gris, size: 18),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ),

            // --- Paiements ---
            _Section(
              icon: Icons.payments,
              color: AppColors.vert,
              title: 'Paiements',
              child: payments.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur : $e'),
                data: (list) => list.isEmpty
                    ? const _Empty('Aucun paiement enregistre')
                    : Column(
                        children: list
                            .map((p) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            '${p.type.label}${p.method != null ? '  •  ${p.method}' : ''}',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                      Text(Formatters.date(p.paidAt),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.gris)),
                                      const SizedBox(width: 10),
                                      Text(Formatters.fcfa(p.amount),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.vert)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final ClientSummary summary;
  const _Identity({required this.summary});

  @override
  Widget build(BuildContext context) {
    final u = summary.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.fullName.isEmpty ? '(sans nom)' : u.fullName,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  if (u.whatsapp.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.chat, size: 14, color: AppColors.vert),
                      const SizedBox(width: 5),
                      Text(u.whatsapp,
                          style: const TextStyle(color: AppColors.gris)),
                    ]),
                  Text('Client depuis le ${Formatters.date(u.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gris)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Commande vs encaisse — la distinction cle du suivi financier.
class _Money extends StatelessWidget {
  final ClientSummary summary;
  const _Money({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _cell('Commande', summary.totalOrdered, AppColors.anthracite),
            _cell('Encaisse', summary.totalPaid, AppColors.vert),
            _cell('Reste du', summary.outstanding,
                summary.outstanding > 0 ? AppColors.ambre : AppColors.gris),
          ],
        ),
      ),
    );
  }

  Widget _cell(String label, num value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(Formatters.fcfa(value),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: AppColors.gris, fontSize: 13));
}
