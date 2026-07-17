import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_info.dart';
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
  bool _busy = false;

  /// Le client declare avoir effectue le virement/depot -> l'admin est notifie
  /// et confirmera apres verification (pas d'auto-validation pour les vehicules).
  Future<void> _declare({required bool deposit}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .declarePayment(widget.order.id!, deposit ? 'deposit' : 'balance');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Merci ! Notre équipe vérifie votre paiement et confirme sous peu.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDoc(String name) async {
    try {
      final path = '${widget.order.clientId}/$name-${widget.order.id}.pdf';
      final url =
          await ref.read(vehicleOrderServiceProvider).documentUrl(path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ouverture impossible : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final vehicle = ref.watch(vehicleByRefProvider(o.vehicleReference));
    final title = vehicle.valueOrNull?.title ?? o.vehicleReference;
    final tracking = ref.watch(vehicleTrackingProvider(o.id!));

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi du véhicule')),
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
                    _info('Départ estimé', Formatters.date(o.estimatedDeparture)),
                    _info('Arrivée estimée', Formatters.date(o.estimatedArrival)),
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
                'Délai d\'acheminement par container : 60 à 90 jours. '
                'Le dédouanement est à votre charge.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A5A00)),
              ),
            ),
            const SizedBox(height: 16),
            // Paiement vehicule : par virement ou especes, confirme par l'equipe.
            if (o.status == VehicleOrderStatus.enAttenteAcompte &&
                !o.depositPaid)
              _paymentBlock(
                  label: 'Acompte (70%)',
                  amount: o.depositAmount,
                  deposit: true),
            if (o.status == VehicleOrderStatus.arrivePort && !o.balancePaid)
              _paymentBlock(
                  label: 'Solde (30%)',
                  amount: o.balanceAmount,
                  deposit: false),
            // Documents (facture puis contrat) delivres par la structure.
            if (o.hasInvoice || o.hasContract) ...[
              const SizedBox(height: 12),
              const Text('Mes documents',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                if (o.hasInvoice)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDoc('facture'),
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('Ma facture'),
                    ),
                  ),
                if (o.hasInvoice && o.hasContract) const SizedBox(width: 8),
                if (o.hasContract)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDoc('contrat'),
                      icon: const Icon(Icons.assignment, size: 18),
                      label: const Text('Mon contrat'),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 16),
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

  /// Bloc d'instructions de paiement vehicule (virement/especes) +
  /// bouton « J'ai effectue le paiement » qui notifie l'equipe.
  Widget _paymentBlock(
      {required String label, required num? amount, required bool deposit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label à régler : ${Formatters.fcfa(amount)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 6),
          const Text(
            'Le paiement d\'un véhicule se fait par virement bancaire ou en '
            'espèces. Contactez-nous pour les coordonnées, puis confirmez ci-dessous.',
            style: TextStyle(fontSize: 12.5, color: AppColors.anthracite),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openWhatsapp(label),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Nous contacter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _declare(deposit: deposit),
                icon: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: const Text('J\'ai payé'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _openWhatsapp(String subject) async {
    final url = AppInfo.whatsappUrl(
        message: 'Bonjour, je souhaite régler le $subject de ma commande '
            'véhicule (${widget.order.vehicleReference}).');
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

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
