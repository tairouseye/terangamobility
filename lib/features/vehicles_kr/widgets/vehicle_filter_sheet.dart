import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/vehicle_filter.dart';
import '../../../providers/vehicle_catalog_providers.dart';

/// Feuille de filtres du catalogue véhicules :
/// Marque -> Modèle (listes dependantes), Année « a partir de »,
/// Carburant, Transmission, Couleur, Kilométrage max (paliers).
class VehicleFilterSheet extends ConsumerStatefulWidget {
  const VehicleFilterSheet({super.key});

  @override
  ConsumerState<VehicleFilterSheet> createState() => _VehicleFilterSheetState();
}

class _VehicleFilterSheetState extends ConsumerState<VehicleFilterSheet> {
  late VehicleFilter _draft;

  static const _mileageTiers = [50000, 100000, 150000, 200000];

  // Paliers de prix en FCFA (1 M -> 20 M).
  static const _priceTiers = [
    1000000, 2000000, 3000000, 4000000, 5000000, 6000000, 7000000, 8000000,
    10000000, 12000000, 15000000, 20000000,
  ];

  static String _priceLabel(int fcfa) => '${(fcfa / 1000000).round()} M';

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

    // Modèles dependants de la marque choisie.
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
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // --- Marque -> Modèle (dependants) ---
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
              label: 'Modèle',
              value: _draft.model,
              hint: _draft.brand == null
                  ? 'Choisir une marque d\'abord'
                  : 'Tous',
              items: models,
              itemLabel: (m) => m,
              enabled: _draft.brand != null,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(model: v)),
            ),

            // --- Plage d'année (min / max) ---
            const _SectionLabel('Année'),
            Row(children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'À partir de',
                  value: _draft.year,
                  hint: 'Min',
                  items: years,
                  itemLabel: (y) => '$y',
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(year: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown<int>(
                  label: 'Jusqu\'à',
                  value: _draft.yearMax,
                  hint: 'Max',
                  items: years,
                  itemLabel: (y) => '$y',
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(yearMax: v)),
                ),
              ),
            ]),

            // --- Plage de prix (min / max), en millions de FCFA ---
            const _SectionLabel('Prix (FCFA)'),
            Row(children: [
              Expanded(
                child: _dropdown<int>(
                  label: 'À partir de',
                  value: _draft.priceMin,
                  hint: 'Min',
                  items: _priceTiers,
                  itemLabel: _priceLabel,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(priceMin: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown<int>(
                  label: 'Jusqu\'à',
                  value: _draft.priceMax,
                  hint: 'Max',
                  items: _priceTiers,
                  itemLabel: _priceLabel,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(priceMax: v)),
                ),
              ),
            ]),

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

            // --- Kilométrage max (paliers) ---
            _dropdown<int>(
              label: 'Kilométrage maximum',
              value: _draft.maxMileage,
              hint: 'Illimité',
              items: _mileageTiers,
              itemLabel: (km) => 'Jusqu\'à ${_fmt(km)} km',
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
                  ? 'Voir tous les véhicules'
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
  /// proprement au reset et quand la liste dependante (modèles) change.
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

/// Petit intitule de section au-dessus d'un groupe de champs.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.black54)),
      );
}
