# Import Encar → `vehicle_listings`

Edge Function Supabase (Deno) qui alimente le catalogue véhicules à partir de
l'API interne d'Encar. L'application Flutter ne fait que **lire**
`vehicle_listings` — jamais Encar directement.

```
Encar  →  [Edge Function encar-import, planifiée]  →  vehicle_listings  →  App
```

> ⚠️ **Le prix n'est jamais importé** (règle métier). Le mapping l'ignore volontairement.

## Comment ça marche (validé sur l'API live)

Deux appels par exécution :

1. **Liste** — `api.encar.com/search/car/list/general`
   → renvoie les `Id`, les photos (`Photos[].location`) et la région.
2. **Fiche** — `api.encar.com/v1/readside/vehicle/{Id}` (un appel par véhicule)
   → renvoie les specs complètes. La fiche fournit déjà les **noms en anglais**
   (`manufacturerEnglishName`, `modelGroupEnglishName`, `gradeEnglishName`),
   plus `transmissionName` / `fuelName` / `colorName` en coréen (traduits via
   `mappings.ts`), `displacement`, `mileage`, `vin`, etc.

Photos servies depuis `https://ci.encar.com` (format WebP, léger).

---

## ⚠️ À savoir avant de déployer

1. **API interne, non officielle.** Testée et fonctionnelle en 2026-07, mais
   Encar peut la modifier sans préavis. En cas de casse, relancer `?dry=1`
   (voir §4) et ajuster `fetchDetail()` selon la réponse réelle.
2. **CGU.** Vérifier ce qu'Encar autorise avant tout usage automatisé en
   production. Un scraping non autorisé peut être bloqué à tout moment.
3. **Volume.** `MAX_ITEMS` (défaut 40) borne le nombre de fiches par exécution
   (chaque fiche = 1 requête). Augmente-le prudemment ; la planification (§6)
   rafraîchit régulièrement, pas besoin de tout charger d'un coup.
4. **Non repris pour l'instant** : nombre de portes (Encar expose seatCount) et
   libellés d'options (codes numériques Encar à décoder) — enrichissables plus
   tard sans toucher au reste.

---

## 1. Pré-requis

- [Supabase CLI](https://supabase.com/docs/guides/cli) installé (`npm i -g supabase`)
- Être connecté : `supabase login`
- Lier le projet : `supabase link --project-ref dfjikxgklnvqgjlexurv`

## 2. Secrets

```bash
# Secret partagé qui protège le déclenchement de la fonction
supabase secrets set IMPORT_SECRET="un-secret-long-et-aleatoire"
```
`SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont injectés automatiquement
dans les Edge Functions — rien à faire pour eux.

## 3. Déploiement

```bash
supabase functions deploy encar-import
```

## 4. VALIDER d'abord (mode dry-run, n'écrit rien)

```bash
curl -H "x-import-secret: <ton_secret>" \
  "https://dfjikxgklnvqgjlexurv.functions.supabase.co/encar-import?dry=1"
```
La réponse contient `listed` (nb d'annonces vues), `detailed` (nb de fiches
enrichies) et `sample` (3 véhicules prêts à insérer). Vérifie que `sample`
contient bien marque/modèle/année/km/transmission/couleur/photos.
- si `sample` est correct → passe à l'import réel (§5).
- si des champs sont vides → ajuste `fetchDetail()` puis redéploie et re-teste.

## 5. Import réel

```bash
curl -H "x-import-secret: <ton_secret>" \
  "https://dfjikxgklnvqgjlexurv.functions.supabase.co/encar-import"
# -> { "imported": N, "fetched": N }
```
Rouvre l'app → **Véhicules Corée** : les véhicules apparaissent.

## 6. Planifier (quasi-live)

Dans le **SQL Editor**, planifie un appel régulier via `pg_cron` + `pg_net` :

```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Toutes les 6 heures
select cron.schedule(
  'encar-import-6h',
  '0 */6 * * *',
  $$
  select net.http_post(
    url     := 'https://dfjikxgklnvqgjlexurv.functions.supabase.co/encar-import',
    headers := jsonb_build_object('x-import-secret', 'ton-secret')
  );
  $$
);
```
Le catalogue est alors rafraîchi automatiquement (quasi-live, pas temps réel).

---

## Réglages utiles (dans `index.ts`)

| Constante | Rôle |
|---|---|
| `PAGE_SIZE` / `MAX_ITEMS` | Volume récupéré par exécution |
| `encarListUrl()` → `q` | Filtre Encar (marques, type…) |
| `PHOTO_BASE` | Base des URLs de photos |
| `mapItem()` | Correspondance champs Encar → colonnes |
| `mappings.ts` | Dictionnaires coréen → latin |

## Retrait

```sql
-- Supprimer les véhicules importés d'Encar
delete from vehicle_listings where source = 'encar';
-- Désactiver la planification
select cron.unschedule('encar-import-6h');
```
