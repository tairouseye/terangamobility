// Ouvre une URL EXTERNE dans un nouvel onglet SANS jamais naviguer l'onglet
// courant (qui, sur mobile/iOS, rechargerait toute l'app -> retour au menu).
//
// Sur le web, `url_launcher` en mode externalApplication ouvre avec la cible
// `_top` sur Safari/iOS : cela navigue l'onglet courant. On contourne en
// appelant `window.open(url, '_blank')` de maniere SYNCHRONE (dans le geste
// utilisateur) -> vrai nouvel onglet, l'app reste vivante.
export 'open_tab_io.dart' if (dart.library.js_interop) 'open_tab_web.dart';
