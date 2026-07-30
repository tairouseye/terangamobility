import 'package:url_launcher/url_launcher.dart';

/// Implementation non-web : ouverture externe (le systeme propose d'enregistrer).
Future<void> downloadImage(String url, String filename) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
