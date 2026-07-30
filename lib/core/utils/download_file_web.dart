import 'package:web/web.dart' as web;

/// Implementation web : balise <a download> cliquee par programme.
/// Pour une image de MEME origine, le navigateur l'enregistre directement ;
/// pour une image externe (Encar, sans CORS) l'attribut `download` est ignore
/// et la photo s'ouvre dans un nouvel onglet -> l'utilisateur l'enregistre.
Future<void> downloadImage(String url, String filename) async {
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..target = '_blank'
    ..rel = 'noopener';
  web.document.body?.append(a);
  a.click();
  a.remove();
}
