import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_info.dart';
import '../../core/config/parts_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/parts_request.dart';
import '../../models/supplier_quote.dart';
import '../../providers/auth_providers.dart';
import '../../providers/partner_providers.dart';
import '../../providers/quote_providers.dart';
import 'build_quote_screen.dart';

/// Admin : sourcing d'une piece via Partswini (Autowini) puis saisie de la
/// proposition fournisseur. A la validation, la demande passe a 'piece_trouvee'
/// (trigger) et on ouvre le chiffrage du devis.
class SourcePartScreen extends ConsumerStatefulWidget {
  final PartsRequest request;
  const SourcePartScreen({super.key, required this.request});

  @override
  ConsumerState<SourcePartScreen> createState() => _SourcePartScreenState();
}

class _SourcePartScreenState extends ConsumerState<SourcePartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partRef = TextEditingController();
  final _priceKrw = TextEditingController();
  final _weight = TextEditingController();
  final _dimensions = TextEditingController();
  final _leadTime = TextEditingController();
  final _sourceUrl = TextEditingController();
  bool _available = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _partRef,
      _priceKrw,
      _weight,
      _dimensions,
      _leadTime,
      _sourceUrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _whatsappMessage() {
    final r = widget.request;
    final lines = <String>[
      'Bonjour, je recherche une piece :',
      'Piece : ${r.partName}',
      'Vehicule : ${r.vehicleLabel}',
      if (r.vehicleEngine != null && r.vehicleEngine!.isNotEmpty)
        'Motorisation : ${r.vehicleEngine}',
      if (r.vehicleVin != null && r.vehicleVin!.isNotEmpty)
        'VIN : ${r.vehicleVin}',
      if (r.notes != null && r.notes!.isNotEmpty) 'Details : ${r.notes}',
      '',
      'Pouvez-vous me donner la reference exacte, le prix et la disponibilite ? Merci.',
    ];
    return lines.join('\n');
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authServiceProvider).currentUser?.id;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final quote = SupplierQuote(
        requestId: widget.request.id!,
        partnerId: uid, // l'admin joue le role de sourcing
        partRef: _partRef.text.trim().isEmpty ? null : _partRef.text.trim(),
        available: _available,
        buyPriceKrw: num.tryParse(_priceKrw.text.trim()),
        weightKg: num.tryParse(_weight.text.trim().replaceAll(',', '.')),
        dimensions:
            _dimensions.text.trim().isEmpty ? null : _dimensions.text.trim(),
        leadTimeDays: int.tryParse(_leadTime.text.trim()),
        source: 'partswini',
        sourceUrl:
            _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
      );
      await ref.read(supplierQuoteServiceProvider).submit(quote);
      ref.invalidate(newPartsRequestsProvider);
      ref.invalidate(requestsToQuoteProvider);
      ref.invalidate(quotesForRequestProvider(widget.request.id!));
      if (mounted) {
        // Enchaine sur le chiffrage du devis.
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BuildQuoteScreen(request: widget.request),
        ));
      }
    } catch (e) {
      setState(() => _error = 'Enregistrement impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('Sourcer la pièce')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Récap de la demande
              Card(
                color: AppColors.grisClair,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.partName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      _info('Véhicule', r.vehicleLabel),
                      _info('Motorisation', r.vehicleEngine),
                      _info('VIN', r.vehicleVin),
                      _info('Reçue le', Formatters.date(r.createdAt)),
                      if (r.notes != null && r.notes!.isNotEmpty)
                        _info('Détails', r.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('1. Sourcer sur Partswini',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(PartsConfig.partswiniCatalogUrl),
                    icon: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('Ouvrir Partswini'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _open(AppInfo.whatsappTo(
                        PartsConfig.partswiniWhatsapp, _whatsappMessage())),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Fournisseur'),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              const Text(
                  'Le message WhatsApp est pré-rempli avec le véhicule, le VIN et la pièce.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
              const Divider(height: 32),
              const Text('2. Saisir la proposition',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pièce disponible'),
                value: _available,
                activeThumbColor: AppColors.vert,
                onChanged: (v) => setState(() => _available = v),
              ),
              _field(_partRef, 'Référence / n° de pièce'),
              _field(_priceKrw, 'Prix d\'achat (KRW) *',
                  keyboard: TextInputType.number, required: true),
              _field(_weight, 'Poids (kg)',
                  keyboard: const TextInputType.numberWithOptions(decimal: true)),
              _field(_dimensions, 'Dimensions (L x l x h cm)'),
              _field(_leadTime, 'Délai fournisseur (jours)',
                  keyboard: TextInputType.number),
              _field(_sourceUrl, 'Lien Partswini (interne)',
                  keyboard: TextInputType.url),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.calculate),
                label: const Text('Enregistrer et chiffrer le devis'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.gris))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null
            : null,
      ),
    );
  }
}
