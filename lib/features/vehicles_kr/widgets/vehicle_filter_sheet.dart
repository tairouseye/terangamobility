import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/vehicle_filter.dart';
import '../../../providers/vehicle_catalog_providers.dart';

/// Feuille de filtres du catalogue vehicules :
/// Marque -> Modele (listes dependantes), Annee « a partir de »,
/// Carburant, Transmission, Couleur, Kilometrage max (paliers).
class VehicleFilterSheet extends ConsumerStatefulWidget {
  const VehicleFilterSheet({super.key});

  @override
  ConsumerState<VehicleFilterSheet> createState() => _VehicleFilterSheetState();
}

class _VehicleFilterSheetState extends ConsumerState<VehicleFilterSheet> {
  late VehicleFilter _draft;

  static const _mileageTiers = [50000, 100000, 150000, 200000];

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

    // Modeles dependants de la marque choisie.
    final models = _draft.brand == null
        ? const <String>[]
        : (ref.watch(vehicleModelsProvider(_draft.brand!)).valueOrNull ??
            const []);

    final nowYear = DateTime.now().year;
    final years = [for (var y = nowYear; y >= nowYear - 10; y--) y];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
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
            const SizedBox(height: 4),

            // --- Marque -> Modele (dependants) ---
            _dropdown<String>(
              label: 'Marque',
              value: _draft.brand,
              hint: 'Toutes',
              items: brands,
              itemLabel: (b) => b,
              onChanged: (v) => setState(() =>
                  _draft = _draft.copyWith(brand: v, model: null)),
            ),
            _dropdown<String>(
              label: 'Modele',
              value: _draft.model,
              hint: _draft.brand == null
                  ? 'Choisir une marque d\'abord'
                  : 'Tous',
              items: models,
              itemLabel: (m) => m,
              enabled: _draft.brand != null,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(model: v)),
            ),

            // --- Annee a partir de ---
            _dropdown<int>(
              label: 'Annee (a partir de)',
              value: _draft.year,
              hint: 'Toutes',
              items: years,
              itemLabel: (y) => 'A partir de $y',
              onChanged: (v) => setState(() => _draft = _draft.copyWith(year: v)),
            ),

            // --- Carburant / Transmission / Couleur ---
            _dropdown<String>(
              label: 'Carburant',
              value: _draft.fuel,
              hint: 'Tous',
              items: fuels,
              itemLabel: (e) => e,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(fuel: v)),
            ),
            _dropdown<String>(
              label: 'Transmission',
              value: _draft.transmission,
              hint: 'Toutes',
              items: trans,
              itemLabel: (e) => e,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(transmission: v)),
            ),
            _dropdown<String>(
              label: 'Couleur',
              value: _draft.color,
              hint: 'Toutes',
              items: colors,
              itemLabel: (e) => e,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(color: v)),
            ),

            // --- Kilometrage max (paliers) ---
            _dropdown<int>(
              label: 'Kilometrage maximum',
              value: _draft.maxMileage,
              hint: 'Illimite',
              items: _mileageTiers,
              itemLabel: (km) => 'Jusqu\'a ${_fmt(km)} km',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(maxMileage: v)),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(vehicleFilterProvider.notifier).state = _draft;
                Navigator.of(context).pop();
              },
              child: Text(_draft.activeCount == 0
                  ? 'Voir tous les vehicules'
                  : 'Appliquer (${_draft.activeCount})'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// Dropdown generique avec option « aucune valeur » (null).
  /// La cle inclut la valeur et le nombre d'items : le champ se reinitialise
  /// proprement au reset et quand la liste dependante (modeles) change.
  Widget _dropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    // Valeur toujours coherente avec les options disponibles.
    final T? safe = (value != null && items.contains(value)) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        key: ValueKey('$label-$safe-${items.length}'),
        initialValue: safe,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        hint: Text(hint),
        items: [
          DropdownMenuItem<T>(value: null, child: Text(hint)),
          ...items
              .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e)))),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
