# Teranga Parts

Marketplace de pièces détachées coréennes — marque **TerangaMobility**.
_« Vos pièces automobiles directement de Corée »_

Flutter (Android / iOS / Web) + Supabase (Auth, PostgreSQL, Storage, RLS).

## Architecture

Feature-first, 3 couches : **UI → Provider (Riverpod) → Service (Supabase)**.

```
lib/
├── core/        config, thème (Rouge/Vert/Blanc), router+guards, widgets, utils
├── models/      DTO typés + enums (13 statuts, rôles, paiement)
├── services/    auth_service, storage_service (+ à venir)
├── providers/   providers Riverpod (auth, session, profil/rôle)
└── features/
    ├── auth/        splash, login, signup (choix rôle)
    ├── client/      espace client
    ├── partner_kr/  espace partenaire Corée
    ├── admin/       espace admin
    └── shared/      ossature commune des dashboards
supabase/migrations/  schéma SQL versionné (tables + RLS + fonction devis)
lib/demo/             mode démo hors-ligne (données en mémoire, sans Supabase)
```

## Mode démo (sans Supabase)

Pour explorer l'app **sans aucun backend**, avec des données fictives en mémoire :

```
flutter run -t lib/main_demo.dart
```

(fonctionne sur Chrome, un émulateur ou en desktop). Un écran d'accueil permet
de choisir l'espace **Client / Partenaire Corée / Admin**. Les actions
(ajouter un véhicule, déposer une demande, chiffrer un devis, payer l'acompte,
faire avancer une commande…) sont fonctionnelles et se répercutent entre écrans,
mais rien n'est persisté : tout repart à zéro au redémarrage.

## Déploiement (Netlify)

La **démo** est en ligne : **https://teranga-parts-demo.netlify.app**
(site Netlify `teranga-parts-demo`, id `353d44d0-a7b5-4cc5-a9fa-51e76b494176`)

Le SDK Flutter n'existe pas dans l'image de build Netlify : on **build en local**
puis on publie le dossier `build/web`.

### Redéployer la démo
```bash
flutter build web --release -t lib/main_demo.dart
NETLIFY_AUTH_TOKEN=<ton_token> npx netlify-cli deploy --prod --no-build \
  --dir=build/web --site=teranga-parts-demo
```

### Déployer l'app réelle (quand Supabase sera prêt)
```bash
flutter build web --release          # main.dart par defaut
NETLIFY_AUTH_TOKEN=<ton_token> npx netlify-cli deploy --prod --no-build \
  --dir=build/web --site=<site-de-l-app-reelle>
```

`web/_redirects` et `web/_headers` sont copiés automatiquement dans `build/web` :
ils assurent le routage SPA (pas de 404 sur /client au refresh) et le `no-cache`
sur `index.html` (sinon les utilisateurs restent bloqués sur une vieille version).

> ⚠️ **Piège rencontré** : l'antivirus AVG intercepte le TLS sur ce poste
> (`SSLKEYLOGFILE=\\.\avgMonFltProxy\...`). Résultat : `curl` échoue sur tous les
> sites HTTPS depuis Git Bash, et l'outil `@netlify/mcp` casse sur les gros
> uploads. `netlify-cli` et PowerShell passent sans problème.

## Mise en route

### 1. Créer le projet Supabase
Créer un **nouveau projet Supabase dédié** puis récupérer `Project URL` et `anon key`
(Project Settings → API).

### 2. Appliquer le schéma
Coller le contenu de `supabase/migrations/0001_initial_schema.sql` dans le
**SQL Editor** de Supabase et exécuter. Cela crée les 10 tables + l'audit,
la RLS, la fonction `compute_customer_quote()` et les paramètres par défaut.

### 3. Créer les buckets Storage (privés)
- `documents` — cartes grises
- `parts` — photos de pièces

### 4. Renseigner les clés
Dans `lib/core/config/supabase_config.dart`, remplacer `VOTRE_PROJET` et
`VOTRE_CLE_ANON`, **ou** lancer avec :
```
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### 5. Promouvoir un admin
Les inscriptions créent des rôles `client` ou `partner_kr`. Pour un admin :
```sql
update profiles set role = 'admin' where id = '<uid>';
```

## Modèle de devis (serveur)

`total = prix_pièce + FedEx(poids) + douane(grille) + commission`

Calculé par `compute_customer_quote()` à partir de `settings`
(taux KRW→FCFA, coût FedEx/kg, % commission) et `customs_rates`.
Paiement **70 % acompte / 30 % solde**.

## État d'avancement (MVP)

- [x] **Lot 0** — Scaffold : projet, thème, config, schéma SQL + RLS, auth 3 rôles
- [ ] Lot 1 — Auth finalisée (reset mot de passe)
- [x] **Lot 2** — Véhicules (CRUD + upload carte grise)
- [x] **Lot 3** — Demande de pièce (formulaire + photo + liste/statut)
- [x] **Lot 4** — Espace partenaire Corée (inbox demandes + propositions)
- [x] **Lot 5** — Devis chiffré (compute serveur) + validation client
- [x] **Lot 6** — Acompte 70 % (fonction `pay_deposit` → commande)
- [x] **Lot 7** — Suivi commande (timeline 13 statuts), solde 30 % (`pay_balance`), pilotage admin (statuts + expédition FedEx)

**MVP fonctionnel complet.** Reste hors-MVP : Lot 1 (reset mot de passe), intégration paiement PSP (Wave API…), notifications WhatsApp, module admin clients/paramètres douane.
