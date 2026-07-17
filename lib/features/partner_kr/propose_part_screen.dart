import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/parts_request.dart';
import '../../models/supplier_quote.dart';
import '../../providers/auth_providers.dart';
import '../../providers/partner_providers.dart';

/// Formulaire de proposition de pièce par le partenaire Corée (Lot 4).
class ProposePartScreen extends ConsumerStatefulWidget {
  final PartsRequest request;
  const ProposePartScreen({super.key, required this.request});

  @override
  ConsumerState<ProposePartScreen> createState() => _ProposePartScreenState();
}

class _ProposePartScreenState extends ConsumerState<ProposePartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partRef = TextEditingController();
  final _priceKrw = TextEditingController();
  final _weight = TextEditingController();
  final _dimensions = TextEditingController();
  final _leadTime = TextEditingController();
  bool _available = true;
  XFile? _photo;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _partRef.dispose();
    _priceKrw.dispose();
    _weight.dispose();
    _dimensions.dispose();
    _leadTime.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _photo = img);
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
      String? photoUrl;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final ext = _photo!.name.split('.').last;
        photoUrl = await ref
            .read(storageServiceProvider)
            .uploadPartPhoto(uid, bytes, ext: ext.isEmpty ? 'jpg' : ext);
      }

      final quote = SupplierQuote(
        requestId: widget.request.id!,
        partnerId: uid,
        partRef: _partRef.text.trim().isEmpty ? null : _partRef.text.trim(),
        available: _available,
        buyPriceKrw: num.tryParse(_priceKrw.text.trim()),
        weightKg: num.tryParse(_weight.text.trim().replaceAll(',', '.')),
        dimensions:
            _dimensions.text.trim().isEmpty ? null : _dimensions.text.trim(),
        photoUrl: photoUrl,
        leadTimeDays: int.tryParse(_leadTime.text.trim()),
      );

      await ref.read(supplierQuoteServiceProvider).submit(quote);
      ref.invalidate(openRequestsProvider);
      ref.invalidate(quotesForRequestProvider(widget.request.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposition envoyée a TerangaMobility.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Envoi impossible : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('Proposer une pièce')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RequestSummary(request: r),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pièce disponible'),
                value: _available,
                activeThumbColor: AppColors.vert,
                onChanged: (v) => setState(() => _available = v),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _partRef,
                decoration: const InputDecoration(
                    labelText: 'Référence de la pièce'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceKrw,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Prix d\'achat (KRW) *',
                    hintText: 'Prix en wons coréens'),
                validator: (v) => (num.tryParse(v?.trim() ?? '') == null)
                    ? 'Prix requis'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Poids (kg) *'),
                validator: (v) => (num.tryParse(
                            (v ?? '').trim().replaceAll(',', '.')) ==
                        null)
                    ? 'Poids requis (transport FedEx)'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dimensions,
                decoration: const InputDecoration(
                    labelText: 'Dimensions', hintText: 'L x l x h (cm)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _leadTime,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Délai d\'approvisionnement (jours)'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(_photo != null ? Icons.check_circle : Icons.image,
                    color: _photo != null ? AppColors.vert : AppColors.gris),
                label: Text(_photo != null
                    ? _photo!.name
                    : 'Ajouter une photo de la pièce'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  alignment: Alignment.centerLeft,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.primary)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Envoyer la proposition'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rappel de la demande (pièce + véhicule) pour aider le partenaire.
class _RequestSummary extends StatelessWidget {
  final PartsRequest request;
  const _RequestSummary({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.grisClair,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.partName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _line(Icons.directions_car, request.vehicleLabel),
            if (request.vehicleEngine != null)
              _line(Icons.settings, 'Motorisation : ${request.vehicleEngine}'),
            if (request.vehicleVin != null)
              _line(Icons.tag, 'VIN : ${request.vehicleVin}'),
            if (request.notes != null)
              _line(Icons.notes, request.notes!),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.gris),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(color: AppColors.anthracite))),
          ],
        ),
      );
}
