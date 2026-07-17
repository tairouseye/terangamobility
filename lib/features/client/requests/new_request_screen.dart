import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/part_catalog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parts_request.dart';
import '../../../models/vehicle.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/request_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../vehicles/vehicle_form_screen.dart';

/// Formulaire de depot d'une nouvelle demande de pièce (Lot 3).
class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customPart = TextEditingController();
  final _notes = TextEditingController();
  Vehicle? _vehicle;
  String? _category;
  String? _selectedPart;
  XFile? _pickedPhoto;
  bool _saving = false;
  String? _error;

  /// Vrai quand il faut afficher le champ texte libre.
  bool get _needsCustom =>
      _category == 'Autre' || _selectedPart == PartCatalog.autre;

  /// Nom final de la pièce (choix dans la liste ou saisie libre).
  String get _resolvedPartName =>
      _needsCustom ? _customPart.text.trim() : (_selectedPart ?? '');

  @override
  void dispose() {
    _customPart.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _pickedPhoto = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resolvedPartName.isEmpty) {
      setState(() => _error = 'Choisissez ou précisez la pièce recherchee.');
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.id;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? photoUrl;
      if (_pickedPhoto != null) {
        final bytes = await _pickedPhoto!.readAsBytes();
        final ext = _pickedPhoto!.name.split('.').last;
        photoUrl = await ref
            .read(storageServiceProvider)
            .uploadPartPhoto(uid, bytes, ext: ext.isEmpty ? 'jpg' : ext);
      }

      final request = PartsRequest(
        clientId: uid,
        vehicleId: _vehicle?.id,
        partName: _resolvedPartName,
        partPhotoUrl: photoUrl,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        // Instantane vehicle fige pour le partenaire Corée.
        vehicleBrand: _vehicle?.brand,
        vehicleModel: _vehicle?.model,
        vehicleYear: _vehicle?.year,
        vehicleEngine: _vehicle?.engine,
        vehicleVin: _vehicle?.vin,
      );

      await ref.read(requestServiceProvider).create(request);
      ref.invalidate(myRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée ! Nous recherchons la pièce.')),
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
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande de pièce')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- Rappel : uniquement pièces expediables ---
              const _ShippingNotice(),
              const SizedBox(height: 20),
              // --- Véhicule concerne ---
              const Text('Véhicule concerne',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              vehiclesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur véhicules : $e'),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return _AddVehiclePrompt(onAdded: () =>
                        ref.invalidate(myVehiclesProvider));
                  }
                  _vehicle ??= vehicles.first;
                  return DropdownButtonFormField<Vehicle>(
                    initialValue: _vehicle,
                    items: vehicles
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text(v.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _vehicle = v),
                  );
                },
              ),
              const SizedBox(height: 20),
              // --- Pièce recherchee (catégorie -> pièce, + saisie libre) ---
              const Text('Pièce recherchee',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Catégorie *'),
                hint: const Text('Choisir une catégorie'),
                items: PartCatalog.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (c) => setState(() {
                  _category = c;
                  _selectedPart = null; // reinitialise la pièce
                }),
              ),
              if (_category != null && _category != 'Autre') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPart,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pièce *'),
                  hint: const Text('Choisir la pièce'),
                  items: PartCatalog.partsFor(_category!)
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (p) => setState(() => _selectedPart = p),
                ),
              ],
              if (_needsCustom) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customPart,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Precisez la pièce *',
                    hintText: 'Ex : support de boite de vitesses',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Precisez la pièce'
                      : null,
                ),
              ],
              if (PartCatalog.isOversized(_selectedPart)) ...[
                const SizedBox(height: 12),
                const _OversizeWarning(),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details / précisions',
                  hintText: 'Référence connue, cote, état...',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(
                    _pickedPhoto != null ? Icons.check_circle : Icons.image,
                    color: _pickedPhoto != null ? AppColors.vert : AppColors.gris),
                label: Text(_pickedPhoto != null
                    ? (_pickedPhoto!.name)
                    : 'Ajouter une photo de la pièce (optionnel)'),
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
                    : const Text('Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rappel permanent : Teranga Parts ne traite que des pièces acheminables
/// par messagerie express (FedEx, DHL...).
class _ShippingNotice extends StatelessWidget {
  const _ShippingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.vert.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vert.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping, color: AppColors.vert, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: AppColors.anthracite, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: 'Pièces expediables uniquement.\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'Nous traitons les pièces transportables par messagerie '
                        'express (FedEx, DHL...). Les pièces très volumineuses '
                        'ou lourdes ne peuvent pas être acheminees.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avertissement affiche quand la pièce choisie est generalement hors gabarit.
class _OversizeWarning extends StatelessWidget {
  const _OversizeWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ambre.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ambre.withValues(alpha: 0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB07C00), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cette pièce est souvent trop volumineuse pour un envoi express. '
              'Vous pouvez envoyer la demande : nous verifierons la faisabilite '
              'et le cout avant tout devis.',
              style: TextStyle(color: Color(0xFF7A5A00), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddVehiclePrompt extends StatelessWidget {
  final VoidCallback onAdded;
  const _AddVehiclePrompt({required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.grisClair,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aucun véhicule enregistre. Ajoutez-en un pour associer la demande.',
              style: TextStyle(color: AppColors.gris),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VehicleFormScreen(),
                ));
                onAdded();
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un véhicule'),
            ),
          ],
        ),
      ),
    );
  }
}
