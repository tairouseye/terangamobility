/// Liens vers l'annonce d'origine sur Encar.
///
/// La `reference` d'un vehicule importe est prefixee « EC- » suivie de
/// l'identifiant Encar (voir la fonction d'import). On peut ainsi reconstruire
/// le lien vers l'annonce d'origine — utile cote admin pour VERIFIER que le
/// vehicule est toujours en vente sur Encar (si l'annonce est retiree/vendue,
/// la page Encar affiche un message correspondant).
library;

/// Identifiant Encar extrait de la reference (`EC-41843785` -> `41843785`).
/// null si la reference n'est pas une annonce Encar.
String? encarCarId(String reference) {
  final m = RegExp(r'^EC-(\d+)$').firstMatch(reference.trim());
  return m?.group(1);
}

/// Lien vers l'annonce d'origine sur Encar (page fiche actuelle).
/// null si la reference n'est pas une annonce Encar.
String? encarListingUrl(String reference) {
  final id = encarCarId(reference);
  if (id == null) return null;
  return 'https://fem.encar.com/cars/detail/$id';
}
