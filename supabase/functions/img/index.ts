// =====================================================================
// Edge Function : img  (proxy d'images Encar)
//
// POURQUOI : les photos Encar (ci.encar.com) sont servies SANS en-tete CORS
// et avec un Content-Type errone (multipart/form-data). Le navigateur peut les
// AFFICHER dans une balise <img>, mais JavaScript ne peut PAS lire leurs octets
// -> impossible d'« Enregistrer dans Photos », de partager le fichier, ni de
// forcer un vrai telechargement.
//
// Cette fonction re-sert la photo avec les bons en-tetes :
//   - Content-Type: image/jpeg      (l'appui long « Enregistrer l'image » marche)
//   - Access-Control-Allow-Origin:* (fetch cote client autorise -> partage natif)
//   - Content-Disposition: attachment (si ?dl=1 -> telechargement direct)
//
// Securite : on n'accepte QUE les URL du CDN Encar (anti-SSRF). Fonction
// publique (verify_jwt = false) car ouverte dans un onglet / balise <img>.
//
//   Deploiement :  supabase functions deploy img --no-verify-jwt
// =====================================================================

const ALLOWED_HOST = "ci.encar.com";

const ENCAR_HEADERS: HeadersInit = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  "Referer": "https://www.encar.com/",
  "Accept": "image/avif,image/webp,image/*,*/*;q=0.8",
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "*",
};

function safeName(raw: string | null): string {
  const n = (raw ?? "photo.jpg").replace(/[^A-Za-z0-9._-]/g, "_");
  return n.toLowerCase().endsWith(".jpg") ? n : `${n}.jpg`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS });
  }

  const params = new URL(req.url).searchParams;
  const target = params.get("u");
  if (!target) {
    return new Response("parametre u manquant", { status: 400, headers: CORS });
  }

  let url: URL;
  try {
    url = new URL(target);
  } catch {
    return new Response("URL invalide", { status: 400, headers: CORS });
  }
  // Anti-SSRF : uniquement le CDN Encar en HTTPS.
  if (url.protocol !== "https:" || url.hostname !== ALLOWED_HOST) {
    return new Response("hote non autorise", { status: 403, headers: CORS });
  }

  let upstream: Response;
  try {
    upstream = await fetch(url.toString(), { headers: ENCAR_HEADERS });
  } catch (e) {
    return new Response(`amont injoignable: ${e}`, { status: 502, headers: CORS });
  }
  if (!upstream.ok || !upstream.body) {
    return new Response("photo indisponible", {
      status: upstream.status || 502,
      headers: CORS,
    });
  }

  const headers = new Headers(CORS);
  headers.set("Content-Type", "image/jpeg");
  headers.set("Cache-Control", "public, max-age=86400");
  if (params.get("dl") === "1") {
    headers.set(
      "Content-Disposition",
      `attachment; filename="${safeName(params.get("name"))}"`,
    );
  }
  return new Response(upstream.body, { status: 200, headers });
});
