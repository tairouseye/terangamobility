import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Telechargement web SANS casser la navigation de l'app.
///
/// On recupere l'image via `fetch` (l'URL passe par notre proxy `img`, qui
/// autorise le CORS), on la transforme en `blob`, puis on la telecharge via un
/// lien `blob:` LOCAL. Comme le lien est de meme origine, l'attribut `download`
/// est toujours respecte : le fichier est enregistre **sans naviguer ni ouvrir
/// d'onglet**. (L'ancienne methode `<a target="_blank">` vers une URL externe
/// pouvait, sur mobile, naviguer l'onglet courant et recharger l'app —> retour
/// au menu de depart.)
Future<void> downloadImage(String url, String filename) async {
  try {
    final resp = await web.window.fetch(url.toJS).toDart;
    final blob = await resp.blob().toDart;
    final objectUrl = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = objectUrl
      ..download = filename
      ..style.display = 'none';
    web.document.body?.appendChild(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(objectUrl);
  } catch (_) {
    // Repli qui n'affecte pas la page courante : onglet isole.
    web.window.open(url, '_blank', 'noopener');
  }
}
