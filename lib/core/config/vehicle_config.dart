/// Parametres metier du parcours vehicule (reservation, paiements).
///
/// Centralise ici pour un ajustement a un seul endroit. Les numeros mobile
/// money sont des PLACEHOLDERS (numero d'assistance) tant que la structure
/// n'a pas fourni ses comptes Wave / Orange Money dedies.
class VehicleConfig {
  const VehicleConfig._();

  /// Duree de validite d'une reservation : le client a 72 h pour payer les 70 %
  /// avant remise du vehicule au catalogue.
  static const Duration reservationWindow = Duration(hours: 72);

  /// Comptes mobile money de la structure (a confirmer / remplacer).
  static const String waveNumber = '+221 77 343 59 28';
  static const String orangeMoneyNumber = '+221 77 343 59 28';
}
