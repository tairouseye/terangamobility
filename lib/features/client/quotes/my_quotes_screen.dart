import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/customer_quote.dart';
import '../../../models/quote_breakdown.dart';
import '../../../providers/quote_providers.dart';
import '../../../providers/request_providers.dart';
import '../../shared/quote_breakdown_card.dart';

/// Client : ses devis, avec detail chiffre et paiement de l'acompte (Lot 5+6).
class MyQuotesScreen extends ConsumerWidget {
  const MyQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myQuotesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes devis')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myQuotesProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (quotes) {
            if (quotes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.gris),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Aucun devis pour le moment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _QuoteCard(quote: quotes[i]),
            );
          },
        ),
      ),
    );
  }
}

class _QuoteCard extends ConsumerStatefulWidget {
  final CustomerQuote quote;
  const _QuoteCard({required this.quote});

  @override
  ConsumerState<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends ConsumerState<_QuoteCard> {
  bool _paying = false;

  QuoteBreakdown get _breakdown => QuoteBreakdown(
        partPrice: widget.quote.partPrice,
        fedexCost: widget.quote.fedexCost,
        customsCost: widget.quote.customsCost,
        commission: widget.quote.commission,
        total: widget.quote.totalFcfa,
      );

  Future<void> _payDeposit() async {
    final method = await _pickMethod();
    if (method == null) return;

    setState(() => _paying = true);
    try {
      await ref.read(orderServiceProvider).payDeposit(
            quoteId: widget.quote.id!,
            method: method,
          );
      ref.invalidate(myQuotesProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(myRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Acompte enregistre. Commande confirmee !')),
        );
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
              child: Text('Mode de paiement de l\'acompte',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final m in const ['Wave', 'Orange Money'])
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
    final q = widget.quote;
    final isSent = q.status == 'sent';
    final isAccepted = q.status == 'accepted';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Devis du ${Formatters.date(q.createdAt)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            _StatusChip(status: q.status),
          ],
        ),
        const SizedBox(height: 10),
        QuoteBreakdownCard(breakdown: _breakdown),
        const SizedBox(height: 10),
        if (isSent)
          ElevatedButton.icon(
            onPressed: _paying ? null : _payDeposit,
            icon: _paying
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle),
            label: Text(
                'Valider et payer l\'acompte (${Formatters.fcfa(_breakdown.deposit)})'),
          ),
        if (isAccepted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.vert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('✓ Acompte payé — commande confirmee',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.vert, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'sent' => ('A valider', AppColors.ambre),
      'accepted' => ('Accepte', AppColors.vert),
      'rejected' => ('Refuse', AppColors.primary),
      _ => ('Brouillon', AppColors.gris),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
