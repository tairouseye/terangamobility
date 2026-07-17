import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/parts_request.dart';
import '../../models/quote_breakdown.dart';
import '../../models/supplier_quote.dart';
import '../../providers/partner_providers.dart';
import '../../providers/quote_providers.dart';
import '../shared/quote_breakdown_card.dart';

/// Categories de douane (doivent correspondre a la table customs_rates).
const _customsCategories = ['general', 'carrosserie', 'électronique', 'mecanique'];

/// Ecran admin : chiffrer et envoyer un devis a partir d'une proposition
/// partenaire (Lot 5).
class BuildQuoteScreen extends ConsumerStatefulWidget {
  final PartsRequest request;
  const BuildQuoteScreen({super.key, required this.request});

  @override
  ConsumerState<BuildQuoteScreen> createState() => _BuildQuoteScreenState();
}

class _BuildQuoteScreenState extends ConsumerState<BuildQuoteScreen> {
  SupplierQuote? _selected;
  String _category = 'general';
  QuoteBreakdown? _breakdown;
  bool _computing = false;
  bool _sending = false;
  String? _error;

  Future<void> _compute() async {
    if (_selected == null) return;
    setState(() {
      _computing = true;
      _error = null;
    });
    try {
      final b = await ref.read(quoteServiceProvider).compute(
            supplierQuoteId: _selected!.id!,
            customsCategory: _category,
          );
      setState(() => _breakdown = b);
    } catch (e) {
      setState(() => _error = 'Calcul impossible : $e');
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  Future<void> _send() async {
    if (_selected == null || _breakdown == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(quoteServiceProvider).sendQuote(
            requestId: widget.request.id!,
            supplierQuoteId: _selected!.id!,
            b: _breakdown!,
            validUntil: DateTime.now().add(const Duration(days: 7)),
          );
      ref.invalidate(requestsToQuoteProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devis envoyé au client.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Envoi impossible : $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync =
        ref.watch(quotesForRequestProvider(widget.request.id!));
    return Scaffold(
      appBar: AppBar(title: const Text('Chiffrer le devis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.request.partName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(widget.request.vehicleLabel,
                style: const TextStyle(color: AppColors.gris)),
            const SizedBox(height: 20),
            const Text('1. Proposition partenaire',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            quotesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e'),
              data: (quotes) {
                if (quotes.isEmpty) {
                  return const Text('Aucune proposition reçue.',
                      style: TextStyle(color: AppColors.gris));
                }
                _selected ??= quotes.first;
                return RadioGroup<SupplierQuote>(
                  groupValue: _selected,
                  onChanged: (v) => setState(() {
                    _selected = v;
                    _breakdown = null;
                  }),
                  child: Column(
                    children: quotes
                        .map((q) => RadioListTile<SupplierQuote>(
                              value: q,
                              title: Text(
                                  '${Formatters.fcfa(q.buyPriceKrw)} KRW  •  ${q.weightKg ?? '?'} kg'),
                              subtitle: Text([
                                if (q.partRef != null) 'Ref ${q.partRef}',
                                if (q.leadTimeDays != null)
                                  'Délai ${q.leadTimeDays} j',
                                if (!q.available) 'INDISPONIBLE',
                              ].join('  •  ')),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('2. Catégorie de douane',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _customsCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _category = v ?? 'general';
                _breakdown = null;
              }),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_selected == null || _computing) ? null : _compute,
              icon: _computing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.calculate),
              label: const Text('Calculer le prix total'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            if (_breakdown != null) ...[
              const SizedBox(height: 20),
              QuoteBreakdownCard(breakdown: _breakdown!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Envoyer le devis au client'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.primary)),
            ],
          ],
        ),
      ),
    );
  }
}
