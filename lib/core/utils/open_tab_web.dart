import 'package:web/web.dart' as web;

/// Web : nouvel onglet synchrone (geste utilisateur preserve). Ne navigue JAMAIS
/// l'onglet courant, donc l'app n'est pas rechargee.
void openInNewTab(String url) {
  web.window.open(url, '_blank', 'noopener');
}
