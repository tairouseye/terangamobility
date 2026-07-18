/// Parametres metier du parcours vehicule (reservation, paiements).
///
/// Centralise ici pour un ajustement a un seul endroit. Les numeros mobile
/// money sont des PLACEHOLDERS (numero d'assistance) tant que la structure
/// n'a pas fourni ses comptes Wave / Orange Money dedies.
class VehicleConfig {
  const VehicleConfig._();

  /// Montant fixe de l'acompte de reservation (FCFA), payable par mobile money.
  /// Verrouille le vehicule 48 h et declenche sa securisation sur Encar.
  static const int reservationFeeFcfa = 200000;

  /// Duree de validite d'une reservation avant remise au catalogue.
  static const Duration reservationWindow = Duration(hours: 48);

  /// Comptes mobile money de la structure (a confirmer / remplacer).
  static const String waveNumber = '+221 77 343 59 28';
  static const String orangeMoneyNumber = '+221 77 343 59 28';
}
