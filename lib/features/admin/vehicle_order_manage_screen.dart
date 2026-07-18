import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/open_external.dart';
import '../../models/vehicle_enums.dart';
import '../../models/vehicle_order.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../../providers/vehicle_order_providers.dart';
import '../shared/vehicle_timeline.dart';

/// Admin : pilotage d'une commande véhicule (statut + expédition maritime).
class VehicleOrderManageScreen extends ConsumerStatefulWidget {
  final VehicleOrder order;
  const VehicleOrderManageScreen({super.key, required this.order});

  @override
  ConsumerState<VehicleOrderManageScreen> createState() =>
      _VehicleOrderManageScreenState();
}

class _VehicleOrderManageScreenState
    extends ConsumerState<VehicleOrderManageScreen> {
  late VehicleOrderStatus _status;
  late final TextEditingController _tracking;
  late final TextEditingController _company;
  DateTime? _departure;
  DateTime? _arrival;
  bool _saving = false;
  // État local (le widget.order passe est immuable).
  late bool _depositPaid;
  late bool _balancePaid;
  late bool _hasInvoice;
  late bool _hasContract;
  bool _busyDoc = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _tracking = TextEditingController(text: widget.order.trackingNumber ?? '');
    _company = TextEditingController(text: widget.order.shippingCompany ?? '');
    _departure = widget.order.estimatedDeparture;
    _arrival = widget.order.estimatedArrival;
    _depositPaid = widget.order.depositPaid;
    _balancePaid = widget.order.balancePaid;
    _hasInvoice = widget.order.hasInvoice;
    _hasContract = widget.order.hasContract;
  }

  Future<void> _releaseReservation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Relâcher la réservation ?'),
        content: const Text(
            'Le véhicule sera remis au catalogue et la commande marquée '
            'expirée. Action irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Relâcher')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyDoc = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .releaseReservation(widget.order.id!);
      setState(() => _status = VehicleOrderStatus.expiree);
      ref.invalidate(vehicleOrdersAdminProvider);
      ref.invalidate(vehicleListingsProvider);
      _snack('Réservation relâchée, véhicule remis au catalogue');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busyDoc = false);
    }
  }

  Future<String?> _pickPaymentMethod() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Mode de paiement reçu',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (final m in const ['Virement', 'Espèces'])
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppColors.vert),
              title: Text(m),
              onTap: () => Navigator.pop(context, m),
            ),
        ]),
      ),
    );
  }

  Future<void> _confirmPayment({required bool deposit}) async {
    final method = await _pickPaymentMethod();
    if (method == null) return;
    setState(() => _busyDoc = true);
    try {
      final svc = ref.read(vehicleOrderServiceProvider);
      if (deposit) {
        await svc.confirmDeposit(widget.order.id!, method);
        setState(() {
          _depositPaid = true;
          _status = VehicleOrderStatus.commandeConfirmee;
        });
      } else {
        await svc.confirmBalance(widget.order.id!, method);
        setState(() {
          _balancePaid = true;
          _status = VehicleOrderStatus.pretRecuperation;
        });
      }
      ref.invalidate(vehicleOrdersAdminProvider);
      _snack(deposit ? 'Acompte confirme' : 'Solde confirme');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busyDoc = false);
    }
  }

  Future<void> _generate({required bool invoice}) async {
    setState(() => _busyDoc = true);
    try {
      final svc = ref.read(vehicleOrderServiceProvider);
      if (invoice) {
        await svc.generateInvoice(widget.order);
        setState(() => _hasInvoice = true);
      } else {
        await svc.generateContract(widget.order);
        setState(() => _hasContract = true);
      }
      ref.invalidate(vehicleOrdersAdminProvider);
      _snack(invoice ? 'Facture générée' : 'Contrat généré');
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _busyDoc = false);
    }
  }

  Future<void> _openDoc(String name) async {
    final path = '${widget.order.clientId}/$name-${widget.order.id}.pdf';
    try {
      await openSignedUrl(
          ref.read(vehicleOrderServiceProvider).documentUrl(path));
    } catch (e) {
      _snack('Ouverture impossible : $e');
    }
  }

  /// Envoi assisté : ouvre WhatsApp vers le client avec un message pré-rempli
  /// (liens facture + contrat en URL signée 7 jours + suite du process).
  Future<void> _sendWhatsapp() async {
    final o = widget.order;
    final number = o.clientWhatsapp;
    if (number == null || number.trim().isEmpty) {
      _snack('Numéro WhatsApp du client indisponible.');
      return;
    }
    setState(() => _busyDoc = true);
    try {
      final svc = ref.read(vehicleOrderServiceProvider);
      const week = Duration(days: 7);
      final links = <String>[];
      if (_hasInvoice) {
        final u = await svc.documentUrl(
            '${o.clientId}/facture-${o.id}.pdf',
            expiry: week);
        links.add('Facture : $u');
      }
      if (_hasContract) {
        final u = await svc.documentUrl(
            '${o.clientId}/contrat-${o.id}.pdf',
            expiry: week);
        links.add('Contrat : $u');
      }
      final vehicle =
          ref.read(vehicleByRefProvider(o.vehicleReference)).valueOrNull;
      final title = vehicle?.title ?? o.vehicleReference;
      final msg = 'Bonjour ${o.clientName ?? ''},\n\n'
          'Votre commande du véhicule $title est confirmée. Voici vos documents :\n'
          '${links.join('\n')}\n\n'
          'La suite du process :\n'
          '• Achat du véhicule en Corée\n'
          '• Préparation puis mise en container (60-90 jours)\n'
          '• Arrivée au port (dédouanement à votre charge)\n'
          '• Solde de 30 % avant la remise du véhicule\n\n'
          'Merci de votre confiance — ${AppInfo.appName}.';
      final url = AppInfo.whatsappTo(number, msg);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _snack('Envoi impossible : $e');
    } finally {
      if (mounted) setState(() => _busyDoc = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  void dispose() {
    _tracking.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _saveStatus() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .advanceStatus(widget.order.id!, _status);
      ref.invalidate(vehicleOrdersAdminProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Statut : ${_status.label}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveShipping() async {
    setState(() => _saving = true);
    try {
      await ref.read(vehicleOrderServiceProvider).setShipping(
            orderId: widget.order.id!,
            trackingNumber:
                _tracking.text.trim().isEmpty ? null : _tracking.text.trim(),
            shippingCompany:
                _company.text.trim().isEmpty ? null : _company.text.trim(),
            departure: _departure,
            arrival: _arrival,
          );
      ref.invalidate(vehicleOrdersAdminProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expédition enregistrée.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool departure) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (departure ? _departure : _arrival) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) {
      setState(() => departure ? _departure = d : _arrival = d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final vehicle = ref.watch(vehicleByRefProvider(o.vehicleReference));
    final title = vehicle.valueOrNull?.title ?? o.vehicleReference;

    return Scaffold(
      appBar: AppBar(title: const Text('Piloter la commande')),
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
            // Prix + paiements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _row('Prix total', o.totalPrice),
                  _row('Acompte (70%)', o.depositAmount, paid: _depositPaid),
                  _row('Solde (30%)', o.balanceAmount, paid: _balancePaid),
                ]),
              ),
            ),
            // --- Réservation (véhicule bloqué 72 h) ---
            if (_status == VehicleOrderStatus.enAttenteAcompte ||
                _status == VehicleOrderStatus.expiree) ...[
              const Divider(height: 32),
              const Text('Réservation',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (_status == VehicleOrderStatus.expiree)
                const Text('Réservation expirée — véhicule remis au catalogue.',
                    style: TextStyle(color: AppColors.gris, fontSize: 12.5))
              else ...[
                Text(
                  o.reservationDeadline != null
                      ? 'Échéance des 72 h : ${Formatters.date(o.reservationDeadline)}'
                      : 'Véhicule réservé — acompte 70 % attendu.',
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.gris),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busyDoc ? null : _releaseReservation,
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text('Relâcher la réservation'),
                  ),
                ),
              ],
            ],
            if (o.depositAppointmentAt != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.grisClair,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.event, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'RDV acompte (agence) : ${Formatters.date(o.depositAppointmentAt)}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ]),
              ),
            ],
            const Divider(height: 32),
            // --- Paiements (à confirmer APRÈS vérification de la réception) ---
            const Text('Paiements',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (o.depositMethod != null && !_depositPaid)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.ambre.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Le client déclare avoir payé : ${o.depositMethod}'
                        '${o.depositReference != null ? ' — réf ${o.depositReference}' : ''}',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                        '⚠ Vérifiez que les fonds sont bien reçus et non annulables '
                        '(virements / mobile money réversibles) avant de confirmer.',
                        style:
                            TextStyle(fontSize: 11.5, color: Color(0xFF7A5A00))),
                  ],
                ),
              ),
            if (!_depositPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busyDoc ? null : () => _confirmPayment(deposit: true),
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                      'Confirmer l\'acompte 70 % reçu (${Formatters.fcfa(o.depositAmount)})'),
                ),
              ),
            if (_depositPaid && !_balancePaid) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busyDoc ? null : () => _confirmPayment(deposit: false),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                      'Confirmer le solde reçu (${Formatters.fcfa(o.balanceAmount)})'),
                ),
              ),
            ],
            if (_depositPaid && _balancePaid)
              const Text('Acompte et solde confirmes.',
                  style: TextStyle(color: AppColors.vert, fontSize: 12.5)),
            const Divider(height: 32),
            // --- Documents : facture puis contrat ---
            const Text('Documents',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Generez d\'abord la facture, puis le contrat.',
                style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busyDoc ? null : () => _generate(invoice: true),
                  icon: const Icon(Icons.description, size: 18),
                  label: Text(_hasInvoice ? 'Regenerer facture' : 'Générer facture'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_busyDoc || !_hasInvoice)
                      ? null
                      : () => _generate(invoice: false),
                  icon: const Icon(Icons.assignment, size: 18),
                  label:
                      Text(_hasContract ? 'Regenerer contrat' : 'Générer contrat'),
                ),
              ),
            ]),
            if (_hasInvoice || _hasContract) ...[
              const SizedBox(height: 8),
              Row(children: [
                if (_hasInvoice)
                  TextButton.icon(
                    onPressed: () => _openDoc('facture'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ouvrir facture'),
                  ),
                if (_hasContract)
                  TextButton.icon(
                    onPressed: () => _openDoc('contrat'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ouvrir contrat'),
                  ),
              ]),
            ],
            if (_hasInvoice && _hasContract) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busyDoc ? null : _sendWhatsapp,
                  icon: const Icon(Icons.chat),
                  label: const Text('Envoyer au client (WhatsApp)'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white),
                ),
              ),
              const Text(
                  'Ouvre WhatsApp vers le client : liens des 2 documents + suite du process.',
                  style: TextStyle(fontSize: 11, color: AppColors.gris)),
            ],
            const Divider(height: 32),
            const Text('Faire avancer le statut',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<VehicleOrderStatus>(
              initialValue: VehicleOrderStatus.trackingSteps.contains(_status)
                  ? _status
                  : VehicleOrderStatus.enAttenteAcompte,
              isExpanded: true,
              items: VehicleOrderStatus.trackingSteps
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (s) => setState(() => _status = s ?? _status),
            ),
            const SizedBox(height: 6),
            const Text(
                'Passe a « Arrive au port » pour permettre au client de payer '
                'le solde de 30%.',
                style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _saving ? null : _saveStatus,
                child: const Text('Enregistrer le statut')),
            const Divider(height: 32),
            const Text('Expédition maritime',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
                controller: _tracking,
                decoration:
                    const InputDecoration(labelText: 'Numéro de tracking')),
            const SizedBox(height: 12),
            TextField(
                controller: _company,
                decoration: const InputDecoration(
                    labelText: 'Compagnie maritime')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _DateField(
                    label: 'Depart estime',
                    value: _departure,
                    onTap: () => _pickDate(true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                    label: 'Arrivee estimee',
                    value: _arrival,
                    onTap: () => _pickDate(false)),
              ),
            ]),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: _saving ? null : _saveShipping,
                child: const Text('Enregistrer l\'expédition')),
            const Divider(height: 32),
            const Text('Historique',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            VehicleTimeline(current: o.status),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, num? value, {bool? paid}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Row(children: [
              if (paid == true)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child:
                      Icon(Icons.check_circle, size: 16, color: AppColors.vert),
                ),
              Text(Formatters.fcfa(value),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        child: Text(value == null ? '—' : Formatters.date(value)),
      ),
    );
  }
}
