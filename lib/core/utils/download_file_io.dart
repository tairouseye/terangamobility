import 'package:url_launcher/url_launcher.dart';

/// Implementation non-web : ouverture externe (le systeme propose d'enregistrer).
Future<void> downloadImage(String url, String filename) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Non-web : pas d'empaquetage ZIP en memoire — on ouvre chaque photo.
Future<void> downloadImagesZip(
    List<String> urls, List<String> filenames, String zipName) async {
  for (final url in urls) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
