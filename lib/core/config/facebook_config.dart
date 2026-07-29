/// Parametres de la Page Facebook TerangaMobility (publication assistee).
///
/// La publication automatique par API demandera plus tard une app configuree
/// pour les Pages + un jeton `pages_manage_posts`. En attendant, l'admin
/// publie en mode assiste : l'appli prepare le texte + la photo, et ouvre le
/// composeur de la page ou il colle et publie.
class FacebookConfig {
  const FacebookConfig._();

  /// ID de la page (vu dans l'URL Meta Business Suite : asset_id=...).
  static const String pageId = '966529719870149';

  /// Composeur de publication (Meta Business Suite) pre-selectionne sur la page.
  static const String composerUrl =
      'https://business.facebook.com/latest/composer?asset_id=$pageId';

  /// Page publique (secours si le composeur ne s'ouvre pas directement).
  static const String pageUrl = 'https://www.facebook.com/$pageId';
}
