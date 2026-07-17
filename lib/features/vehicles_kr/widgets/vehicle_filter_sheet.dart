import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/vehicle_filter.dart';
import '../../../providers/vehicle_catalog_providers.dart';

/// Feuille de filtres du catalogue vehicules.
class VehicleFilterSheet extends ConsumerStatefulWidget {
  const VehicleFilterSheet({super.key});

  @override
  ConsumerState<VehicleFilterSheet> createState() => _VehicleFilterSheetState();
}

class _VehicleFilterSheetState extends ConsumerState<VehicleFilterSheet> {
  late VehicleFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(vehicleFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(vehicleBrandsProvider).valueOrNull ?? const [];
    final fuels = ref.watch(vehicleFuelsProvider).valueOrNull ?? const [];
    final trans =
        ref.watch(vehicleTransmissionsProvider).valueOrNull ?? const [];
    final colors = ref.watch(vehicleColorsProvider).valueOrNull ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scroll,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtrer',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: () =>
                      setState(() => _draft = const VehicleFilter()),
                  child: const Text('Reinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _dropdown('Marque', _draft.brand, brands,
                (v) => setState(() => _draft = _draft.copyWith(brand: v))),
            _dropdown('Carburant', _draft.fuel, fuels,
                (v) => setState(() => _draft = _draft.copyWith(fuel: v))),
            _dropdown('Transmission', _draft.transmission, trans,
                (v) => setState(() => _draft = _draft.copyWith(transmission: v))),
            _dropdown('Couleur', _draft.color, colors,
                (v) => setState(() => _draft = _draft.copyWith(color: v))),
            const SizedBox(height: 8),
            _TextFilter(
              label: 'Modele (mot-cle)',
              value: _draft.model,
              keyboard: TextInputType.text,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(model: v)),
            ),
            _TextFilter(
              label: 'Annee',
              value: _draft.year?.toString(),
              keyboard: TextInputType.number,
              onChanged: (v) => setState(() =>
                  _draft = _draft.copyWith(year: v == null ? null : int.tryParse(v))),
            ),
            _TextFilter(
              label: 'Kilometrage maximum',
              value: _draft.maxMileage?.toString(),
              keyboard: TextInputType.number,
              onChanged: (v) => setState(() => _draft =
                  _draft.copyWith(maxMileage: v == null ? null : int.tryParse(v))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(vehicleFilterProvider.notifier).state = _draft;
                Navigator.of(context).pop();
              },
              child: const Text('Appliquer les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        hint: const Text('Tous'),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Tous')),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _TextFilter extends StatefulWidget {
  final String label;
  final String? value;
  final TextInputType keyboard;
  final ValueChanged<String?> onChanged;
  const _TextFilter({
    required this.label,
    required this.value,
    required this.keyboard,
    required this.onChanged,
  });

  @override
  State<_TextFilter> createState() => _TextFilterState();
}

class _TextFilterState extends State<_TextFilter> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c,
        keyboardType: widget.keyboard,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: _c.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _c.clear();
                    widget.onChanged(null);
                  },
                ),
        ),
        onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
      ),
    );
  }
}

/// Couleur d'accent reutilisable pour le badge de filtre actif.
const filterAccent = AppColors.primary;
