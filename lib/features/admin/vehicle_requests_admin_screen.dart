import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_enums.dart';
import '../../models/vehicle_request.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../../providers/vehicle_order_providers.dart';

/// Admin : demandes de prix véhicule + envoi du devis.
class VehicleRequestsAdminScreen extends ConsumerWidget {
  const VehicleRequestsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehicleRequestsAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes véhicule')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vehicleRequestsAdminProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.request_quote_outlined,
                    size: 64, color: AppColors.gris),
                SizedBox(height: 16),
                Center(
                    child: Text('Aucune demande de prix',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _RequestCard(request: requests[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final VehicleRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleByRefProvider(request.vehicleReference));
    final title = vehicle.valueOrNull?.title ?? request.vehicleReference;
    final canQuote = request.status == VehicleRequestStatus.enAttenteDevis;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 8),
            _line(Icons.person, request.customerName),
            _line(Icons.phone, request.phone),
            if (request.whatsapp != null && request.whatsapp!.isNotEmpty)
              _line(Icons.chat, 'WhatsApp ${request.whatsapp}'),
            if ((request.city ?? '').isNotEmpty ||
                (request.country ?? '').isNotEmpty)
              _line(Icons.place,
                  [request.city, request.country].whereType<String>().join(', ')),
            if (request.message != null && request.message!.isNotEmpty)
              _line(Icons.notes, request.message!),
            _line(Icons.tag, 'Ref ${request.vehicleReference}'),
            const SizedBox(height: 4),
            Text('Reçue le ${Formatters.date(request.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.gris)),
            if (canQuote) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendQuoteDialog(context, ref),
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer un devis'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendQuoteDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final total = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prix total du véhicule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Montant total (FCFA), tout compris. Le client paiera 70% '
                'd\'acompte puis 30% au port.',
                style: TextStyle(fontSize: 12.5, color: AppColors.gris)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Prix total (FCFA)', prefixIcon: Icon(Icons.payments)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final v = num.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (total == null) return;

    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .sendQuote(request: request, totalPrice: total);
      ref.invalidate(vehicleRequestsAdminProvider);
      ref.invalidate(vehicleOrdersAdminProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Devis envoyé : ${Formatters.fcfa(total)} (acompte ${Formatters.fcfa((total * 0.7).round())})')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: AppColors.gris),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}

class _StatusChip extends StatelessWidget {
  final VehicleRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color) = switch (status) {
      VehicleRequestStatus.enAttenteDevis => AppColors.ambre,
      VehicleRequestStatus.devisEnvoye => AppColors.primary,
      VehicleRequestStatus.accepte => AppColors.vert,
      VehicleRequestStatus.refuse => AppColors.gris,
      VehicleRequestStatus.clos => AppColors.gris,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
