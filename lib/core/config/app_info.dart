/// Informations sur l'editeur de l'application et l'assistance.
///
/// Centralise ici : un changement de numero ou d'email ne se fait qu'a un
/// seul endroit. La VERSION, elle, n'est pas dupliquee ici : elle est lue a
/// l'execution depuis le pubspec via package_info_plus (evite toute derive).
class AppInfo {
  const AppInfo._();

  /// Marque de l'application (activite).
  static const String appName = 'TerangaMobility';
  static const String appTagline = 'Parts & Véhicules';

  /// Editeur du logiciel.
  static const String publisher = 'GesPro Digital';
  static const String publisherShort = 'GesPro';
  static const String publisherSite = 'https://gesprosn.org';

  /// Date de deploiement, injectee au build :
  ///   flutter build web --dart-define=BUILD_DATE=2026-07-17
  /// Vide en dev -> on n'affiche que la version du pubspec.
  static const String buildDate =
      String.fromEnvironment('BUILD_DATE', defaultValue: '');

  /// Assistance.
  static const String supportPhone = '+221 77 343 59 28';
  static const String supportPhoneE164 = '221773435928';
  static const String supportEmail = 'gesprosn@gmail.com';

  /// Lien WhatsApp avec message pre-rempli.
  static String whatsappUrl({String? message}) {
    final text = Uri.encodeComponent(
      message ?? 'Bonjour, j\'ai besoin d\'assistance sur l\'application '
          '$appName ($appTagline).',
    );
    return 'https://wa.me/$supportPhoneE164?text=$text';
  }

  static String get telUrl => 'tel:+$supportPhoneE164';
}
