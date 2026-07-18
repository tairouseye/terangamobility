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

/// Statut d'une commande vehicule.
///
/// Prelude reservation (`enAttenteReservation`, `reservee`) + etapes du suivi
/// maritime + etat terminal `expiree`. L'ordre suit l'enum Postgres.
enum VehicleOrderStatus {
  enAttenteReservation,
  reservee,
  enAttenteAcompte,
  commandeConfirmee,
  vehiculeAchete,
  preparation,
  chargeContainer,
  navireEnMer,
  arrivePort,
  pretRecuperation,
  livre,
  expiree;

  String get dbValue => switch (this) {
        VehicleOrderStatus.enAttenteReservation => 'en_attente_reservation',
        VehicleOrderStatus.reservee => 'reservee',
        VehicleOrderStatus.enAttenteAcompte => 'en_attente_acompte',
        VehicleOrderStatus.commandeConfirmee => 'commande_confirmee',
        VehicleOrderStatus.vehiculeAchete => 'vehicule_achete',
        VehicleOrderStatus.preparation => 'preparation',
        VehicleOrderStatus.chargeContainer => 'charge_container',
        VehicleOrderStatus.navireEnMer => 'navire_en_mer',
        VehicleOrderStatus.arrivePort => 'arrive_port',
        VehicleOrderStatus.pretRecuperation => 'pret_recuperation',
        VehicleOrderStatus.livre => 'livre',
        VehicleOrderStatus.expiree => 'expiree',
      };

  String get label => switch (this) {
        VehicleOrderStatus.enAttenteReservation =>
          'En attente de réservation',
        VehicleOrderStatus.reservee => 'Réservé',
        VehicleOrderStatus.enAttenteAcompte => 'Réservé — acompte 70 %',
        VehicleOrderStatus.commandeConfirmee => 'Commande confirmée',
        VehicleOrderStatus.vehiculeAchete => 'Véhicule acheté',
        VehicleOrderStatus.preparation => 'Préparation du véhicule',
        VehicleOrderStatus.chargeContainer => 'Chargé dans le container',
        VehicleOrderStatus.navireEnMer => 'Navire en mer',
        VehicleOrderStatus.arrivePort => 'Arrivé au port',
        VehicleOrderStatus.pretRecuperation => 'Prêt à être récupéré',
        VehicleOrderStatus.livre => 'Livré',
        VehicleOrderStatus.expiree => 'Réservation expirée',
      };

  /// Etapes affichees dans la timeline maritime (hors prelude reservation et
  /// etat terminal `expiree`).
  static const List<VehicleOrderStatus> trackingSteps = [
    enAttenteAcompte,
    commandeConfirmee,
    vehiculeAchete,
    preparation,
    chargeContainer,
    navireEnMer,
    arrivePort,
    pretRecuperation,
    livre,
  ];

  bool get isReservationPhase =>
      this == enAttenteReservation || this == reservee;

  int get step => index + 1;

  Color get color => switch (this) {
        VehicleOrderStatus.livre ||
        VehicleOrderStatus.pretRecuperation =>
          AppColors.vert,
        VehicleOrderStatus.enAttenteReservation => AppColors.ambre,
        VehicleOrderStatus.reservee => AppColors.primary,
        VehicleOrderStatus.expiree => AppColors.gris,
        VehicleOrderStatus.enAttenteAcompte => AppColors.ambre,
        _ => AppColors.ambre,
      };

  static VehicleOrderStatus fromDb(String? v) =>
      VehicleOrderStatus.values.firstWhere((s) => s.dbValue == v,
          orElse: () => VehicleOrderStatus.enAttenteAcompte);
}
