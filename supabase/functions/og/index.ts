// =====================================================================
// Edge Function : og — aperçu social par véhicule (Open Graph)
//
// L'app est une SPA à routage par hash (#/vehicule/REF) sur GitHub Pages :
// les robots Facebook/WhatsApp ne voient donc JAMAIS le fragment ni le contenu
// rendu en JS -> tous les liens partagés affichent la même vignette générique.
//
// Cette fonction sert, pour une référence donnée, une page HTML avec les
// balises Open Graph du VRAI véhicule (photo + modèle + prix). Les robots
// lisent ces balises (ils n'exécutent pas le JS) ; un humain est redirigé vers
// l'app. On l'utilise comme LIEN DE PARTAGE (fbCaption, boutons Partager/WhatsApp).
//
// public (verify_jwt=false) : les crawlers ne sont pas authentifiés. Lecture
// de la fiche via SERVICE_ROLE (la RLS interdit la lecture anonyme).
// =====================================================================

const APP_BASE = "https://terangamobility.gesprosn.org";

const esc = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

function fcfa(v: number | null | undefined): string | null {
  if (v == null) return null;
  const s = Math.round(v).toString();
  let out = "";
  for (let i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 === 0) out += " ";
    out += s[i];
  }
  return out + " FCFA";
}

function imageUrl(supaUrl: string, photo?: string): string {
  const fallback = `${APP_BASE}/icons/Icon-512.png`;
  if (!photo) return fallback;
  // Photo Encar en ~1200 de large via la politique de redim, servie par le proxy img.
  const sized = photo.includes("ci.encar.com") && !photo.includes("impolicy=")
    ? `${photo}${photo.includes("?") ? "&" : "?"}impolicy=heightRate&rh=630`
    : photo;
  if (!sized.includes("ci.encar.com")) return fallback;
  return `${supaUrl}/functions/v1/img?u=${encodeURIComponent(sized)}`;
}

Deno.serve(async (req) => {
  const supaUrl = Deno.env.get("SUPABASE_URL")!;
  const url = new URL(req.url);
  // Référence depuis le chemin (/og/EC-123) ou le paramètre ?ref=.
  const fromPath = url.pathname.split("/").filter(Boolean).pop() ?? "";
  const ref = (url.searchParams.get("ref") ?? (fromPath === "og" ? "" : fromPath)).trim();
  const appLink = ref
    ? `${APP_BASE}/#/vehicule/${encodeURIComponent(ref)}`
    : `${APP_BASE}/#/vehicules`;

  let title = "TerangaMobility — Véhicules importés de Corée";
  let desc = "Véhicules et pièces importés de Corée, livrés au Sénégal.";
  let image = `${APP_BASE}/icons/Icon-512.png`;

  if (ref) {
    try {
      const res = await fetch(
        `${supaUrl}/rest/v1/vehicle_listings?reference=eq.${encodeURIComponent(ref)}` +
          `&select=brand,model,year,mileage_km,fuel,transmission,price_fcfa,photos&limit=1`,
        {
          headers: {
            apikey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
            Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!}`,
          },
        },
      );
      const rows = await res.json();
      const v = Array.isArray(rows) ? rows[0] : null;
      if (v) {
        const name = [v.brand, v.model, v.year].filter(Boolean).join(" ");
        const price = fcfa(v.price_fcfa);
        title = price ? `${name} — ${price}` : `${name} — Prix sur demande`;
        const specs = [
          v.mileage_km ? `${fcfa(v.mileage_km)?.replace(" FCFA", "")} km` : null,
          v.fuel, v.transmission,
        ].filter(Boolean).join(" · ");
        desc = `${specs ? specs + " — " : ""}Importé de Corée, livré au Sénégal. TerangaMobility.`;
        image = imageUrl(supaUrl, Array.isArray(v.photos) ? v.photos[0] : undefined);
      }
    } catch (_) { /* fiche indisponible : aperçu générique */ }
  }

  const html = `<!doctype html><html lang="fr"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta property="og:type" content="website">
<meta property="og:site_name" content="TerangaMobility">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:image" content="${esc(image)}">
<meta property="og:url" content="${esc(appLink)}">
<meta property="og:locale" content="fr_FR">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
<meta name="twitter:image" content="${esc(image)}">
<link rel="canonical" href="${esc(appLink)}">
<meta http-equiv="refresh" content="0; url=${esc(appLink)}">
<script>location.replace(${JSON.stringify(appLink)});</script>
</head><body style="font-family:sans-serif;text-align:center;padding:40px">
<p>Redirection vers TerangaMobility…</p>
<p><a href="${esc(appLink)}">Voir le véhicule</a></p>
</body></html>`;

  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      // Cache court : les crawlers peuvent remettre en cache, mais le prix/photo
      // restent frais dans un délai raisonnable.
      "Cache-Control": "public, max-age=600",
    },
  });
});
