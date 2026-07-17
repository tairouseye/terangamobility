import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Roles utilisateurs = les 3 espaces de l'application.
enum UserRole {
  client,
  partnerKr,
  admin;

  String get dbValue => switch (this) {
        UserRole.client => 'client',
        UserRole.partnerKr => 'partner_kr',
        UserRole.admin => 'admin',
      };

  String get label => switch (this) {
        UserRole.client => 'Client',
        UserRole.partnerKr => 'Partenaire Coree',
        UserRole.admin => 'Admin Teranga Parts',
      };

  static UserRole fromDb(String? value) => switch (value) {
        'partner_kr' => UserRole.partnerKr,
        'admin' => UserRole.admin,
        _ => UserRole.client,
      };
}

/// Type de paiement dans le modele 70/30.
enum PaymentType {
  deposit, // acompte 70%
  balance; // solde 30%

  String get dbValue => this == PaymentType.deposit ? 'deposit' : 'balance';

  String get label => this == PaymentType.deposit ? 'Acompte (70%)' : 'Solde (30%)';

  static PaymentType fromDb(String value) =>
      value == 'balance' ? PaymentType.balance : PaymentType.deposit;
}

/// Les 13 statuts du workflow commande, dans l'ordre chronologique.
enum OrderStatus {
  nouvelleDemande,
  rechercheCoree,
  pieceTrouvee,
  devisEnvoye,
  acomptePaye,
  commandeConfirmee,
  pieceAchetee,
  expediee,
  enTransit,
  arriveeSenegal,
  soldeDemande,
  payee,
  livree;

  String get dbValue => switch (this) {
        OrderStatus.nouvelleDemande => 'nouvelle_demande',
        OrderStatus.rechercheCoree => 'recherche_coree',
        OrderStatus.pieceTrouvee => 'piece_trouvee',
        OrderStatus.devisEnvoye => 'devis_envoye',
        OrderStatus.acomptePaye => 'acompte_paye',
        OrderStatus.commandeConfirmee => 'commande_confirmee',
        OrderStatus.pieceAchetee => 'piece_achetee',
        OrderStatus.expediee => 'expediee',
        OrderStatus.enTransit => 'en_transit',
        OrderStatus.arriveeSenegal => 'arrivee_senegal',
        OrderStatus.soldeDemande => 'solde_demande',
        OrderStatus.payee => 'payee',
        OrderStatus.livree => 'livree',
      };

  String get label => switch (this) {
        OrderStatus.nouvelleDemande => 'Nouvelle demande',
        OrderStatus.rechercheCoree => 'Recherche Coree',
        OrderStatus.pieceTrouvee => 'Piece trouvee',
        OrderStatus.devisEnvoye => 'Devis envoye',
        OrderStatus.acomptePaye => 'Acompte paye',
        OrderStatus.commandeConfirmee => 'Commande confirmee',
        OrderStatus.pieceAchetee => 'Piece achetee',
        OrderStatus.expediee => 'Expediee',
        OrderStatus.enTransit => 'En transit',
        OrderStatus.arriveeSenegal => 'Arrivee Senegal',
        OrderStatus.soldeDemande => 'Solde demande',
        OrderStatus.payee => 'Payee',
        OrderStatus.livree => 'Livree',
      };

  int get step => index + 1;

  Color get color {
    if (this == OrderStatus.livree || this == OrderStatus.payee) {
      return AppColors.vert;
    }
    if (this == OrderStatus.nouvelleDemande) return AppColors.gris;
    return AppColors.ambre;
  }

  static OrderStatus fromDb(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => OrderStatus.nouvelleDemande,
    );
  }
}
