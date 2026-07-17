import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
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
    try {
      final path = '${widget.order.clientId}/$name-${widget.order.id}.pdf';
      final url =
          await ref.read(vehicleOrderServiceProvider).documentUrl(path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _snack('Ouverture impossible : $e');
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
            const Divider(height: 32),
            // --- Confirmation des paiements (virement/espèces) ---
            const Text('Paiements (virement / espèces)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (!_depositPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busyDoc ? null : () => _confirmPayment(deposit: true),
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                      'Confirmer l\'acompte reçu (${Formatters.fcfa(o.depositAmount)})'),
                ),
              ),
            if (_depositPaid && !_balancePaid) ...[
              if (!_depositPaid) const SizedBox(height: 8),
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
            const Divider(height: 32),
            const Text('Faire avancer le statut',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<VehicleOrderStatus>(
              initialValue: _status,
              isExpanded: true,
              items: VehicleOrderStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('${s.step}. ${s.label}')))
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
