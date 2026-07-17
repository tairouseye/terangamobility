import '../models/vehicle_filter.dart';
import '../models/vehicle_listing.dart';
import '../models/vehicle_request.dart';
import '../services/vehicle_data_source.dart';
import '../services/vehicle_request_service.dart';

/// Source de catalogue EN MEMOIRE pour le mode demo (aucun Supabase).
/// Represente ce que l'import Encar (car.encar.com) deposerait dans
/// vehicle_listings.
class DemoVehicleDataSource implements VehicleDataSource {
  /// En demo, on genere des visuels ETIQUETES au nom du modele (placeholders).
  /// En production, ce sont les vraies URLs des photos de l'annonce Encar.
  static List<String> _photos(String label, int count) => List.generate(
        count,
        (i) => 'https://placehold.co/800x450/1C1C1E/FFFFFF/png'
            '?text=${Uri.encodeComponent('$label\n${i + 1} / $count')}',
      );

  static final List<VehicleListing> _listings = [
    VehicleListing(
      id: 'vl-1',
      reference: 'EC-SF19-001',
      brand: 'Hyundai',
      model: 'Santa Fe',
      year: 2019,
      version: '2.2 CRDi 4WD Premium',
      engine: '2.2 CRDi Diesel',
      displacement: '2199 cc',
      mileageKm: 78000,
      transmission: 'Automatique',
      fuel: 'Diesel',
      color: 'Blanc',
      doors: 5,
      steering: 'left',
      location: 'Incheon, Coree du Sud',
      condition: 'Occasion - excellent etat',
      options: const [
        'Climatisation',
        'GPS',
        'Camera de recul',
        'Sieges cuir',
        'Toit ouvrant',
        'Regulateur de vitesse',
      ],
      description:
          'Hyundai Santa Fe 2019 en tres bon etat, entretien a jour, '
          'ideal familial. 7 places, transmission integrale 4WD.',
      photos: _photos('Hyundai Santa Fe 2019', 3),
    ),
    VehicleListing(
      id: 'vl-2',
      reference: 'EC-SOR20-014',
      brand: 'Kia',
      model: 'Sorento',
      year: 2020,
      version: '2.2 CRDi Signature',
      engine: '2.2 CRDi Diesel',
      displacement: '2151 cc',
      mileageKm: 52000,
      transmission: 'Automatique',
      fuel: 'Diesel',
      color: 'Noir',
      doors: 5,
      steering: 'left',
      location: 'Busan, Coree du Sud',
      condition: 'Occasion - tres bon etat',
      options: const [
        'Climatisation automatique',
        'GPS',
        'Camera 360',
        'Sieges chauffants',
        'Hayon electrique',
      ],
      description:
          'Kia Sorento 2020 Signature, faible kilometrage, full options.',
      photos: _photos('Kia Sorento 2020', 3),
    ),
    VehicleListing(
      id: 'vl-3',
      reference: 'EC-TUC18-102',
      brand: 'Hyundai',
      model: 'Tucson',
      year: 2018,
      version: '2.0 GDi Style',
      engine: '2.0 GDi Essence',
      displacement: '1999 cc',
      mileageKm: 96000,
      transmission: 'Automatique',
      fuel: 'Essence',
      color: 'Gris',
      doors: 5,
      steering: 'left',
      location: 'Seoul, Coree du Sud',
      condition: 'Occasion - bon etat',
      options: const ['Climatisation', 'Bluetooth', 'Camera de recul'],
      description: 'Hyundai Tucson 2018 essence, fiable et economique.',
      photos: _photos('Hyundai Tucson 2018', 2),
    ),
    VehicleListing(
      id: 'vl-4',
      reference: 'EC-MOR21-045',
      brand: 'Kia',
      model: 'Morning',
      year: 2021,
      version: '1.0 Comfort',
      engine: '1.0 Essence',
      displacement: '998 cc',
      mileageKm: 31000,
      transmission: 'Automatique',
      fuel: 'Essence',
      color: 'Rouge',
      doors: 5,
      steering: 'left',
      location: 'Incheon, Coree du Sud',
      condition: 'Occasion - comme neuf',
      options: const ['Climatisation', 'Bluetooth'],
      description: 'Kia Morning 2021 citadine, tres faible kilometrage.',
      photos: _photos('Kia Morning 2021', 2),
    ),
    VehicleListing(
      id: 'vl-5',
      reference: 'EC-G80-19-007',
      brand: 'Genesis',
      model: 'G80',
      year: 2019,
      version: '3.3 T-GDi AWD',
      engine: '3.3 T-GDi Essence',
      displacement: '3342 cc',
      mileageKm: 64000,
      transmission: 'Automatique',
      fuel: 'Essence',
      color: 'Bleu nuit',
      doors: 4,
      steering: 'left',
      location: 'Seoul, Coree du Sud',
      condition: 'Occasion - excellent etat',
      options: const [
        'Cuir Nappa',
        'Toit ouvrant panoramique',
        'Sono premium',
        'Sieges ventiles',
        'Aide au stationnement',
      ],
      description: 'Genesis G80 berline premium, confort et performances.',
      photos: _photos('Genesis G80 2019', 3),
    ),
  ];

  @override
  Future<List<VehicleListing>> fetchListings(VehicleFilter f) async {
    Iterable<VehicleListing> r = _listings;
    if (f.brand != null) r = r.where((v) => v.brand == f.brand);
    if (f.model != null) {
      r = r.where(
          (v) => v.model.toLowerCase().contains(f.model!.toLowerCase()));
    }
    if (f.year != null) r = r.where((v) => (v.year ?? 0) >= f.year!);
    if (f.fuel != null) r = r.where((v) => v.fuel == f.fuel);
    if (f.transmission != null) {
      r = r.where((v) => v.transmission == f.transmission);
    }
    if (f.color != null) r = r.where((v) => v.color == f.color);
    if (f.maxMileage != null) {
      r = r.where((v) => (v.mileageKm ?? 0) <= f.maxMileage!);
    }
    if (f.keyword != null && f.keyword!.trim().isNotEmpty) {
      final k = f.keyword!.toLowerCase();
      r = r.where((v) =>
          v.brand.toLowerCase().contains(k) ||
          v.model.toLowerCase().contains(k) ||
          (v.version ?? '').toLowerCase().contains(k) ||
          v.reference.toLowerCase().contains(k));
    }
    return r.toList();
  }

  @override
  Future<VehicleListing?> fetchByReference(String reference) async {
    for (final v in _listings) {
      if (v.reference == reference) return v;
    }
    return null;
  }

  @override
  Future<List<String>> distinctValues(String field) async {
    String? pick(VehicleListing v) => switch (field) {
          'brand' => v.brand,
          'model' => v.model,
          'fuel' => v.fuel,
          'transmission' => v.transmission,
          'color' => v.color,
          _ => null,
        };
    final set = <String>{};
    for (final v in _listings) {
      final x = pick(v);
      if (x != null && x.isNotEmpty) set.add(x);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Future<List<String>> modelsForBrand(String brand) async {
    final set = _listings
        .where((v) => v.brand == brand)
        .map((v) => v.model)
        .toSet()
        .toList()
      ..sort();
    return set;
  }
}

/// Service de demande de prix factice (mode demo).
class DemoVehicleRequestService extends VehicleRequestService {
  DemoVehicleRequestService(super.client);

  @override
  Future<String> submit({
    required String vehicleReference,
    required String customerName,
    required String phone,
    String? whatsapp,
    String? email,
    String? country,
    String? city,
    String? message,
  }) async =>
      'demo-vehicle-request';

  @override
  Future<List<VehicleRequest>> listForClient() async => [];
}
