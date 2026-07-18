// Ouvre une URL signee (obtenue de facon asynchrone) dans un nouvel onglet.
//
// Sur le web, appeler window.open APRES un await perd le « geste utilisateur »
// et le navigateur bloque la popup -> le document ne s'ouvre pas. L'implementation
// web pre-ouvre l'onglet de maniere synchrone puis y injecte l'URL une fois prete.
export 'open_external_io.dart'
    if (dart.library.js_interop) 'open_external_web.dart';
