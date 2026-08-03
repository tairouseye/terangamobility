import '../config/supabase_config.dart';

/// URL passant par notre proxy (Edge Function `img`) : la photo Encar est
/// resservie avec le bon type `image/jpeg` + en-tetes CORS. Indispensable pour
/// enregistrer la photo dans « Photos » (l'appui long « Enregistrer l'image »
/// fonctionne alors), la partager, ou la telecharger (`download:true` force la
/// piece jointe avec un nom de fichier propre).
/// Les URL non-Encar (placeholders) sont renvoyees telles quelles.
String imageProxyUrl(String encarUrl, {bool download = false, String? name}) {
  if (!encarUrl.contains('ci.encar.com')) return encarUrl;
  final buf = StringBuffer('${SupabaseConfig.url}/functions/v1/img'
      '?u=${Uri.encodeComponent(encarUrl)}');
  if (download) {
    buf.write('&dl=1');
    if (name != null) buf.write('&name=${Uri.encodeComponent(name)}');
  }
  return buf.toString();
}

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

/// Version HAUTE QUALITE, sans recadrage : le ratio d'origine de la photo est
/// preserve (contrairement a [encarPhoto] qui recadre en 16:9). A utiliser pour
/// le telechargement et les publications reseaux sociaux, ou l'on veut la photo
/// entiere et nette. `height` = hauteur cible en pixels (1080 par defaut).
String encarPhotoFull(String url, {int height = 1080}) {
  if (!url.contains('ci.encar.com')) return url;
  if (url.contains('impolicy=')) return url;
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}impolicy=heightRate&rh=$height';
}

/// Derive des URL de photos Encar supplementaires (autres indices) a partir des
/// photos existantes (motif `.../<id>_NNN.jpg`). Pour l'apercu ADMIN uniquement.
/// Repli propre si une image derivee n'existe pas (gere par errorBuilder).
List<String> extraEncarPhotos(List<String> photos,
    {List<int> indices = const [2, 5]}) {
  if (photos.isEmpty) return const [];
  final base = RegExp(r'^(.*_)(\d{3})(\.jpg.*)$').firstMatch(photos.first);
  if (base == null) return const [];
  final existing = <int>{};
  for (final p in photos) {
    final m = RegExp(r'_(\d{3})\.jpg').firstMatch(p);
    if (m != null) existing.add(int.parse(m.group(1)!));
  }
  final out = <String>[];
  for (final i in indices) {
    if (existing.contains(i)) continue;
    out.add('${base.group(1)}${i.toString().padLeft(3, '0')}${base.group(3)}');
  }
  return out;
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
