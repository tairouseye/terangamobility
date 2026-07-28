import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Envoie un evenement standard au Pixel Facebook via `fbq('track', ...)`.
/// No-op si le pixel n'est pas charge (ID non configure).
void fbTrack(String event, [Map<String, Object?>? params]) {
  final g = globalContext;
  if (!g.has('fbq')) return;
  g.callMethod<JSAny?>('fbq'.toJS, 'track'.toJS, event.toJS, params?.jsify());
}
