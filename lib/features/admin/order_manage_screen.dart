import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/order_view.dart';
import '../../models/shipment.dart';
import '../../providers/quote_providers.dart';
import '../shared/order_timeline.dart';

/// Admin : pilotage d'une commande (avancer le statut, gerer l'expedition).
class OrderManageScreen extends ConsumerStatefulWidget {
  final OrderView orderView;
  const OrderManageScreen({super.key, required this.orderView});

  @override
  ConsumerState<OrderManageScreen> createState() => _OrderManageScreenState();
}

class _OrderManageScreenState extends ConsumerState<OrderManageScreen> {
  late OrderStatus _status;
  final _tracking = TextEditingController();
  final _transitaire = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.orderView.status;
  }

  @override
  void dispose() {
    _tracking.dispose();
    _transitaire.dispose();
    super.dispose();
  }

  Future<void> _saveStatus() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(orderServiceProvider)
          .advanceStatus(widget.orderView.order.id!, _status);
      ref.invalidate(allOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis a jour : ${_status.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveShipment() async {
    if (_tracking.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(orderServiceProvider).upsertShipment(Shipment(
            orderId: widget.orderView.order.id!,
            fedexTracking: _tracking.text.trim(),
            transitaire: _transitaire.text.trim().isEmpty
                ? null
                : _transitaire.text.trim(),
          ));
      ref.invalidate(shipmentProvider(widget.orderView.order.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expedition enregistree.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.orderView;
    return Scaffold(
      appBar: AppBar(title: const Text('Piloter la commande')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(v.partName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${v.vehicleLabel}  •  ${Formatters.fcfa(v.total)}',
                style: const TextStyle(color: AppColors.gris)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _flag('Acompte', v.order.depositPaid),
                _flag('Solde', v.order.balancePaid),
              ],
            ),
            const Divider(height: 32),
            const Text('Faire avancer le statut',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<OrderStatus>(
              initialValue: _status,
              items: OrderStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('${s.step}. ${s.label}')))
                  .toList(),
              onChanged: (s) => setState(() => _status = s ?? _status),
            ),
            const SizedBox(height: 8),
            const Text(
              'Astuce : selectionne « Solde demande » pour que le client puisse payer les 30%.',
              style: TextStyle(fontSize: 12, color: AppColors.gris),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _saveStatus,
              child: const Text('Enregistrer le statut'),
            ),
            const Divider(height: 32),
            const Text('Expedition FedEx',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _tracking,
              decoration:
                  const InputDecoration(labelText: 'Numero de suivi FedEx'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _transitaire,
              decoration:
                  const InputDecoration(labelText: 'Transitaire (douane)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saving ? null : _saveShipment,
              child: const Text('Enregistrer l\'expedition'),
            ),
            const Divider(height: 32),
            const Text('Historique',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            OrderTimeline(current: v.status),
          ],
        ),
      ),
    );
  }

  Widget _flag(String label, bool ok) => Chip(
        avatar: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18, color: ok ? AppColors.vert : AppColors.gris),
        label: Text('$label ${ok ? 'paye' : 'en attente'}'),
        backgroundColor: (ok ? AppColors.vert : AppColors.gris)
            .withValues(alpha: 0.08),
      );
}
