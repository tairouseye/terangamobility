import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/client_overview.dart';
import '../../providers/admin_client_providers.dart';
import 'client_detail_screen.dart';

/// Admin : liste des clients avec recherche et compteurs cles.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminClientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un client (nom, WhatsApp)',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _search.clear();
                          ref.read(clientSearchProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) =>
                  ref.read(clientSearchProvider.notifier).state = v.trim(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminClientsProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur : $e', textAlign: TextAlign.center),
                  ),
                ),
                data: (clients) {
                  if (clients.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Icon(Icons.people_outline, size: 64, color: AppColors.gris),
                      SizedBox(height: 16),
                      Center(
                          child: Text('Aucun client',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600))),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: clients.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) return _Totals(clients: clients);
                      return _ClientCard(summary: clients[i - 1]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de synthese sur l'ensemble des clients affiches.
class _Totals extends StatelessWidget {
  final List<ClientSummary> clients;
  const _Totals({required this.clients});

  @override
  Widget build(BuildContext context) {
    final ordered = clients.fold<num>(0, (s, c) => s + c.totalOrdered);
    final paid = clients.fold<num>(0, (s, c) => s + c.totalPaid);
    final due = (ordered - paid).clamp(0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _stat('Clients', '${clients.length}', AppColors.primary),
          _divider(),
          _stat('Commande', Formatters.fcfa(ordered), AppColors.anthracite),
          _divider(),
          _stat('Encaisse', Formatters.fcfa(paid), AppColors.vert),
          _divider(),
          _stat('Reste du', Formatters.fcfa(due),
              due > 0 ? AppColors.ambre : AppColors.gris),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 28, color: AppColors.primary.withValues(alpha: 0.15));

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.gris)),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ],
        ),
      );
}

class _ClientCard extends StatelessWidget {
  final ClientSummary summary;
  const _ClientCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final u = summary.user;
    final initials = u.fullName.trim().isEmpty
        ? '?'
        : u.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ClientDetailScreen(summary: summary),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName.isEmpty ? '(sans nom)' : u.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (u.whatsapp.isNotEmpty)
                      Text(u.whatsapp,
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _pill('${summary.vehicleCount} veh.', AppColors.vert),
                      _pill('${summary.requestCount} dem.', AppColors.gris),
                      _pill('${summary.orderCount} cmd.', AppColors.primary),
                      if (summary.outstanding > 0)
                        _pill('Reste ${Formatters.fcfa(summary.outstanding)}',
                            AppColors.ambre),
                    ]),
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

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
