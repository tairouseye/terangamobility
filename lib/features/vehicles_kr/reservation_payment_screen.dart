import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/vehicle_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/vehicle_order_providers.dart';

/// Paiement de l'acompte de reservation (mobile money) apres avoir reserve
/// un vehicule. Le client paie sur un numero Wave/Orange Money puis declare
/// le paiement ; l'admin verifie et confirme.
class ReservationPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String vehicleTitle;
  final int feeFcfa;
  const ReservationPaymentScreen({
    super.key,
    required this.orderId,
    required this.vehicleTitle,
    required this.feeFcfa,
  });

  @override
  ConsumerState<ReservationPaymentScreen> createState() =>
      _ReservationPaymentScreenState();
}

class _ReservationPaymentScreenState
    extends ConsumerState<ReservationPaymentScreen> {
  String _method = 'Wave';
  bool _busy = false;

  Future<void> _declare() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(vehicleOrderServiceProvider)
          .declareReservationPayment(widget.orderId, _method);
      ref.invalidate(myVehicleOrdersProvider);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.verified, color: AppColors.vert, size: 40),
          title: const Text('Réservation enregistrée'),
          content: const Text(
              'Merci ! Nous vérifions votre paiement et sécurisons le véhicule. '
              'Vous serez notifié dès la confirmation. Suivez l\'avancement dans '
              '« Mes véhicules ».'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(); // cet ecran
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = _method == 'Wave'
        ? VehicleConfig.waveNumber
        : VehicleConfig.orangeMoneyNumber;
    return Scaffold(
      appBar: AppBar(title: const Text('Payer la réservation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.vehicleTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Véhicule réservé pour vous — 48 h pour confirmer.',
                style: TextStyle(color: AppColors.gris, fontSize: 13)),
            const SizedBox(height: 16),
            // Montant
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acompte de réservation',
                      style: TextStyle(fontSize: 13, color: AppColors.gris)),
                  const SizedBox(height: 4),
                  Text(Formatters.fcfa(widget.feeFcfa),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const SizedBox(height: 6),
                  const Text(
                      'Déduit du prix total. Non remboursable en cas d\'annulation '
                      'de votre part (le véhicule est sécurisé pour vous).',
                      style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('1. Choisissez votre moyen',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              _methodChip('Wave'),
              const SizedBox(width: 8),
              _methodChip('Orange Money'),
            ]),
            const SizedBox(height: 20),
            Text('2. Envoyez ${Formatters.fcfa(widget.feeFcfa)} au numéro',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.grisClair,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                    _method == 'Wave'
                        ? Icons.account_balance_wallet
                        : Icons.phone_android,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_method — ${VehicleConfig.reservationFeeFcfa}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gris)),
                      Text(numero,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            const Text(
                'Indiquez la référence du véhicule dans le motif si possible.',
                style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
            const SizedBox(height: 24),
            const Text('3. Confirmez',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _busy ? null : _declare,
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('J\'ai payé la réservation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String m) {
    final selected = _method == m;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = m),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.grisClair,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2),
          ),
          child: Center(
            child: Text(m,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.primary : AppColors.anthracite)),
          ),
        ),
      ),
    );
  }
}
