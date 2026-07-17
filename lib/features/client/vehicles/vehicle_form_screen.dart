import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/vehicle.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/vehicle_providers.dart';

/// Formulaire de creation / edition d'un vehicule.
class VehicleFormScreen extends ConsumerStatefulWidget {
  final Vehicle? existing;
  const VehicleFormScreen({super.key, this.existing});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _engine;
  late final TextEditingController _vin;

  String? _carteGriseUrl;
  XFile? _pickedCarteGrise;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _brand = TextEditingController(text: v?.brand ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: v?.year?.toString() ?? '');
    _engine = TextEditingController(text: v?.engine ?? '');
    _vin = TextEditingController(text: v?.vin ?? '');
    _carteGriseUrl = v?.carteGriseUrl;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _engine.dispose();
    _vin.dispose();
    super.dispose();
  }

  Future<void> _pickCarteGrise() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _pickedCarteGrise = img);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authServiceProvider).currentUser?.id;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Upload de la carte grise si une nouvelle image a ete choisie.
      if (_pickedCarteGrise != null) {
        final bytes = await _pickedCarteGrise!.readAsBytes();
        final ext = _pickedCarteGrise!.name.split('.').last;
        _carteGriseUrl = await ref
            .read(storageServiceProvider)
            .uploadCarteGrise(uid, bytes, ext: ext.isEmpty ? 'jpg' : ext);
      }

      final vehicle = Vehicle(
        id: widget.existing?.id,
        userId: uid,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text.trim()),
        engine: _engine.text.trim().isEmpty ? null : _engine.text.trim(),
        vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
        carteGriseUrl: _carteGriseUrl,
      );

      await ref.read(vehicleServiceProvider).upsert(vehicle);
      ref.invalidate(myVehiclesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Enregistrement impossible : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isEdit ? 'Modifier le vehicule' : 'Nouveau vehicule')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _brand,
                decoration: const InputDecoration(
                    labelText: 'Marque *', hintText: 'Hyundai, Kia...'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _model,
                decoration: const InputDecoration(
                    labelText: 'Modele *', hintText: 'Tucson, Sportage...'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annee'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _engine,
                decoration: const InputDecoration(
                    labelText: 'Motorisation', hintText: '2.0 CRDi, essence...'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vin,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'VIN (numero de chassis)'),
              ),
              const SizedBox(height: 20),
              _CarteGriseField(
                hasImage: _pickedCarteGrise != null || _carteGriseUrl != null,
                pickedName: _pickedCarteGrise?.name,
                onPick: _pickCarteGrise,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.primary)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteGriseField extends StatelessWidget {
  final bool hasImage;
  final String? pickedName;
  final VoidCallback onPick;
  const _CarteGriseField({
    required this.hasImage,
    required this.pickedName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: Icon(hasImage ? Icons.check_circle : Icons.upload_file,
          color: hasImage ? AppColors.vert : AppColors.gris),
      label: Text(
        hasImage
            ? (pickedName ?? 'Carte grise enregistree — modifier')
            : 'Ajouter la photo de la carte grise',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
