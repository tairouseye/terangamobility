import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/vehicle_enums.dart';
import '../../../models/vehicle_order.dart';
import '../../../providers/vehicle_catalog_providers.dart';
import '../../../providers/vehicle_order_providers.dart';
import '../../shared/vehicle_timeline.dart';

/// Client : suivi d'une commande vehicule (prix, expedition, timeline,
/// paiement acompte/solde).
class VehicleTrackingScreen extends ConsumerStatefulWidget {
  final VehicleOrder order;
  const VehicleTrackingScreen({super.key, required this.order});

  @override
  ConsumerState<VehicleTrackingScreen> createState() =>
      _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState
    extends ConsumerState<VehicleTrackingScreen> {
  bool _paying = false;

  Future<void> _pay({required bool deposit}) async {
    final method = await _pickMethod();
    if (method == null) return;
    setState(() => _paying = true);
    try {
      final svc = ref.read(vehicleOrderServiceProvider);
      if (deposit) {
        await svc.payDeposit(widget.order.id!, method: method);
      } else {
        await svc.payBalance(widget.order.id!, method: method);
      }
      ref.invalidate(myVehicleOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(deposit
                ? 'Acompte enregistre. Commande confirmee !'
                : 'Solde regle. Vehicule pret a recuperer !')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Paiement impossible : $e')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<String?> _pickMethod() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Mode de paiement',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (final m in const ['Wave', 'Orange Money', 'Especes', 'Virement'])
            ListTile(
              leading: const Icon(Icons.payments, color: AppColors.vert),
              title: Text(m),
              onTap: () => Navigator.pop(context, m),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final vehicle = ref.watch(vehicleByRefProvider(o.vehicleReference));
    final title = vehicle.valueOrNull?.title ?? o.vehicleReference;
    final tracking = ref.watch(vehicleTrackingProvider(o.id!));

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi du vehicule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Ref ${o.vehicleReference}',
                style: const TextStyle(color: AppColors.gris)),
            const SizedBox(height: 12),
            // Recap paiements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _row('Prix total', o.totalPrice, bold: true),
                  _row('Acompte (70%)', o.depositAmount, paid: o.depositPaid),
                  _row('Solde (30%)', o.balanceAmount, paid: o.balancePaid),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Infos numero de commande + expedition
            Card(
              color: AppColors.grisClair,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _info('N° de commande', o.id?.substring(0, 8).toUpperCase()),
                    _info('N° de tracking', o.trackingNumber),
                    _info('Compagnie maritime', o.shippingCompany),
                    _info('Depart estime', Formatters.date(o.estimatedDeparture)),
                    _info('Arrivee estimee', Formatters.date(o.estimatedArrival)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Rappel delai
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.ambre.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Delai d\'acheminement par container : 60 a 90 jours. '
                'Le dedouanement est a votre charge.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A5A00)),
              ),
            ),
            const SizedBox(height: 16),
            // Boutons de paiement selon le statut
            if (o.status == VehicleOrderStatus.enAttenteAcompte &&
                !o.depositPaid)
              _payButton(
                  'Payer l\'acompte (${Formatters.fcfa(o.depositAmount)})',
                  () => _pay(deposit: true)),
            if (o.status == VehicleOrderStatus.arrivePort && !o.balancePaid)
              _payButton(
                  'Payer le solde (${Formatters.fcfa(o.balanceAmount)})',
                  () => _pay(deposit: false)),
            const SizedBox(height: 12),
            const Text('Suivi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            VehicleTimeline(current: o.status),
            const SizedBox(height: 8),
            // Historique horodate (si dispo)
            tracking.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (events) => events.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: events.reversed
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                    '${Formatters.date(e.createdAt)} — ${e.status.label}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.gris)),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payButton(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          onPressed: _paying ? null : onTap,
          icon: _paying
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.payments),
          label: Text(label),
        ),
      );

  Widget _row(String label, num? value, {bool bold = false, bool? paid}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            Row(children: [
              if (paid == true)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child:
                      Icon(Icons.check_circle, size: 16, color: AppColors.vert),
                ),
              Text(Formatters.fcfa(value),
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
            ]),
          ],
        ),
      );

  Widget _info(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.gris))),
            Expanded(
                child: Text(value == null || value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
