import 'package:web/web.dart' as web;

/// Implementation web : on pre-ouvre l'onglet AVANT l'await (geste utilisateur
/// encore valide), puis on y injecte l'URL signee. Evite le blocage popup.
Future<void> openSignedUrl(Future<String> urlFuture) async {
  final w = web.window.open('', '_blank');
  try {
    final url = await urlFuture;
    if (w != null) {
      w.location.href = url;
    } else {
      // Popup bloquee malgre tout : on ouvre dans l'onglet courant.
      web.window.location.href = url;
    }
  } catch (e) {
    w?.close();
    rethrow;
  }
}
