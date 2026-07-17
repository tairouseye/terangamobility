/// Informations sur l'editeur de l'application et l'assistance.
///
/// Centralise ici : un changement de numero ou d'email ne se fait qu'a un
/// seul endroit. La VERSION, elle, n'est pas dupliquee ici : elle est lue a
/// l'execution depuis le pubspec via package_info_plus (evite toute derive).
class AppInfo {
  const AppInfo._();

  /// Marque de l'application (activite).
  static const String appName = 'TerangaMobility';
  static const String appTagline = 'Parts & Vehicules';

  /// Editeur du logiciel.
  static const String publisher = 'GesPro Digital';
  static const String publisherSite = 'https://gesprosn.org';

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
