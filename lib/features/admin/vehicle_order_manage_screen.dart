import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_enums.dart';
import '../../models/vehicle_order.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../../providers/vehicle_order_providers.dart';
import '../shared/vehicle_timeline.dart';

/// Admin : pilotage d'une commande vehicule (statut + expedition maritime).
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

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _tracking = TextEditingController(text: widget.order.trackingNumber ?? '');
    _company = TextEditingController(text: widget.order.shippingCompany ?? '');
    _departure = widget.order.estimatedDeparture;
    _arrival = widget.order.estimatedArrival;
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
            const SnackBar(content: Text('Expedition enregistree.')));
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
                  _row('Acompte (70%)', o.depositAmount,
                      paid: o.depositPaid),
                  _row('Solde (30%)', o.balanceAmount, paid: o.balancePaid),
                ]),
              ),
            ),
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
            const Text('Expedition maritime',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
                controller: _tracking,
                decoration:
                    const InputDecoration(labelText: 'Numero de tracking')),
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
                child: const Text('Enregistrer l\'expedition')),
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
