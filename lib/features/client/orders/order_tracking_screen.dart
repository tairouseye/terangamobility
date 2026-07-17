import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/enums.dart';
import '../../../models/order_view.dart';
import '../../../providers/quote_providers.dart';
import '../../shared/order_timeline.dart';

/// Suivi detaille d'une commande cote client (Lot 7).
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final OrderView orderView;
  const OrderTrackingScreen({super.key, required this.orderView});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _paying = false;

  Future<void> _payBalance() async {
    final method = await _pickMethod();
    if (method == null) return;
    setState(() => _paying = true);
    try {
      await ref.read(orderServiceProvider).payBalance(
            orderId: widget.orderView.order.id!,
            method: method,
          );
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solde regle. Merci !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement impossible : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<String?> _pickMethod() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Mode de paiement du solde',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final m in const ['Wave', 'Orange Money', 'Especes', 'Virement'])
              ListTile(
                leading: const Icon(Icons.payments, color: AppColors.vert),
                title: Text(m),
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.orderView;
    final orderId = v.order.id!;
    final shipmentAsync = ref.watch(shipmentProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de commande')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(v.partName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(v.vehicleLabel, style: const TextStyle(color: AppColors.gris)),
            const SizedBox(height: 16),
            // Recap paiements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _amountRow('Total commande', v.total, bold: true),
                    _amountRow('Acompte (70%)', v.deposit,
                        paid: v.order.depositPaid),
                    _amountRow('Solde (30%)', v.balance,
                        paid: v.order.balancePaid),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Expedition
            shipmentAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) {
                if (s == null || s.fedexTracking == null) {
                  return const SizedBox.shrink();
                }
                return Card(
                  color: AppColors.grisClair,
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping,
                        color: AppColors.anthracite),
                    title: Text('FedEx : ${s.fedexTracking}'),
                    subtitle: Text([
                      if (s.transitaire != null) 'Transitaire ${s.transitaire}',
                      if (s.eta != null) 'ETA ${Formatters.date(s.eta)}',
                    ].join('  •  ')),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Bouton solde si demande
            if (v.status == OrderStatus.soldeDemande && !v.order.balancePaid)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _paying ? null : _payBalance,
                  icon: _paying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payments),
                  label: Text(
                      'Payer le solde (${Formatters.fcfa(v.balance)})'),
                ),
              ),
            const Text('Etat d\'avancement',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            OrderTimeline(current: v.status),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, num value,
      {bool bold = false, bool? paid}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Row(
            children: [
              if (paid == true)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_circle,
                      size: 16, color: AppColors.vert),
                ),
              Text(Formatters.fcfa(value),
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ],
      ),
    );
  }
}
