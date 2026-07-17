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

/// Variante adaptative : la resolution demandee s'ajuste a la place reellement
/// occupee a l'ecran (largeur logique du conteneur x densite de pixels de
/// l'appareil). Nette sur desktop/retina, legere sur telephone.
///
/// La hauteur physique est arrondie a un palier de 120 px et bornee pour
/// eviter de multiplier les variantes en cache et de sur-charger les gros
/// ecrans.
String encarPhotoAdaptive(
  String url, {
  required double logicalWidth,
  required double devicePixelRatio,
  double ratio = 16 / 9,
  int minHeight = 360,
  int maxHeight = 1200,
}) {
  final physicalWidth = logicalWidth * devicePixelRatio;
  final rawHeight = physicalWidth / ratio;
  // Palier de 120 px : limite le nombre de tailles distinctes.
  final stepped = ((rawHeight / 120).ceil() * 120);
  final height = stepped.clamp(minHeight, maxHeight);
  return encarPhoto(url, height: height, ratio: ratio);
}
