import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Compteurs « à traiter » pour le tableau de bord admin.
/// Chaque champ = nombre d'éléments qui demandent une action.
class AdminCounts {
  final int vehicleRequests; // demandes véhicule en attente de devis
  final int vehicleOrders; // commandes véhicule actives (hors livré/expiré)
  final int partsNew; // demandes de pièces à sourcer
  final int partsToQuote; // pièces trouvées, à chiffrer
  final int partsOrders; // commandes pièces actives (hors livrée)
  final int clients; // total clients

  const AdminCounts({
    this.vehicleRequests = 0,
    this.vehicleOrders = 0,
    this.partsNew = 0,
    this.partsToQuote = 0,
    this.partsOrders = 0,
    this.clients = 0,
  });
}

/// Charge tous les compteurs admin (autoDispose : recalculés à chaque affichage
/// du dashboard). Les tables concernées sont petites -> requêtes légères.
final adminCountsProvider = FutureProvider.autoDispose<AdminCounts>((ref) async {
  final c = ref.watch(supabaseClientProvider);

  Future<int> len(Future<dynamic> q) async => (await q as List).length;

  // Statuts terminaux à exclure pour « actif ».
  const vehicleDone = {'livre', 'expiree'};
  const partsDone = {'livree'};

  final results = await Future.wait(<Future<dynamic>>[
    // Demandes véhicule en attente de devis.
    len(c
        .from('vehicle_requests')
        .select('id')
        .eq('status', 'en_attente_devis')),
    // Commandes véhicule : on récupère les statuts et on compte les actives.
    c.from('vehicle_orders').select('status'),
    // Demandes de pièces à sourcer.
    len(c
        .from('parts_requests')
        .select('id')
        .inFilter('status', ['nouvelle_demande', 'recherche_coree'])),
    // Pièces trouvées, à chiffrer.
    len(c.from('parts_requests').select('id').eq('status', 'piece_trouvee')),
    // Commandes pièces : statuts -> actives.
    c.from('orders').select('status'),
    // Total clients.
    len(c.from('profiles').select('id').eq('role', 'client')),
  ]);

  int activeCount(dynamic rows, Set<String> done) => (rows as List)
      .where((r) => !done.contains((r as Map)['status']?.toString()))
      .length;

  return AdminCounts(
    vehicleRequests: results[0] as int,
    vehicleOrders: activeCount(results[1], vehicleDone),
    partsNew: results[2] as int,
    partsToQuote: results[3] as int,
    partsOrders: activeCount(results[4], partsDone),
    clients: results[5] as int,
  );
});
