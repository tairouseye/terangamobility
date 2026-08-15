import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

/// Non-web : ouverture externe classique (navigateur/app systeme).
void openInNewTab(String url) {
  unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
}
