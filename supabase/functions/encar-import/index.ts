// =====================================================================
// Edge Function : encar-import
//
// Remplit `vehicle_listings` a partir de l'API interne d'Encar.
// L'application Flutter ne fait que LIRE cette table.
//
//   Encar  ->  [cette fonction, planifiee]  ->  vehicle_listings  ->  App
//
// Implementation VALIDEE contre l'API live (2026-07) :
//   1. LISTE   : api.encar.com/search/car/list/general   -> Id + photos + region
//   2. FICHE   : api.encar.com/v1/readside/vehicle/{Id}   -> specs completes
//      (la fiche fournit deja les noms EN ANGLAIS : manufacturerEnglishName,
//       modelGroupEnglishName, gradeEnglishName ; seuls transmission/carburant/
//       couleur sont en coreen -> traduits via mappings.ts)
//
// >>> Le PRIX n'est JAMAIS importe (regle metier). <<<
// >>> Verifier les CGU d'Encar avant tout usage automatise en production. <<<
//
// Securite : en-tete `x-import-secret` = secret IMPORT_SECRET.
// Ecriture avec SUPABASE_SERVICE_ROLE_KEY (contourne la RLS pour l'upsert).
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { COLORS, FUELS, REGIONS, TRANSMISSIONS, tr } from "./mappings.ts";

// --- Reglages --------------------------------------------------------
const PAGE_SIZE = 20; // annonces recuperees dans la liste
const MAX_ITEMS = 40; // fiches enrichies par execution (temps de fonction limite)
const DETAIL_DELAY_MS = 120; // politesse entre 2 appels fiche
const PHOTO_BASE = "https://ci.encar.com"; // + location (ex: /carpicture02/.../x.jpg)

// Filtre Encar. Exemple : uniquement domestiques visibles.
// Pour restreindre a certaines marques, affine `q` (ex: Manufacturer).
const ENCAR_QUERY = "(And.Hidden.N._.CarType.Y.)";

// --- Prix affiche en FCFA -------------------------------------------
// Encar exprime le prix en 만원 (man-won = 10 000 KRW).
//   prix_fcfa = prix_manwon * 10000 * TAUX,  puis marge fixe.
const KRW_PER_MANWON = 10000;
const KRW_TO_FCFA = 0.45; // taux KRW -> FCFA (ajustable selon le cours)
const MARGIN_THRESHOLD = 6000000; // FCFA
const MARGIN_LOW = 1300000; // ajoute si prix converti < seuil
const MARGIN_HIGH = 1500000; // ajoute si prix converti >= seuil

function computePriceFcfa(priceManwon?: number): number | null {
  if (!priceManwon || priceManwon <= 0) return null;
  const raw = priceManwon * KRW_PER_MANWON * KRW_TO_FCFA;
  const rounded = Math.round(raw / 10000) * 10000; // arrondi au 10 000
  const margin = rounded < MARGIN_THRESHOLD ? MARGIN_LOW : MARGIN_HIGH;
  return rounded + margin;
}

const HEADERS: HeadersInit = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  "Referer": "https://www.encar.com/",
  "Accept": "application/json, text/plain, */*",
};

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// --- Etape 1 : LISTE (Id + photos + region) --------------------------
interface ListItem {
  id: string;
  photos: string[];
  region: string | null;
  priceManwon?: number; // prix Encar en 만원
}

function listUrl(offset: number): string {
  const sr = `|ModifiedDate|${offset}|${PAGE_SIZE}`;
  return `https://api.encar.com/search/car/list/general?count=false` +
    `&q=${encodeURIComponent(ENCAR_QUERY)}&sr=${encodeURIComponent(sr)}`;
}

function photosFrom(raw: { location?: string }[] | undefined): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((p) => p.location)
    .filter((x): x is string => !!x)
    .map((loc) => (loc.startsWith("http") ? loc : `${PHOTO_BASE}${loc}`));
}

async function fetchList(): Promise<ListItem[]> {
  const out: ListItem[] = [];
  for (let offset = 0; offset < MAX_ITEMS; offset += PAGE_SIZE) {
    const res = await fetch(listUrl(offset), { headers: HEADERS });
    if (!res.ok) throw new Error(`Liste Encar HTTP ${res.status}`);
    const json = await res.json();
    const page = json.SearchResults ?? [];
    if (page.length === 0) break;
    for (const it of page) {
      if (it.Id == null) continue;
      out.push({
        id: String(it.Id),
        photos: photosFrom(it.Photos),
        region: tr(REGIONS, it.OfficeCityState),
        priceManwon: typeof it.Price === "number" ? it.Price : undefined,
      });
    }
  }
  return out.slice(0, MAX_ITEMS);
}

// --- Etape 2 : FICHE detaillee ---------------------------------------
interface VehicleRow {
  reference: string;
  source: string;
  brand: string;
  model: string;
  year: number | null;
  version: string | null;
  engine: string | null;
  displacement: string | null;
  mileage_km: number | null;
  transmission: string | null;
  fuel: string | null;
  color: string | null;
  doors: number | null;
  steering: string;
  location: string | null;
  condition: string;
  description: string | null;
  photos: string[];
  price_fcfa: number | null;
  is_active: boolean;
}

// Regle metier : uniquement les vehicules de moins de 10 ans.
const MIN_YEAR = new Date().getFullYear() - 10;

async function fetchDetail(item: ListItem): Promise<VehicleRow | null> {
  const res = await fetch(
    `https://api.encar.com/v1/readside/vehicle/${item.id}`,
    { headers: HEADERS },
  );
  if (!res.ok) return null; // annonce retiree / indisponible : on ignore
  const d = await res.json();
  const cat = d.category ?? {};
  const spec = d.spec ?? {};

  // On ignore les vehicules de 10 ans ou plus (ou d'annee inconnue).
  const yr = cat.formYear ? parseInt(String(cat.formYear), 10) : null;
  if (yr == null || yr < MIN_YEAR) return null;

  const version = [cat.gradeEnglishName, cat.gradeDetailEnglishName]
    .filter((x: string) => x && x.trim().length > 0)
    .join(" ");
  const disp = spec.displacement ? `${spec.displacement} cc` : null;

  return {
    reference: `EC-${item.id}`,
    source: "encar",
    brand: cat.manufacturerEnglishName ?? cat.manufacturerName ?? "Inconnu",
    model: cat.modelGroupEnglishName ?? cat.modelName ?? "Inconnu",
    year: cat.formYear ? parseInt(String(cat.formYear), 10) : null,
    version: version.length > 0 ? version : null,
    engine: cat.gradeEnglishName ?? null,
    displacement: disp,
    mileage_km: typeof spec.mileage === "number" ? spec.mileage : null,
    transmission: tr(TRANSMISSIONS, spec.transmissionName),
    fuel: tr(FUELS, spec.fuelName),
    color: tr(COLORS, spec.colorName),
    doors: null, // Encar expose seatCount, pas le nombre de portes
    steering: "left", // vehicules domestiques coreens = conduite a gauche
    location: item.region ? `${item.region}, Coree du Sud` : "Coree du Sud",
    condition: "Occasion",
    description:
      `${cat.manufacturerEnglishName ?? ""} ${cat.modelGroupEnglishName ?? ""}` +
      `${cat.formYear ? " " + cat.formYear : ""} - importe de Coree du Sud.`
        .replace(/\s+/g, " ")
        .trim(),
    photos: item.photos,
    price_fcfa: computePriceFcfa(item.priceManwon),
    is_active: true,
  };
}

// --- Handler ---------------------------------------------------------
Deno.serve(async (req) => {
  const secret = Deno.env.get("IMPORT_SECRET");
  if (secret && req.headers.get("x-import-secret") !== secret) {
    return json({ error: "Non autorise" }, 401);
  }
  const dryRun = new URL(req.url).searchParams.get("dry") === "1";

  try {
    const list = await fetchList();

    // Dedoublonne la liste par Id (la pagination sur donnees live peut
    // renvoyer 2x la meme annonce).
    const seen = new Set<string>();
    const uniqueList = list.filter((it) => {
      if (seen.has(it.id)) return false;
      seen.add(it.id);
      return true;
    });

    const rowsById = new Map<string, VehicleRow>();
    for (const item of uniqueList) {
      const row = await fetchDetail(item);
      if (row) rowsById.set(row.reference, row); // ecrase tout doublon residuel
      await sleep(DETAIL_DELAY_MS);
    }
    const rows: VehicleRow[] = [...rowsById.values()];

    if (dryRun) {
      return json({
        dryRun: true,
        listed: list.length,
        detailed: rows.length,
        sample: rows.slice(0, 3),
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error } = await supabase
      .from("vehicle_listings")
      .upsert(rows, { onConflict: "reference" });
    if (error) return json({ error: error.message }, 500);

    return json({ imported: rows.length, listed: list.length });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
