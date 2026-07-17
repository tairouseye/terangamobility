/// Amelioration de la qualite des photos Encar.
///
/// Les URLs stockees pointent vers la vignette WebP par defaut (~16 Ko, floue).
/// Le CDN Encar (ci.encar.com) accepte une politique de redimensionnement qui
/// renvoie une image nette, recadree et toujours optimisee pour le web.
///
/// Les URLs non-Encar (placeholders des vehicules d'exemple, etc.) sont
/// renvoyees telles quelles.
String encarPhoto(String url, {int height = 720, double ratio = 16 / 9}) {
  if (!url.contains('ci.encar.com')) return url;
  // Deja redimensionnee : on ne double pas la politique.
  if (url.contains('impolicy=')) return url;
  final w = (height * ratio).round();
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}impolicy=heightRate&rh=$height&cw=$w&ch=$height&cg=Center';
}
