#!/usr/bin/env node
// =====================================================================
// Import Encar LOCAL (depuis une IP autorisée : PC de l'admin).
//
// Depuis ~19/08/2026, Encar bloque les IP datacenter (le serveur Supabase
// reçoit HTTP 407). La fonction Edge planifiée ne peut donc plus importer.
// Ce script reproduit sa logique mais tourne sur une IP résidentielle
// (Encar répond 200), puis upsert dans Supabase via la clé service_role.
//
// Usage : node tools/encar_import_local.js [nbItems]
//   nbItems : nombre d'annonces récentes à rafraîchir (défaut 200).
//
// Config Supabase : lue depuis la variable d'env SUPABASE_SERVICE_KEY + URL,
// ou depuis le fichier passé en SB_CONFIG (JSON avec {url|ref, service_role}).
// =====================================================================

const fs = require('fs');

// --- Config Supabase --------------------------------------------------
function loadConfig() {
  const cfgPath = process.env.SB_CONFIG;
  if (cfgPath && fs.existsSync(cfgPath)) {
    const j = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
    const ref = j.ref || (j.url || '').split('//')[1]?.split('.')[0];
    return { url: j.url || `https://${ref}.supabase.co`, key: j.service_role || j.service_key };
  }
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_KEY;
  if (!url || !key) {
    console.error('Config manquante : définir SB_CONFIG (fichier JSON) ou SUPABASE_URL + SUPABASE_SERVICE_KEY.');
    process.exit(1);
  }
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

// --- Réglages ---------------------------------------------------------
const PAGE_SIZE = 20;
const MAX_ITEMS = parseInt(process.argv[2] || '200', 10);
const DETAIL_DELAY_MS = 120;
const PHOTO_BASE = 'https://ci.encar.com';
const ENCAR_QUERY = '(And.Hidden.N._.CarType.Y.)';
const MIN_YEAR = new Date().getFullYear() - 10;

const KRW_PER_MANWON = 10000, KRW_TO_FCFA = 0.45;
const MARGIN_THRESHOLD = 6000000, MARGIN_LOW = 1300000, MARGIN_HIGH = 1500000, PRICE_STEP = 100000;
function computePriceFcfa(priceManwon) {
  if (!priceManwon || priceManwon <= 0) return null;
  const raw = priceManwon * KRW_PER_MANWON * KRW_TO_FCFA;
  const margin = raw < MARGIN_THRESHOLD ? MARGIN_LOW : MARGIN_HIGH;
  return Math.round((raw + margin) / PRICE_STEP) * PRICE_STEP;
}

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
  'Referer': 'https://www.encar.com/',
  'Accept': 'application/json, text/plain, */*',
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function listUrl(offset) {
  const sr = `|ModifiedDate|${offset}|${PAGE_SIZE}`;
  return `https://api.encar.com/search/car/list/general?count=false&q=${encodeURIComponent(ENCAR_QUERY)}&sr=${encodeURIComponent(sr)}`;
}
function photosFrom(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((p) => p.location).filter(Boolean).map((loc) => (loc.startsWith('http') ? loc : `${PHOTO_BASE}${loc}`));
}

async function fetchList() {
  const out = [];
  for (let offset = 0; offset < MAX_ITEMS; offset += PAGE_SIZE) {
    const res = await fetch(listUrl(offset), { headers: HEADERS });
    if (!res.ok) throw new Error(`Liste Encar HTTP ${res.status}`);
    const json = await res.json();
    const page = json.SearchResults ?? [];
    if (page.length === 0) break;
    for (const it of page) {
      if (it.Id == null) continue;
      out.push({ id: String(it.Id), photos: photosFrom(it.Photos), region: tr(REGIONS, it.OfficeCityState), priceManwon: typeof it.Price === 'number' ? it.Price : undefined });
    }
    await sleep(DETAIL_DELAY_MS);
  }
  return out.slice(0, MAX_ITEMS);
}

async function fetchDetail(item) {
  const res = await fetch(`https://api.encar.com/v1/readside/vehicle/${item.id}`, { headers: HEADERS });
  if (!res.ok) return null;
  const d = await res.json();
  const cat = d.category ?? {}, spec = d.spec ?? {};
  const yr = cat.formYear ? parseInt(String(cat.formYear), 10) : null;
  if (yr == null || yr < MIN_YEAR) return null;
  const version = [cat.gradeEnglishName, cat.gradeDetailEnglishName].filter((x) => x && x.trim()).join(' ');
  const disp = spec.displacement ? `${spec.displacement} cc` : null;
  return {
    reference: `EC-${item.id}`, source: 'encar',
    brand: cleanBrand(cat.manufacturerEnglishName ?? cat.manufacturerName),
    model: cat.modelGroupEnglishName ?? cat.modelName ?? 'Inconnu',
    year: yr, version: version || null, engine: cat.gradeEnglishName ?? null, displacement: disp,
    mileage_km: typeof spec.mileage === 'number' ? spec.mileage : null,
    transmission: tr(TRANSMISSIONS, spec.transmissionName), fuel: tr(FUELS, spec.fuelName), color: tr(COLORS, spec.colorName),
    doors: null, steering: 'left',
    location: item.region ? `${item.region}, Coree du Sud` : 'Coree du Sud',
    condition: 'Occasion',
    description: `${cat.manufacturerEnglishName ?? ''} ${cat.modelGroupEnglishName ?? ''}${cat.formYear ? ' ' + cat.formYear : ''} - importe de Coree du Sud.`.replace(/\s+/g, ' ').trim(),
    photos: item.photos, price_fcfa: computePriceFcfa(item.priceManwon), is_active: true,
  };
}

async function upsert(rows) {
  const url = `${CFG.url}/rest/v1/vehicle_listings?on_conflict=reference`;
  for (let i = 0; i < rows.length; i += 100) {
    const chunk = rows.slice(i, i + 100);
    const res = await fetch(url, {
      method: 'POST',
      headers: { apikey: CFG.key, Authorization: 'Bearer ' + CFG.key, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates,return=minimal' },
      body: JSON.stringify(chunk),
    });
    if (!res.ok) throw new Error(`Upsert HTTP ${res.status} : ${(await res.text()).slice(0, 200)}`);
  }
}

(async () => {
  const t0 = Date.now();
  console.log(`[encar-import] liste (max ${MAX_ITEMS})…`);
  const list = await fetchList();
  const seen = new Set();
  const uniq = list.filter((it) => (seen.has(it.id) ? false : (seen.add(it.id), true)));
  console.log(`[encar-import] ${uniq.length} annonces, récupération des fiches…`);
  const byRef = new Map();
  let done = 0;
  for (const item of uniq) {
    try { const row = await fetchDetail(item); if (row) byRef.set(row.reference, row); } catch (_) {}
    if (++done % 25 === 0) console.log(`  … ${done}/${uniq.length}`);
    await sleep(DETAIL_DELAY_MS);
  }
  const rows = [...byRef.values()];
  console.log(`[encar-import] ${rows.length} véhicules < ${MIN_YEAR + 1} ans -> upsert…`);
  await upsert(rows);
  console.log(`[encar-import] OK : ${rows.length} véhicules mis à jour en ${((Date.now() - t0) / 1000).toFixed(0)}s.`);
})().catch((e) => { console.error('[encar-import] ÉCHEC :', e.message); process.exit(1); });
