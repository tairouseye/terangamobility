import 'package:url_launcher/url_launcher.dart';

/// Implementation non-web : ouverture classique via url_launcher.
Future<void> openSignedUrl(Future<String> urlFuture) async {
  final url = await urlFuture;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
