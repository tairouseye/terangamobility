import '../models/vehicle_listing.dart';

/// Seam d'IMPORT des annonces vers `vehicle_listings`.
///
/// Responsabilite : recuperer les annonces d'une source externe (Encar —
/// https://car.encar.com/ — aujourd'hui), les transformer vers notre modele
/// [VehicleListing], puis les enregistrer dans Supabase.
///
/// --- OU CE CODE DOIT TOURNER ---
/// PAS dans le client Flutter : un scraping/import doit s'executer cote serveur
/// (Supabase Edge Function planifiee, worker Node/Python, cron...) pour des
/// raisons de fiabilite, de performance et de conformite aux CGU d'Encar.
/// L'application, elle, ne fait que LIRE via [VehicleDataSource].
///
/// --- EVOLUTIVITE ---
/// Le jour ou une API officielle (Encar ou autre) existe, on implemente une
/// nouvelle classe conforme a cette interface (ex: EncarApiImporter) sans
/// toucher au reste de l'application.
abstract class VehicleImporter {
  /// Recupere et normalise les annonces depuis la source externe.
  Future<List<VehicleListing>> fetchExternalListings();

  /// Identifiant lisible de la source (pour tracabilite).
  String get sourceName;
}

/// Importateur Encar (https://car.encar.com/) — PLACEHOLDER.
///
/// L'implementation reelle (API officielle si disponible, sinon service
/// d'import autorise cote serveur) sera branchee ici. Volontairement non
/// implemente cote client : voir la documentation ci-dessus.
class EncarImporter implements VehicleImporter {
  @override
  String get sourceName => 'encar';

  @override
  Future<List<VehicleListing>> fetchExternalListings() async {
    throw UnimplementedError(
      'L\'import Encar s\'execute cote serveur (Edge Function / worker) et '
      'alimente la table vehicle_listings. L\'application ne fait que lire ce '
      'catalogue via VehicleDataSource.',
    );
  }
}
