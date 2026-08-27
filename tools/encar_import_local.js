#!/usr/bin/env node
// =====================================================================
// Import Encar LOCAL — catalogue CURÉ & PLAFONNÉ (depuis une IP autorisée).
//
// Encar bloque les IP datacenter (HTTP 407) depuis ~19/08/2026 : l'import ne
// peut plus tourner sur Supabase, il tourne ici (IP résidentielle = 200).
//
// Objectif métier : garder ~400 véhicules au total = les annonces les PLUS
// RÉCENTES, uniquement des MARQUES LISTÉES, avec PRIORITÉ AUX ÉLECTRIQUES.
// À chaque passage on reconstruit l'ensemble à garder puis on DÉSACTIVE le
// reste (RPC prune_catalogue) — les véhicules réservés/vendus ne sont jamais
// touchés.
//
// Passes (triées par date de modification décroissante sur Encar) :
//   1) Électriques domestiques  -> jusqu'à ELEC_TARGET (focus)
//   2) Jeep (marque importée)   -> jusqu'à JEEP_TARGET
//   3) Domestiques récentes     -> complète jusqu'à TARGET_TOTAL
//
// Config Supabase : SB_CONFIG (fichier JSON {url|ref, service_role}) ou
// SUPABASE_URL + SUPABASE_SERVICE_KEY.
//
// Usage : node tools/encar_import_local.js
// =====================================================================

const fs = require('fs');

// --- Cible catalogue --------------------------------------------------
const TARGET_TOTAL = 400; // total gardé (actif) après chaque import
const ELEC_TARGET = 100;  // électriques prioritaires
const JEEP_TARGET = 40;   // Jeep (marque importée)
const PRUNE_MIN = 300;    // sûreté : ne prune QUE si on a récupéré au moins ça

// Marques déjà listées (sortie de cleanBrand). Tout le reste est ignoré.
const LISTED = new Set(['Hyundai', 'Kia', 'Genesis', 'SsangYong', 'Chevrolet', 'Renault', 'Jeep']);

// Requêtes Encar (langage de recherche interne).
const Q_ELEC = '(And.Hidden.N._.CarType.Y._.FuelType.전기.)'; // électriques domestiques
const Q_JEEP = '(And.Hidden.N._.Manufacturer.지프.)';         // Jeep (importé)
const Q_GENERAL = '(And.Hidden.N._.CarType.Y.)';              // domestiques

// --- Config Supabase --------------------------------------------------
function loadConfig() {
  const cfgPath = process.env.SB_CONFIG;
  if (cfgPath && fs.existsSync(cfgPath)) {
    const j = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
    const ref = j.ref || (j.url || '').split('//')[1]?.split('.')[0];
    return { url: j.url || `https://${ref}.supabase.co`, key: j.service_role || j.service_key };
  }
  const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_SERVICE_KEY;
  if (!url || !key) { console.error('Config manquante : SB_CONFIG ou SUPABASE_URL + SUPABASE_SERVICE_KEY.'); process.exit(1); }
  return { url, key };
}
const CFG = loadConfig();

// --- Traductions (miroir de mappings.ts) ------------------------------
const BRAND_CLEAN = { 'KG_Mobility_Ssangyong': 'SsangYong', 'KG Mobility': 'SsangYong', 'SsangYong': 'SsangYong', 'Renault Korea': 'Renault', 'Renault Samsung': 'Renault', 'Chevrolet(GM Daewoo)': 'Chevrolet' };
function cleanBrand(b) {
  if (!b || !b.trim()) return 'Inconnu';
  if (BRAND_CLEAN[b]) return BRAND_CLEAN[b];
  if (/ssangyong/i.test(b)) return 'SsangYong';
  if (/chevrolet/i.test(b)) return 'Chevrolet';
  if (/renault/i.test(b)) return 'Renault';
  return b.replace(/_/g, ' ').trim();
}
const FUELS = { '가솔린': 'Essence', '디젤': 'Diesel', '하이브리드': 'Hybride', '가솔린+전기': 'Hybride', 'LPG': 'GPL', 'LPG(일반인)': 'GPL', '전기': 'Electrique', '수소': 'Hydrogene' };
const TRANSMISSIONS = { '오토': 'Automatique', '자동': 'Automatique', '수동': 'Manuelle', 'CVT': 'Automatique (CVT)', '세미오토': 'Semi-automatique' };
const COLORS = { '흰색': 'Blanc', '검정색': 'Noir', '검정': 'Noir', '쥐색': 'Gris', '은색': 'Argent', '은회색': 'Gris argent', '빨간색': 'Rouge', '파란색': 'Bleu', '남색': 'Bleu nuit', '진주색': 'Nacre', '갈색': 'Marron', '금색': 'Or' };
const REGIONS = { '서울': 'Seoul', '경기': 'Gyeonggi', '인천': 'Incheon', '부산': 'Busan', '대구': 'Daegu', '대전': 'Daejeon', '광주': 'Gwangju', '울산': 'Ulsan', '세종': 'Sejong', '강원': 'Gangwon', '충북': 'Chungbuk', '충남': 'Chungnam', '전북': 'Jeonbuk', '전남': 'Jeonnam', '경북': 'Gyeongbuk', '경남': 'Gyeongnam', '제주': 'Jeju' };
const tr = (d, v) => (!v ? null : (d[v] ?? v));

// --- Réglages Encar ---------------------------------------------------
const PAGE_SIZE = 20;
const DETAIL_DELAY_MS = 120;
const PHOTO_BASE = 'https://ci.encar.com';
const MIN_YEAR = new Date().getFullYear() - 10;
const KRW_PER_MANWON = 10000, KRW_TO_FCFA = 0.45;
const MARGIN_THRESHOLD = 6000000, MARGIN_LOW = 1300000, MARGIN_HIGH = 1500000, PRICE_STEP = 100000;
function computePriceFcfa(m) { if (!m || m <= 0) return null; const raw = m * KRW_PER_MANWON * KRW_TO_FCFA; const margin = raw < MARGIN_THRESHOLD ? MARGIN_LOW : MARGIN_HIGH; return Math.round((raw + margin) / PRICE_STEP) * PRICE_STEP; }

const HEADERS = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36', 'Referer': 'https://www.encar.com/', 'Accept': 'application/json, text/plain, */*' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/// GET avec réessais : couvre les hoquets réseau (surtout au démarrage du PC à
/// 09:00 quand le WiFi n'est pas encore prêt) et les 5xx/429/timeouts d'Encar.
/// Ne réessaie PAS les autres 4xx (ex. 407 = blocage IP serveur : inutile).
async function getWithRetry(url, { retries = 6, timeoutMs = 20000 } = {}) {
  let lastErr;
  for (let a = 0; a < retries; a++) {
    try {
      const ctrl = new AbortController();
      const to = setTimeout(() => ctrl.abort(), timeoutMs);
      const res = await fetch(url, { headers: HEADERS, signal: ctrl.signal });
      clearTimeout(to);
      if (res.status >= 500 || res.status === 429) throw new Error(`HTTP ${res.status}`);
      return res; // 2xx ou autre 4xx : rendu tel quel (l'appelant décide)
    } catch (e) {
      lastErr = e;
      if (a < retries - 1) await sleep(Math.min(30000, 1500 * 2 ** a)); // 1.5,3,6,12,24,30s
    }
  }
  throw lastErr;
}

/// Attend que le réseau + Encar soient joignables (jusqu'à ~5 min au démarrage).
async function waitForEncar() {
  for (let i = 0; i < 10; i++) {
    try {
      const r = await fetch(listUrl(Q_GENERAL, 0), { headers: HEADERS });
      if (r.ok) { await r.text(); return true; }
    } catch (_) { /* réseau pas prêt */ }
    console.log(`  … réseau/Encar pas prêt, nouvelle tentative dans 30s (${i + 1}/10)`);
    await sleep(30000);
  }
  return false;
}

function listUrl(q, offset) {
  const sr = `|ModifiedDate|${offset}|${PAGE_SIZE}`;
  return `https://api.encar.com/search/car/list/general?count=false&q=${encodeURIComponent(q)}&sr=${encodeURIComponent(sr)}`;
}
function photosFrom(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((p) => p.location).filter(Boolean).map((loc) => (loc.startsWith('http') ? loc : `${PHOTO_BASE}${loc}`));
}
async function listPage(q, offset) {
  const res = await getWithRetry(listUrl(q, offset));
  if (!res.ok) throw new Error(`Liste Encar HTTP ${res.status}`);
  const json = await res.json();
  return (json.SearchResults ?? []).filter((it) => it.Id != null).map((it) => ({
    id: String(it.Id), photos: photosFrom(it.Photos), region: tr(REGIONS, it.OfficeCityState),
    priceManwon: typeof it.Price === 'number' ? it.Price : undefined,
  }));
}
async function fetchDetail(item) {
  const res = await getWithRetry(`https://api.encar.com/v1/readside/vehicle/${item.id}`, { retries: 3 });
  if (!res.ok) return null;
  const d = await res.json();
  const cat = d.category ?? {}, spec = d.spec ?? {};
  const yr = cat.formYear ? parseInt(String(cat.formYear), 10) : null;
  if (yr == null || yr < MIN_YEAR) return null;
  const version = [cat.gradeEnglishName, cat.gradeDetailEnglishName].filter((x) => x && x.trim()).join(' ');
  return {
    reference: `EC-${item.id}`, source: 'encar',
    brand: cleanBrand(cat.manufacturerEnglishName ?? cat.manufacturerName),
    model: cat.modelGroupEnglishName ?? cat.modelName ?? 'Inconnu',
    year: yr, version: version || null, engine: cat.gradeEnglishName ?? null,
    displacement: spec.displacement ? `${spec.displacement} cc` : null,
    mileage_km: typeof spec.mileage === 'number' ? spec.mileage : null,
    transmission: tr(TRANSMISSIONS, spec.transmissionName), fuel: tr(FUELS, spec.fuelName), color: tr(COLORS, spec.colorName),
    doors: null, steering: 'left',
    location: item.region ? `${item.region}, Coree du Sud` : 'Coree du Sud',
    condition: 'Occasion',
    description: `${cat.manufacturerEnglishName ?? ''} ${cat.modelGroupEnglishName ?? ''}${cat.formYear ? ' ' + cat.formYear : ''} - importe de Coree du Sud.`.replace(/\s+/g, ' ').trim(),
    photos: item.photos, price_fcfa: computePriceFcfa(item.priceManwon), is_active: true,
  };
}

/// Collecte jusqu'à `want` véhicules d'une requête, filtrés par `keepFn`,
/// en évitant les références déjà prises (`skip`). Parcourt la liste triée
/// par date de modification décroissante.
async function collect(label, q, want, keepFn, skip) {
  const rows = [];
  const maxOffset = Math.max(want * 3, 60) + 40;
  for (let offset = 0; rows.length < want && offset < maxOffset; offset += PAGE_SIZE) {
    let page;
    try { page = await listPage(q, offset); } catch (e) { console.error(`  [${label}] liste ${e.message}`); break; }
    if (page.length === 0) break;
    for (const item of page) {
      if (rows.length >= want) break;
      const ref = `EC-${item.id}`;
      if (skip.has(ref)) continue;
      let row; try { row = await fetchDetail(item); } catch (_) { row = null; }
      await sleep(DETAIL_DELAY_MS);
      if (!row || !keepFn(row)) continue;
      skip.add(ref);
      rows.push(row);
    }
  }
  console.log(`  [${label}] ${rows.length} véhicules`);
  return rows;
}

async function upsert(rows) {
  const url = `${CFG.url}/rest/v1/vehicle_listings?on_conflict=reference`;
  for (let i = 0; i < rows.length; i += 100) {
    const chunk = rows.slice(i, i + 100);
    const res = await fetch(url, { method: 'POST', headers: { apikey: CFG.key, Authorization: 'Bearer ' + CFG.key, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify(chunk) });
    if (!res.ok) throw new Error(`Upsert HTTP ${res.status} : ${(await res.text()).slice(0, 200)}`);
  }
}
async function prune(keepRefs) {
  const res = await fetch(`${CFG.url}/rest/v1/rpc/prune_catalogue`, { method: 'POST', headers: { apikey: CFG.key, Authorization: 'Bearer ' + CFG.key, 'Content-Type': 'application/json' }, body: JSON.stringify({ keep_refs: keepRefs }) });
  if (!res.ok) throw new Error(`Prune HTTP ${res.status} : ${(await res.text()).slice(0, 200)}`);
  return parseInt(await res.text(), 10);
}

(async () => {
  const t0 = Date.now();
  console.log(`[import] cible ${TARGET_TOTAL} (${ELEC_TARGET} élec + ${JEEP_TARGET} Jeep + récentes), marques : ${[...LISTED].join(', ')}`);

  // Le PC démarre parfois juste avant 09:00 : on attend que le réseau soit prêt.
  if (!(await waitForEncar())) {
    console.error('[import] Encar injoignable après ~5 min (réseau ?) — abandon, catalogue préservé.');
    process.exit(1);
  }

  const skip = new Set();
  const elec = await collect('élec', Q_ELEC, ELEC_TARGET, (r) => LISTED.has(r.brand), skip);
  const jeep = await collect('jeep', Q_JEEP, JEEP_TARGET, (r) => r.brand === 'Jeep', skip);
  const need = Math.max(0, TARGET_TOTAL - elec.length - jeep.length);
  const gen = await collect('récentes', Q_GENERAL, need, (r) => LISTED.has(r.brand), skip);

  const all = [...elec, ...jeep, ...gen].slice(0, TARGET_TOTAL);
  console.log(`[import] total à garder : ${all.length} (élec ${elec.length}, jeep ${jeep.length}, autres ${gen.length})`);

  if (all.length === 0) { console.error('[import] rien récupéré — abandon (Encar bloqué ?).'); process.exit(1); }
  await upsert(all);
  console.log('[import] upsert OK.');

  if (all.length >= PRUNE_MIN) {
    const off = await prune(all.map((r) => r.reference));
    console.log(`[import] prune : ${off} véhicule(s) désactivé(s) (hors des ${all.length} gardés).`);
  } else {
    console.warn(`[import] prune SAUTÉ (seulement ${all.length} < ${PRUNE_MIN}) — catalogue existant préservé.`);
  }
  console.log(`[import] terminé en ${((Date.now() - t0) / 1000).toFixed(0)}s.`);
})().catch((e) => { console.error('[import] ÉCHEC :', e.message); process.exit(1); });
