import 'dart:js_interop';
import 'dart:typed_data';
import 'package:archive/archive.dart';
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
    _saveBlob(blob, filename);
  } catch (_) {
    // Repli qui n'affecte pas la page courante : onglet isole.
    web.window.open(url, '_blank', 'noopener');
  }
}

/// Telecharge PLUSIEURS images en **un seul fichier ZIP**.
///
/// Pourquoi un ZIP : un navigateur bloque les telechargements multiples
/// declenches en boucle (apres le 1er `await`, le « geste utilisateur » est
/// perdu -> seule la 1re photo partait). Un unique telechargement, lui, passe
/// toujours. On recupere donc toutes les photos (via le proxy CORS), on les
/// empaquete en memoire, et on enregistre le ZIP en une fois.
Future<void> downloadImagesZip(
    List<String> urls, List<String> filenames, String zipName) async {
  final archive = Archive();
  for (var i = 0; i < urls.length; i++) {
    final resp = await web.window.fetch(urls[i].toJS).toDart;
    final buffer = (await resp.arrayBuffer().toDart).toDart;
    final bytes = buffer.asUint8List();
    archive.addFile(ArchiveFile(filenames[i], bytes.length, bytes));
  }
  final encoded = ZipEncoder().encode(archive) ?? const <int>[];
  final zipBytes = Uint8List.fromList(encoded);
  final blob = web.Blob(
    [zipBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/zip'),
  );
  _saveBlob(blob, zipName);
}

/// Enregistre un `Blob` via un lien `blob:` local (aucune navigation).
void _saveBlob(web.Blob blob, String filename) {
  final objectUrl = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(objectUrl);
}
