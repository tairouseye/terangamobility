import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/open_external.dart';
import '../../../models/vehicle_enums.dart';
import '../../../models/vehicle_order.dart';
import '../../../providers/vehicle_catalog_providers.dart';
import '../../../providers/vehicle_order_providers.dart';
import '../../shared/vehicle_timeline.dart';

/// Client : suivi d'une commande véhicule (réservation 72 h, acompte 70 %,
/// suivi maritime, solde 30 %, documents).
class VehicleTrackingScreen extends ConsumerStatefulWidget {
  final VehicleOrder order;
  const VehicleTrackingScreen({super.key, required this.order});

  @override
  ConsumerState<VehicleTrackingScreen> createState() =>
      _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState extends ConsumerState<VehicleTrackingScreen> {
  bool _busy = false;
  Timer? _ticker;

  // État local du paiement de l'acompte 70 %.
  String _channel = 'Mobile money'; // Espèces | Virement | Mobile money
  final _reference = TextEditingController();
  late bool _declared; // acompte déjà déclaré ?
  DateTime? _rdv;

  @override
  void initState() {
    super.initState();
    _declared = widget.order.depositMethod != null;
    _rdv = widget.order.depositAppointmentAt;
    // Compte à rebours des 72 h tant que l'acompte n'est pas payé.
    if (widget.order.status == VehicleOrderStatus.enAttenteAcompte) {
      _ticker =
          Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _declareDeposit() async {
    if (_channel != 'Espèces' && _reference.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entrez le n° de transaction de votre paiement.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final ref0 = _channel == 'Espèces'
          ? (_rdv != null ? 'RDV ${Formatters.date(_rdv)}' : 'Espèces agence')
          : _reference.text.trim();
      await ref
          .read(vehicleOrderServiceProvider)
          .declareDeposit(widget.order.id!, _channel, ref0);
      ref.invalidate(myVehicleOrdersProvider);
      if (mounted) {
        setState(() => _declared = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Merci ! Nous vérifions la réception et confirmons la commande.')));
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

  Future<void> _declareBalance() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .declarePayment(widget.order.id!, 'balance');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Merci ! Notre équipe vérifie et confirme sous peu.')));
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

  Future<void> _bookRdv() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Choisir le jour du RDV',
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Heure du RDV',
    );
    if (time == null) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    setState(() => _busy = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .bookDepositAppointment(widget.order.id!, at);
      ref.invalidate(myVehicleOrdersProvider);
      if (mounted) setState(() => _rdv = at);
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
    final path = '${widget.order.clientId}/$name-${widget.order.id}.pdf';
    try {
      await openSignedUrl(
          ref.read(vehicleOrderServiceProvider).documentUrl(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ouverture impossible : $e')));
      }
    }
  }

  Future<void> _openWhatsapp(String subject) async {
    final url = AppInfo.whatsappUrl(
        message: 'Bonjour, je souhaite régler le $subject de ma commande '
            'véhicule (${widget.order.vehicleReference}).');
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
            // Récap paiements
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
            // Infos commande + expédition
            Card(
              color: AppColors.grisClair,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _info('N° de commande',
                        o.id?.substring(0, 8).toUpperCase()),
                    _info('N° de tracking', o.trackingNumber),
                    _info('Compagnie maritime', o.shippingCompany),
                    _info('Départ estimé', Formatters.date(o.estimatedDeparture)),
                    _info('Arrivée estimée', Formatters.date(o.estimatedArrival)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- Acompte 70 % (réservation en cours) ---
            if (o.status == VehicleOrderStatus.enAttenteAcompte &&
                !o.depositPaid)
              _depositBlock(o),
            if (o.status == VehicleOrderStatus.expiree)
              _infoBlock(
                icon: Icons.lock_clock,
                color: AppColors.gris,
                title: 'Réservation expirée',
                body:
                    'Le délai de 72 h est écoulé et le véhicule a été remis au '
                    'catalogue. Vous pouvez le réserver à nouveau s\'il est '
                    'encore disponible.',
              ),
            // --- Solde 30 % (véhicule au port) ---
            if (o.status == VehicleOrderStatus.arrivePort && !o.balancePaid)
              _balanceBlock(o),
            // Suite du process (une fois la commande confirmée)
            if (o.status.index >= VehicleOrderStatus.commandeConfirmee.index &&
                o.status != VehicleOrderStatus.expiree)
              _infoBlock(
                icon: Icons.route,
                color: AppColors.primary,
                title: 'La suite du process',
                body:
                    'Achat en Corée → préparation → mise en container (60-90 j) '
                    '→ arrivée au port. Le dédouanement est à votre charge. '
                    'Le solde de 30 % est à régler avant la remise du véhicule.',
              ),
            // Documents
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

  /// Acompte 70 % : compte à rebours 72 h + paiement multi-canal + déclaration.
  Widget _depositBlock(VehicleOrder o) {
    final left = o.reservationTimeLeft ?? Duration.zero;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ambre.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ambre.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.timer, color: Color(0xFFB07C00), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Acompte 70 % à payer — ${_fmtLeft(left)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF7A5A00))),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Montant : ${Formatters.fcfa(o.depositDue)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF7A5A00))),
          const SizedBox(height: 10),
          if (_declared)
            const Text('Paiement déclaré — en attente de vérification.',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.vert))
          else ...[
            const Text('Choisissez votre moyen de paiement :',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF7A5A00))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in const ['Espèces', 'Virement', 'Mobile money'])
                  ChoiceChip(
                    label: Text(c),
                    selected: _channel == c,
                    onSelected: (_) => setState(() => _channel = c),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_channel == 'Espèces')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.blanc,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.event, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        _rdv == null
                            ? 'Prendre un RDV en agence'
                            : 'RDV : ${Formatters.date(_rdv)}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _bookRdv,
                    child: Text(_rdv == null ? 'Choisir' : 'Modifier'),
                  ),
                ]),
              )
            else
              TextField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'N° de transaction',
                  hintText: 'ex : ID Wave / référence virement',
                  isDense: true,
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Pour les virements et mobile money, la commande est confirmée '
              'après vérification de la réception (paiements réversibles).',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF7A5A00)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsapp('acompte'),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Nous contacter'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _declareDeposit,
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
        ],
      ),
    );
  }

  /// Solde 30 % (véhicule arrivé au port).
  Widget _balanceBlock(VehicleOrder o) {
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
          Text('Solde 30 % à régler : ${Formatters.fcfa(o.balanceAmount)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 6),
          const Text(
            'À régler avant la remise du véhicule (espèces ou virement). '
            'L\'équipe confirme à réception.',
            style: TextStyle(fontSize: 12.5, color: AppColors.anthracite),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openWhatsapp('solde'),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Nous contacter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _declareBalance,
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

  Widget _infoBlock(
      {required IconData icon,
      required Color color,
      required String title,
      required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.anthracite)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtLeft(Duration d) {
    if (d <= Duration.zero) return 'expiré';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h >= 1) return 'il reste ${h}h${m.toString().padLeft(2, '0')}';
    return 'il reste $m min';
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
