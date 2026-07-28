// Envoi d'evenements au Pixel Facebook.
//
// Sur le web, appelle la fonction globale `fbq(...)` installee dans index.html
// (seulement si un vrai Pixel ID est configure). Hors web ou si le pixel n'est
// pas charge, c'est un no-op silencieux.
export 'fb_pixel_stub.dart'
    if (dart.library.js_interop) 'fb_pixel_web.dart';
