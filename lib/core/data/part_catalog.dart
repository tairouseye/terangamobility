/// Catalogue de pieces detachees courantes, organise par categorie, pour
/// aider le client a nommer sa demande (liste deroulante). Une option
/// « Autre » permet toujours une saisie libre.
class PartCatalog {
  const PartCatalog._();

  /// Libelle de l'option de saisie libre.
  static const autre = 'Autre (preciser)';

  /// Categorie -> liste de pieces.
  static const Map<String, List<String>> catalog = {
    'Freinage': [
      'Plaquettes de frein avant',
      'Plaquettes de frein arriere',
      'Disques de frein avant',
      'Disques de frein arriere',
      'Etrier de frein',
      'Maitre-cylindre de frein',
      'Flexible de frein',
      'Cable de frein a main',
    ],
    'Moteur & distribution': [
      'Courroie de distribution',
      'Kit de distribution complet',
      'Courroie d\'accessoire',
      'Pompe a eau',
      'Bougies d\'allumage',
      'Bobine d\'allumage',
      'Injecteur',
      'Joint de culasse',
      'Support moteur',
      'Turbocompresseur',
    ],
    'Filtration': [
      'Filtre a air',
      'Filtre a huile',
      'Filtre a carburant',
      'Filtre d\'habitacle',
    ],
    'Suspension & direction': [
      'Amortisseur avant',
      'Amortisseur arriere',
      'Ressort de suspension',
      'Rotule de direction',
      'Biellette de barre stabilisatrice',
      'Bras de suspension',
      'Roulement de roue',
      'Cardan / arbre de transmission',
      'Cremaillere de direction',
      'Silent-bloc',
    ],
    'Embrayage & transmission': [
      'Kit d\'embrayage',
      'Volant moteur',
      'Butee d\'embrayage',
      'Cable d\'embrayage',
    ],
    'Carrosserie & optique': [
      'Retroviseur droit',
      'Retroviseur gauche',
      'Phare avant droit',
      'Phare avant gauche',
      'Feu arriere droit',
      'Feu arriere gauche',
      'Pare-chocs avant',
      'Pare-chocs arriere',
      'Capot',
      'Aile avant',
      'Calandre',
      'Pare-brise',
    ],
    'Electrique & batterie': [
      'Batterie',
      'Alternateur',
      'Demarreur',
      'Capteur ABS',
      'Sonde lambda',
      'Faisceau electrique',
    ],
    'Refroidissement & clim': [
      'Radiateur',
      'Ventilateur de refroidissement',
      'Thermostat',
      'Durite de refroidissement',
      'Compresseur de climatisation',
      'Condenseur de climatisation',
    ],
    'Echappement': [
      'Ligne d\'echappement',
      'Silencieux',
      'Catalyseur',
      'Vanne EGR',
    ],
    'Autre': [],
  };

  static List<String> get categories => catalog.keys.toList();

  /// Pieces d'une categorie + option « Autre » a la fin.
  static List<String> partsFor(String category) => [
        ...?catalog[category],
        autre,
      ];

  /// Pieces generalement trop volumineuses / lourdes pour un envoi par
  /// messagerie express (FedEx, DHL...). Elles sont signalees au client car
  /// Teranga Parts ne traite que des pieces acheminables par ces transporteurs.
  static const Set<String> oversized = {
    'Pare-chocs avant',
    'Pare-chocs arriere',
    'Capot',
    'Aile avant',
    'Calandre',
    'Pare-brise',
    'Ligne d\'echappement',
    'Silencieux',
    'Radiateur',
  };

  static bool isOversized(String? part) =>
      part != null && oversized.contains(part);
}
