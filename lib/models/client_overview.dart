import 'app_user.dart';

/// Ligne de la liste des clients (admin) : profil + compteurs cles.
class ClientSummary {
  final AppUser user;
  final int vehicleCount;
  final int requestCount;
  final int orderCount;
  final num totalOrdered; // total des commandes (devis acceptes)
  final num totalPaid; // total reellement encaisse

  const ClientSummary({
    required this.user,
    this.vehicleCount = 0,
    this.requestCount = 0,
    this.orderCount = 0,
    this.totalOrdered = 0,
    this.totalPaid = 0,
  });

  /// Reste a encaisser (acomptes/soldes non regles).
  num get outstanding => (totalOrdered - totalPaid).clamp(0, double.infinity);
}
