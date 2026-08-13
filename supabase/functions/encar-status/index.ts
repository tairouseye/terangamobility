// =====================================================================
// Edge Function : encar-status
//
// Verifie, cote serveur, si des annonces Encar sont TOUJOURS en ligne.
// L'app envoie une liste de references (EC-<id>) ; on interroge la fiche
// Encar de chacune EN PARALLELE et on renvoie celles qui ont disparu.
//
//   App (selection Facebook)  ->  [cette fonction]  ->  api.encar.com
//
// Pourquoi : `encar-import` ne fait qu'ajouter/mettre a jour des annonces ;
// il ne marque jamais « vendu » celles qui disparaissent. Resultat : la
// selection proposait des vehicules qui ne sont plus en vente sur Encar.
//
// Prudence (anti faux positif) : on ne considere « disparu » que sur un
// 404/410 EXPLICITE (annonce retiree). Un 403/429/5xx (blocage temporaire,
// throttling) est traite comme « toujours en ligne » -> on ne supprime jamais
// un vehicule a tort. Les references confirmees disparues sont aussi passees
// `is_active=false` en base (service role) pour nettoyer le catalogue.
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const HEADERS: HeadersInit = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  "Referer": "https://www.encar.com/",
  "Accept": "application/json, text/plain, */*",
};

const CORS: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_REFS = 80;

function encarId(reference: string): string | null {
  const m = /^EC-(\d+)$/.exec(reference.trim());
  return m ? m[1] : null;
}

/// Retourne true si l'annonce a EXPLICITEMENT disparu (404/410), false sinon.
/// Un blocage temporaire (403/429/5xx) ou une erreur reseau -> false (on ne
/// juge pas). Une petite reprise couvre les coupures ponctuelles.
async function isGone(id: string): Promise<boolean> {
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await fetch(
        `https://api.encar.com/v1/readside/vehicle/${id}`,
        { headers: HEADERS },
      );
      // Consomme le corps pour liberer la connexion.
      await res.text().catch(() => {});
      if (res.status === 404 || res.status === 410) return true; // retiree
      return false; // 200 (en ligne) ou blocage temporaire : on garde
    } catch {
      // erreur reseau : on retente une fois puis on abandonne (on garde)
    }
    await new Promise((r) => setTimeout(r, 150));
  }
  return false;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  let refs: string[] = [];
  try {
    const body = await req.json();
    if (Array.isArray(body?.refs)) refs = body.refs.map((r: unknown) => String(r));
  } catch {
    // corps invalide -> liste vide
  }
  refs = [...new Set(refs)].filter((r) => encarId(r) !== null).slice(0, MAX_REFS);

  const flags = await Promise.all(
    refs.map(async (ref) => ({ ref, gone: await isGone(encarId(ref)!) })),
  );
  const dead = flags.filter((f) => f.gone).map((f) => f.ref);

  if (dead.length > 0) {
    try {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      );
      await supabase
        .from("vehicle_listings")
        .update({ is_active: false })
        .in("reference", dead);
    } catch {
      // le nettoyage DB est un bonus : ne bloque pas la reponse
    }
  }

  return new Response(
    JSON.stringify({ dead, checked: refs.length }),
    { headers: { ...CORS, "Content-Type": "application/json" } },
  );
});
