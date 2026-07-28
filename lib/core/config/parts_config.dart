/// Parametres du sourcing pieces detachees via Partswini (Autowini).
///
/// Integration assistee : l'admin ouvre le catalogue Partswini et contacte le
/// fournisseur par WhatsApp (message pre-rempli avec les infos vehicule),
/// recupere reference + prix, puis saisit la proposition dans l'appli.
///
/// Le numero WhatsApp est un PLACEHOLDER (numero d'assistance) tant que le
/// contact fournisseur Partswini n'a pas ete fourni.
class PartsConfig {
  const PartsConfig._();

  /// Contact WhatsApp du fournisseur / sourcing Partswini (a remplacer).
  static const String partswiniWhatsapp = '+221 77 343 59 28';

  /// Catalogue de recherche des pieces Partswini (version mobile).
  static const String partswiniCatalogUrl =
      'https://m.autowini.com/Parts/Catalog/parts-search.do';
}
