/// Parametres metier du parcours vehicule (reservation, paiements).
///
/// Centralise ici pour un ajustement a un seul endroit.
class VehicleConfig {
  const VehicleConfig._();

  /// Duree de validite d'une reservation : le client a 72 h pour payer les 70 %
  /// avant remise du vehicule au catalogue.
  static const Duration reservationWindow = Duration(hours: 72);

  /// Comptes mobile money de la structure (Wave / Orange Money).
  static const String waveNumber = '+221 77 282 17 82';
  static const String orangeMoneyNumber = '+221 77 282 17 82';
}
