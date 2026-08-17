import 'package:url_launcher/url_launcher.dart';

/// Implementation non-web : ouverture classique via url_launcher.
/// (`filename` ignoré : le système gère l'ouverture/enregistrement.)
Future<void> openSignedUrl(Future<String> urlFuture,
    {String filename = 'document.pdf'}) async {
  final url = await urlFuture;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
