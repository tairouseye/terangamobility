import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Statut d'une demande de prix vehicule.
enum VehicleRequestStatus {
  enAttenteDevis,
  devisEnvoye,
  accepte,
  refuse,
  clos;

  String get dbValue => switch (this) {
        VehicleRequestStatus.enAttenteDevis => 'en_attente_devis',
        VehicleRequestStatus.devisEnvoye => 'devis_envoye',
        VehicleRequestStatus.accepte => 'accepte',
        VehicleRequestStatus.refuse => 'refuse',
        VehicleRequestStatus.clos => 'clos',
      };

  String get label => switch (this) {
        VehicleRequestStatus.enAttenteDevis => 'En attente de devis',
        VehicleRequestStatus.devisEnvoye => 'Devis envoyé',
        VehicleRequestStatus.accepte => 'Accepté',
        VehicleRequestStatus.refuse => 'Refusé',
        VehicleRequestStatus.clos => 'Clos',
      };

  static VehicleRequestStatus fromDb(String? v) =>
      VehicleRequestStatus.values.firstWhere((s) => s.dbValue == v,
          orElse: () => VehicleRequestStatus.enAttenteDevis);
}

/// Statut d'une commande vehicule = etapes du suivi maritime.
enum VehicleOrderStatus {
  enAttenteAcompte,
  commandeConfirmee,
  vehiculeAchete,
  preparation,
  chargeContainer,
  navireEnMer,
  arrivePort,
  pretRecuperation,
  livre;

  String get dbValue => switch (this) {
        VehicleOrderStatus.enAttenteAcompte => 'en_attente_acompte',
        VehicleOrderStatus.commandeConfirmee => 'commande_confirmee',
        VehicleOrderStatus.vehiculeAchete => 'vehicule_achete',
        VehicleOrderStatus.preparation => 'preparation',
        VehicleOrderStatus.chargeContainer => 'charge_container',
        VehicleOrderStatus.navireEnMer => 'navire_en_mer',
        VehicleOrderStatus.arrivePort => 'arrive_port',
        VehicleOrderStatus.pretRecuperation => 'pret_recuperation',
        VehicleOrderStatus.livre => 'livre',
      };

  String get label => switch (this) {
        VehicleOrderStatus.enAttenteAcompte => 'En attente d\'acompte',
        VehicleOrderStatus.commandeConfirmee => 'Commande confirmée',
        VehicleOrderStatus.vehiculeAchete => 'Véhicule acheté',
        VehicleOrderStatus.preparation => 'Préparation du véhicule',
        VehicleOrderStatus.chargeContainer => 'Chargé dans le container',
        VehicleOrderStatus.navireEnMer => 'Navire en mer',
        VehicleOrderStatus.arrivePort => 'Arrivé au port',
        VehicleOrderStatus.pretRecuperation => 'Prêt à être récupéré',
        VehicleOrderStatus.livre => 'Livré',
      };

  int get step => index + 1;

  Color get color {
    if (this == VehicleOrderStatus.livre ||
        this == VehicleOrderStatus.pretRecuperation) {
      return AppColors.vert;
    }
    if (this == VehicleOrderStatus.enAttenteAcompte) return AppColors.gris;
    return AppColors.ambre;
  }

  static VehicleOrderStatus fromDb(String? v) =>
      VehicleOrderStatus.values.firstWhere((s) => s.dbValue == v,
          orElse: () => VehicleOrderStatus.enAttenteAcompte);
}
