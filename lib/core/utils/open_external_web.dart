import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Ouvre un document (URL signée, obtenue de façon asynchrone) SANS jamais
/// naviguer l'onglet courant.
///
/// Ancienne implémentation : on pré-ouvrait un onglet puis, si le popup était
/// bloqué (fréquent sur mobile et dans les navigateurs intégrés WhatsApp /
/// Facebook), on faisait `window.location.href = url` — ce qui **rechargeait
/// toute l'app** (retour au menu de départ). Cause d'instabilité côté admin
/// (ouverture facture/contrat).
///
/// Nouvelle approche, stable partout : on récupère le document via `fetch`
/// (les URL signées Supabase Storage autorisent le CORS), puis on le télécharge
/// via un lien `blob:` LOCAL. Aucune navigation, aucun rechargement.
Future<void> openSignedUrl(Future<String> urlFuture,
    {String filename = 'document.pdf'}) async {
  final url = await urlFuture;
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
    // Dernier recours : nouvel onglet isolé (jamais l'onglet courant).
    web.window.open(url, '_blank', 'noopener');
  }
}
