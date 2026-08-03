import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/encar_image.dart';
import '../../core/utils/encar_price.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_listing.dart';
import '../../providers/vehicle_catalog_providers.dart';
import '../vehicles_kr/facebook_post_helper.dart';
import '../vehicles_kr/vehicle_detail_screen.dart';

/// Admin : suggestion de vehicules a poster sur Facebook.
/// 2 vehicules par tranche de prix (3M -> 14M FCFA), tries par score mixte
/// (faible km + annee recente), filtrables par marque et km max.
class FacebookSelectionScreen extends ConsumerStatefulWidget {
  const FacebookSelectionScreen({super.key});

  @override
  ConsumerState<FacebookSelectionScreen> createState() =>
      _FacebookSelectionScreenState();
}

class _FacebookSelectionScreenState
    extends ConsumerState<FacebookSelectionScreen> {
  int _maxKm = 120000;
  final Set<String> _brands = {}; // vide = toutes

  // Score : recent ET peu roule -> plus haut = mieux.
  double _score(VehicleListing v) =>
      (v.year ?? 2000).toDouble() - (v.mileageKm ?? 999999) / 20000;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(facebookSelectionProvider(_maxKm));
    return Scaffold(
      appBar: AppBar(title: const Text('Sélection Facebook')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
            child: Text('Impossible de charger.',
                style: TextStyle(color: AppColors.gris))),
        data: (all) {
          final brands = (all.map((v) => v.brand).toSet().toList()..sort());
          // Filtre marques
          final filtered = _brands.isEmpty
              ? all
              : all.where((v) => _brands.contains(v.brand)).toList();
          // Regroupe par tranche 3..14 et garde les 2 meilleurs.
          final byBracket = <int, List<VehicleListing>>{};
          for (final v in filtered) {
            final p = v.priceFcfa;
            if (p == null) continue;
            final b = (p / 1000000).floor();
            if (b < 3 || b > 14) continue;
            (byBracket[b] ??= []).add(v);
          }
          for (final list in byBracket.values) {
            list.sort((a, b) => _score(b).compareTo(_score(a)));
          }
          final brackets = [for (var b = 3; b <= 14; b++) b];

          return Column(
            children: [
              _filters(brands),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: [
                    for (final b in brackets)
                      if ((byBracket[b] ?? const []).isNotEmpty)
                        _bracketSection(b, byBracket[b]!.take(2).toList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filters(List<String> brands) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kilométrage max',
              style: TextStyle(fontSize: 12, color: AppColors.gris)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: [
            for (final km in const [80000, 120000, 150000, 999999])
              ChoiceChip(
                label: Text(km == 999999 ? 'Tous' : '${km ~/ 1000}k'),
                selected: _maxKm == km,
                onSelected: (_) => setState(() => _maxKm = km),
              ),
          ]),
          const SizedBox(height: 8),
          const Text('Marques',
              style: TextStyle(fontSize: 12, color: AppColors.gris)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: [
            FilterChip(
              label: const Text('Toutes'),
              selected: _brands.isEmpty,
              onSelected: (_) => setState(() => _brands.clear()),
            ),
            for (final b in brands)
              FilterChip(
                label: Text(b),
                selected: _brands.contains(b),
                onSelected: (s) => setState(() {
                  if (s) {
                    _brands.add(b);
                  } else {
                    _brands.remove(b);
                  }
                }),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _bracketSection(int bracketM, List<VehicleListing> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
          child: Text('≈ ${Formatters.fcfa(bracketM * 1000000)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary)),
        ),
        for (final v in vehicles) _card(v),
      ],
    );
  }

  Widget _card(VehicleListing v) {
    final subtitle = [
      if (v.year != null) '${v.year}',
      if (v.mileageLabel != null) v.mileageLabel!,
      if (v.condition != null && v.condition!.isNotEmpty) v.condition!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 92,
                height: 62,
                child: v.photos.isEmpty
                    ? Container(
                        color: AppColors.grisClair,
                        child: const Icon(Icons.directions_car,
                            color: AppColors.gris))
                    : Image.network(
                        encarPhoto(v.photos.first, height: 200, ratio: 16 / 9),
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, _, _) => Container(
                            color: AppColors.grisClair,
                            child: const Icon(Icons.directions_car,
                                color: AppColors.gris)),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.gris)),
                  const SizedBox(height: 4),
                  Text(Formatters.fcfa(v.priceFcfa),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  if (estimatedEncarPrice(v.priceFcfa) case final e?)
                    Text('Encar brut ≈ ${Formatters.fcfa(e.fcfa)} · \$${e.usd}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF7A5A00))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => prepareFacebookPost(context, v),
                        icon: const Icon(Icons.campaign, size: 16),
                        label: const Text('Préparer post',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => VehicleDetailScreen(
                                  reference: v.reference))),
                      child: const Text('Fiche',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
