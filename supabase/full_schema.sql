-- =====================================================================
-- TERANGA PARTS — SCHEMA COMPLET (migrations 0001 a 0007 concatenees)
-- A coller en UNE FOIS dans le SQL Editor de Supabase, sur un projet VIDE.
-- =====================================================================



-- #####################################################################
-- ### FICHIER : migrations/0001_initial_schema.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Schema initial (Lot 0)
-- Marketplace pieces detachees coreennes / TerangaMobility
-- PostgreSQL / Supabase — Auth + RLS + Storage
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Types enumeres
-- ---------------------------------------------------------------------
create type user_role   as enum ('client', 'partner_kr', 'admin');
create type order_status as enum (
  'nouvelle_demande', 'recherche_coree', 'piece_trouvee', 'devis_envoye',
  'acompte_paye', 'commande_confirmee', 'piece_achetee', 'expediee',
  'en_transit', 'arrivee_senegal', 'solde_demande', 'payee', 'livree'
);
create type payment_type as enum ('deposit', 'balance');
create type quote_status as enum ('draft', 'sent', 'accepted', 'rejected');

-- ---------------------------------------------------------------------
-- 1. profiles (1 ligne par utilisateur auth)
-- ---------------------------------------------------------------------
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text not null default '',
  whatsapp   text not null default '',
  role       user_role not null default 'client',
  created_at timestamptz not null default now()
);

-- Cree automatiquement le profil a l'inscription
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, whatsapp, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'whatsapp', ''),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'client')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Helper : l'appelant est-il admin ?
create or replace function is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Helper : l'appelant est-il partenaire Coree ?
create or replace function is_partner()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'partner_kr'
  );
$$;

-- ---------------------------------------------------------------------
-- 2. vehicles
-- ---------------------------------------------------------------------
create table vehicles (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references profiles(id) on delete cascade,
  brand           text not null,
  model           text not null,
  year            int,
  engine          text,
  vin             text,
  carte_grise_url text,
  created_at      timestamptz not null default now()
);
create index idx_vehicles_user on vehicles(user_id);

-- ---------------------------------------------------------------------
-- 3. parts_requests
-- ---------------------------------------------------------------------
create table parts_requests (
  id             uuid primary key default gen_random_uuid(),
  client_id      uuid not null references profiles(id) on delete cascade,
  vehicle_id     uuid references vehicles(id) on delete set null,
  part_name      text not null,
  part_photo_url text,
  notes          text,
  status         order_status not null default 'nouvelle_demande',
  created_at     timestamptz not null default now()
);
create index idx_requests_client on parts_requests(client_id);
create index idx_requests_status on parts_requests(status);

-- ---------------------------------------------------------------------
-- 4. suppliers_quotes (propositions partenaire Coree)
-- ---------------------------------------------------------------------
create table suppliers_quotes (
  id             uuid primary key default gen_random_uuid(),
  request_id     uuid not null references parts_requests(id) on delete cascade,
  partner_id     uuid not null references profiles(id) on delete cascade,
  part_ref       text,
  available      boolean not null default true,
  buy_price_krw  numeric,       -- prix d'achat en won
  weight_kg      numeric,
  dimensions     text,
  photo_url      text,
  lead_time_days int,
  created_at     timestamptz not null default now()
);
create index idx_squotes_request on suppliers_quotes(request_id);

-- ---------------------------------------------------------------------
-- 5. customer_quotes (devis chiffre client)
-- ---------------------------------------------------------------------
create table customer_quotes (
  id                uuid primary key default gen_random_uuid(),
  request_id        uuid not null references parts_requests(id) on delete cascade,
  supplier_quote_id uuid references suppliers_quotes(id) on delete set null,
  part_price        numeric not null default 0,  -- FCFA
  fedex_cost        numeric not null default 0,
  customs_cost      numeric not null default 0,
  commission        numeric not null default 0,
  total_fcfa        numeric not null default 0,
  status            quote_status not null default 'draft',
  valid_until       date,
  created_at        timestamptz not null default now()
);
create index idx_cquotes_request on customer_quotes(request_id);

-- ---------------------------------------------------------------------
-- 6. orders
-- ---------------------------------------------------------------------
create table orders (
  id           uuid primary key default gen_random_uuid(),
  quote_id     uuid not null references customer_quotes(id) on delete restrict,
  client_id    uuid not null references profiles(id) on delete cascade,
  status       order_status not null default 'acompte_paye',
  deposit_paid boolean not null default false,
  balance_paid boolean not null default false,
  created_at   timestamptz not null default now()
);
create index idx_orders_client on orders(client_id);

-- ---------------------------------------------------------------------
-- 7. payments (modele 70/30)
-- ---------------------------------------------------------------------
create table payments (
  id        uuid primary key default gen_random_uuid(),
  order_id  uuid not null references orders(id) on delete cascade,
  type      payment_type not null,
  amount    numeric not null,
  method    text,              -- wave / orange_money / especes / virement
  reference text,
  paid_at   timestamptz not null default now()
);
create index idx_payments_order on payments(order_id);

-- ---------------------------------------------------------------------
-- 8. shipments
-- ---------------------------------------------------------------------
create table shipments (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references orders(id) on delete cascade,
  fedex_tracking text,
  transitaire    text,
  eta            date,
  current_step   text,
  created_at     timestamptz not null default now()
);
create index idx_shipments_order on shipments(order_id);

-- ---------------------------------------------------------------------
-- 9. customs_rates (grille douane du transitaire)
-- ---------------------------------------------------------------------
create table customs_rates (
  id           uuid primary key default gen_random_uuid(),
  category     text not null unique,   -- ex: 'general', 'carrosserie', 'electronique'
  rate_percent numeric not null,       -- % applique sur (piece + transport)
  min_fee      numeric not null default 0,
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 10. settings (cle/valeur)
-- ---------------------------------------------------------------------
create table settings (
  key         text primary key,
  value       text not null,
  description text
);

-- ---------------------------------------------------------------------
-- 11. order_status_history (audit du workflow)
-- ---------------------------------------------------------------------
create table order_status_history (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references orders(id) on delete cascade,
  from_status order_status,
  to_status   order_status not null,
  changed_by  uuid references profiles(id) on delete set null,
  changed_at  timestamptz not null default now()
);
create index idx_history_order on order_status_history(order_id);

-- Journalise chaque changement de statut de commande
create or replace function log_order_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into order_status_history (order_id, from_status, to_status, changed_by)
    values (new.id, case when tg_op='UPDATE' then old.status end, new.status, auth.uid());
  end if;
  return new;
end;
$$;

create trigger trg_log_order_status
  after insert or update of status on orders
  for each row execute function log_order_status();

-- =====================================================================
-- FONCTION DE CALCUL DU DEVIS (cote serveur, non falsifiable)
--   total = prix piece + FedEx(poids) + douane(grille) + commission
-- =====================================================================
create or replace function compute_customer_quote(
  p_supplier_quote_id uuid,
  p_customs_category  text default 'general'
)
returns table (
  part_price   numeric,
  fedex_cost   numeric,
  customs_cost numeric,
  commission   numeric,
  total_fcfa   numeric
)
language plpgsql stable security definer set search_path = public as $$
declare
  v_krw_to_fcfa  numeric;
  v_fedex_per_kg numeric;
  v_commission_p numeric;
  v_rate_percent numeric;
  v_min_fee      numeric;
  v_buy_krw      numeric;
  v_weight       numeric;
  v_part         numeric;
  v_fedex        numeric;
  v_customs      numeric;
  v_commission   numeric;
begin
  select coalesce((select value::numeric from settings where key='krw_to_fcfa'), 0.65),
         coalesce((select value::numeric from settings where key='fedex_cost_per_kg'), 9000),
         coalesce((select value::numeric from settings where key='commission_percent'), 15)
    into v_krw_to_fcfa, v_fedex_per_kg, v_commission_p;

  select coalesce(buy_price_krw,0), coalesce(weight_kg,0)
    into v_buy_krw, v_weight
    from suppliers_quotes where id = p_supplier_quote_id;

  select coalesce(rate_percent, 20), coalesce(min_fee, 0)
    into v_rate_percent, v_min_fee
    from customs_rates where category = p_customs_category;
  if not found then
    v_rate_percent := 20; v_min_fee := 0;
  end if;

  v_part     := round(v_buy_krw * v_krw_to_fcfa);
  v_fedex    := round(v_weight * v_fedex_per_kg);
  v_customs  := greatest(round((v_part + v_fedex) * v_rate_percent / 100), v_min_fee);
  v_commission := round((v_part + v_fedex + v_customs) * v_commission_p / 100);

  return query select
    v_part,
    v_fedex,
    v_customs,
    v_commission,
    v_part + v_fedex + v_customs + v_commission;
end;
$$;

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table profiles            enable row level security;
alter table vehicles            enable row level security;
alter table parts_requests      enable row level security;
alter table suppliers_quotes    enable row level security;
alter table customer_quotes     enable row level security;
alter table orders              enable row level security;
alter table payments            enable row level security;
alter table shipments           enable row level security;
alter table customs_rates       enable row level security;
alter table settings            enable row level security;
alter table order_status_history enable row level security;

-- --- profiles ---
create policy "profiles: lecture soi ou admin"
  on profiles for select using (id = auth.uid() or is_admin());
create policy "profiles: maj soi"
  on profiles for update using (id = auth.uid());
create policy "profiles: admin tout"
  on profiles for all using (is_admin()) with check (is_admin());

-- --- vehicles (client proprietaire, admin) ---
create policy "vehicles: proprietaire"
  on vehicles for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "vehicles: admin"
  on vehicles for all using (is_admin()) with check (is_admin());

-- --- parts_requests (client proprietaire ; partenaire en lecture ; admin) ---
create policy "requests: client proprietaire"
  on parts_requests for all using (client_id = auth.uid()) with check (client_id = auth.uid());
create policy "requests: partenaire lecture"
  on parts_requests for select using (is_partner());
create policy "requests: admin"
  on parts_requests for all using (is_admin()) with check (is_admin());

-- --- suppliers_quotes (partenaire ecrit les siennes ; client lit celles de ses demandes ; admin) ---
create policy "squotes: partenaire les siennes"
  on suppliers_quotes for all using (partner_id = auth.uid()) with check (partner_id = auth.uid());
create policy "squotes: client lecture via sa demande"
  on suppliers_quotes for select using (
    exists (select 1 from parts_requests r where r.id = request_id and r.client_id = auth.uid())
  );
create policy "squotes: admin"
  on suppliers_quotes for all using (is_admin()) with check (is_admin());

-- --- customer_quotes (client lit les siens ; admin gere) ---
create policy "cquotes: client lecture via sa demande"
  on customer_quotes for select using (
    exists (select 1 from parts_requests r where r.id = request_id and r.client_id = auth.uid())
  );
create policy "cquotes: admin"
  on customer_quotes for all using (is_admin()) with check (is_admin());

-- --- orders (client proprietaire lecture ; admin gere) ---
create policy "orders: client lecture"
  on orders for select using (client_id = auth.uid());
create policy "orders: admin"
  on orders for all using (is_admin()) with check (is_admin());

-- --- payments (client lecture via sa commande ; admin gere) ---
create policy "payments: client lecture"
  on payments for select using (
    exists (select 1 from orders o where o.id = order_id and o.client_id = auth.uid())
  );
create policy "payments: admin"
  on payments for all using (is_admin()) with check (is_admin());

-- --- shipments (client lecture via sa commande ; admin gere) ---
create policy "shipments: client lecture"
  on shipments for select using (
    exists (select 1 from orders o where o.id = order_id and o.client_id = auth.uid())
  );
create policy "shipments: admin"
  on shipments for all using (is_admin()) with check (is_admin());

-- --- customs_rates & settings (lecture authentifiee ; ecriture admin) ---
create policy "customs: lecture auth"
  on customs_rates for select using (auth.role() = 'authenticated');
create policy "customs: admin ecriture"
  on customs_rates for all using (is_admin()) with check (is_admin());
create policy "settings: lecture auth"
  on settings for select using (auth.role() = 'authenticated');
create policy "settings: admin ecriture"
  on settings for all using (is_admin()) with check (is_admin());

-- --- order_status_history (client lecture via sa commande ; admin) ---
create policy "history: client lecture"
  on order_status_history for select using (
    exists (select 1 from orders o where o.id = order_id and o.client_id = auth.uid())
  );
create policy "history: admin"
  on order_status_history for select using (is_admin());

-- =====================================================================
-- SEED : parametres par defaut + grille douane indicative
--   (a ajuster avec le transitaire et le cours reel du won)
-- =====================================================================
insert into settings (key, value, description) values
  ('krw_to_fcfa',        '0.65', 'Taux de conversion 1 KRW -> FCFA'),
  ('fedex_cost_per_kg',  '9000', 'Cout FedEx estime par kg (FCFA)'),
  ('commission_percent', '15',   'Commission Teranga Parts (%)'),
  ('company_whatsapp',   '221770000000', 'Contact WhatsApp Teranga Parts')
on conflict (key) do nothing;

insert into customs_rates (category, rate_percent, min_fee) values
  ('general',      20, 5000),
  ('carrosserie',  25, 5000),
  ('electronique', 30, 8000),
  ('mecanique',    20, 5000)
on conflict (category) do nothing;


-- #####################################################################
-- ### FICHIER : migrations/0002_supplier_quote_flow.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Lot 4 : flux partenaire Coree
--  1. Instantane du vehicule fige dans la demande (visible par le partenaire
--     sans acceder a la table vehicles, protegee par RLS).
--  2. Passage automatique de la demande a 'piece_trouvee' quand le
--     partenaire soumet une proposition.
-- =====================================================================

-- 1. Colonnes instantane vehicule sur parts_requests
alter table parts_requests
  add column if not exists vehicle_brand  text,
  add column if not exists vehicle_model  text,
  add column if not exists vehicle_year   int,
  add column if not exists vehicle_engine text,
  add column if not exists vehicle_vin    text;

-- 2. Quand une proposition partenaire est inseree, la demande passe a
--    'piece_trouvee' (si elle etait encore en amont). Respecte la RLS
--    car execute en security definer.
create or replace function on_supplier_quote_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update parts_requests
     set status = 'piece_trouvee'
   where id = new.request_id
     and status in ('nouvelle_demande', 'recherche_coree');
  return new;
end;
$$;

drop trigger if exists trg_supplier_quote_insert on suppliers_quotes;
create trigger trg_supplier_quote_insert
  after insert on suppliers_quotes
  for each row execute function on_supplier_quote_insert();


-- #####################################################################
-- ### FICHIER : migrations/0003_pay_deposit.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Lot 6 : paiement de l'acompte 70%
-- Le client ne peut pas ecrire directement dans orders/payments (RLS).
-- Cette fonction security-definer valide que le devis lui appartient,
-- cree la commande + la ligne de paiement acompte, et avance les statuts.
-- =====================================================================
create or replace function pay_deposit(
  p_quote_id  uuid,
  p_method    text default null,
  p_reference text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_client   uuid;
  v_total    numeric;
  v_request  uuid;
  v_deposit  numeric;
  v_order    uuid;
begin
  -- Le devis appartient-il a l'appelant ?
  select r.client_id, q.total_fcfa, q.request_id
    into v_client, v_total, v_request
    from customer_quotes q
    join parts_requests r on r.id = q.request_id
   where q.id = p_quote_id;

  if v_client is null then
    raise exception 'Devis introuvable';
  end if;
  if v_client <> auth.uid() then
    raise exception 'Acces refuse a ce devis';
  end if;

  v_deposit := round(v_total * 0.7);

  insert into orders (quote_id, client_id, status, deposit_paid)
  values (p_quote_id, v_client, 'acompte_paye', true)
  returning id into v_order;

  insert into payments (order_id, type, amount, method, reference)
  values (v_order, 'deposit', v_deposit, p_method, p_reference);

  update customer_quotes set status = 'accepted' where id = p_quote_id;
  update parts_requests   set status = 'acompte_paye' where id = v_request;

  return v_order;
end;
$$;


-- #####################################################################
-- ### FICHIER : migrations/0004_pay_balance.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Lot 7 : paiement du solde 30% (avant livraison)
-- Miroir de pay_deposit(). Le client regle les 30% restants quand la
-- commande est en 'solde_demande' ; la commande passe alors a 'payee'.
-- =====================================================================
create or replace function pay_balance(
  p_order_id  uuid,
  p_method    text default null,
  p_reference text default null
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_client  uuid;
  v_total   numeric;
  v_status  order_status;
  v_balance numeric;
begin
  select o.client_id, q.total_fcfa, o.status
    into v_client, v_total, v_status
    from orders o
    join customer_quotes q on q.id = o.quote_id
   where o.id = p_order_id;

  if v_client is null then
    raise exception 'Commande introuvable';
  end if;
  if v_client <> auth.uid() then
    raise exception 'Acces refuse a cette commande';
  end if;
  if v_status <> 'solde_demande' then
    raise exception 'Le solde n''est pas encore demande pour cette commande';
  end if;

  -- Solde = total - acompte (70%)
  v_balance := v_total - round(v_total * 0.7);

  insert into payments (order_id, type, amount, method, reference)
  values (p_order_id, 'balance', v_balance, p_method, p_reference);

  update orders
     set balance_paid = true, status = 'payee'
   where id = p_order_id;
end;
$$;


-- #####################################################################
-- ### FICHIER : migrations/0005_vehicles_import.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Module IMPORT DE VEHICULES depuis la Coree (Encar)
-- Source : https://car.encar.com/
-- V1 : catalogue, demandes de prix, commandes, suivi maritime, notifications
--
-- Principe : l'application ne lit QUE la table vehicle_listings (remplie par
-- un import independant). Le prix Encar n'est jamais importe ni stocke ici.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Types enumeres
-- ---------------------------------------------------------------------
create type vehicle_request_status as enum (
  'en_attente_devis', 'devis_envoye', 'accepte', 'refuse', 'clos'
);

-- Statuts de commande = etapes du suivi maritime (60-90 jours).
create type vehicle_order_status as enum (
  'en_attente_acompte',   -- devis accepte, acompte 70% attendu
  'commande_confirmee',   -- acompte recu
  'vehicule_achete',
  'preparation',
  'charge_container',
  'navire_en_mer',
  'arrive_port',          -- solde 30% attendu
  'pret_recuperation',
  'livre'
);

-- ---------------------------------------------------------------------
-- 1. vehicle_listings — catalogue importe (SANS prix)
-- ---------------------------------------------------------------------
create table vehicle_listings (
  id          uuid primary key default gen_random_uuid(),
  reference   text not null unique,        -- numero de reference (Encar)
  source      text not null default 'encar',
  brand       text not null,
  model       text not null,
  year        int,
  version     text,
  engine      text,                        -- motorisation
  displacement text,                       -- cylindree
  mileage_km  int,
  transmission text,                       -- auto / manuelle
  fuel        text,                        -- essence / diesel / hybride...
  color       text,
  doors       int,
  steering    text,                        -- 'left' / 'right'
  location    text,
  condition   text,                        -- etat du vehicule
  options     text[] default '{}',
  description text,
  photos      text[] default '{}',
  is_active   boolean not null default true,
  imported_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);
create index idx_listings_brand on vehicle_listings(brand);
create index idx_listings_model on vehicle_listings(model);
create index idx_listings_active on vehicle_listings(is_active);

-- ---------------------------------------------------------------------
-- 2. vehicle_requests — demande de prix d'un client
-- ---------------------------------------------------------------------
create table vehicle_requests (
  id                uuid primary key default gen_random_uuid(),
  client_id         uuid references profiles(id) on delete set null,
  vehicle_reference text not null,
  customer_name     text not null,
  phone             text not null,
  whatsapp          text,
  email             text,
  country           text,
  city              text,
  message           text,
  status            vehicle_request_status not null default 'en_attente_devis',
  created_at        timestamptz not null default now()
);
create index idx_vreq_client on vehicle_requests(client_id);
create index idx_vreq_status on vehicle_requests(status);
create index idx_vreq_ref on vehicle_requests(vehicle_reference);

-- ---------------------------------------------------------------------
-- 3. vehicle_orders — commande de vehicule
-- ---------------------------------------------------------------------
create table vehicle_orders (
  id                 uuid primary key default gen_random_uuid(),
  request_id         uuid references vehicle_requests(id) on delete set null,
  client_id          uuid references profiles(id) on delete set null,
  vehicle_reference  text not null,
  total_price        numeric,              -- fixe par l'admin (devis)
  deposit_amount     numeric,              -- 70%
  balance_amount     numeric,              -- 30%
  deposit_paid       boolean not null default false,
  balance_paid       boolean not null default false,
  tracking_number    text,
  shipping_company   text,
  estimated_departure date,
  estimated_arrival  date,
  status             vehicle_order_status not null default 'en_attente_acompte',
  terms_accepted     boolean not null default false, -- conditions douane/30%
  created_at         timestamptz not null default now()
);
create index idx_vorders_client on vehicle_orders(client_id);
create index idx_vorders_status on vehicle_orders(status);
create index idx_vorders_ref on vehicle_orders(vehicle_reference);

-- ---------------------------------------------------------------------
-- 4. vehicle_tracking — historique des etapes du suivi maritime
-- ---------------------------------------------------------------------
create table vehicle_tracking (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references vehicle_orders(id) on delete cascade,
  status      vehicle_order_status not null,
  description text,
  location    text,
  created_at  timestamptz not null default now()
);
create index idx_vtracking_order on vehicle_tracking(order_id);

-- Journalise chaque changement de statut de commande vehicule.
create or replace function log_vehicle_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into vehicle_tracking (order_id, status, description)
    values (new.id, new.status, null);
  end if;
  return new;
end;
$$;
create trigger trg_log_vehicle_status
  after insert or update of status on vehicle_orders
  for each row execute function log_vehicle_status();

-- ---------------------------------------------------------------------
-- 5. notifications — client + administrateur
-- ---------------------------------------------------------------------
create table notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references profiles(id) on delete cascade, -- destinataire client
  target_role user_role,                                      -- ex: 'admin'
  title       text not null,
  body        text,
  type        text,        -- 'vehicle_request', 'quote', 'payment', 'tracking'...
  related_id  uuid,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);
create index idx_notif_user on notifications(user_id);
create index idx_notif_role on notifications(target_role);

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table vehicle_listings enable row level security;
alter table vehicle_requests enable row level security;
alter table vehicle_orders   enable row level security;
alter table vehicle_tracking enable row level security;
alter table notifications    enable row level security;

-- --- vehicle_listings : lecture pour tout authentifie ; ecriture admin ---
create policy "listings: lecture auth"
  on vehicle_listings for select using (auth.role() = 'authenticated');
create policy "listings: admin ecriture"
  on vehicle_listings for all using (is_admin()) with check (is_admin());

-- --- vehicle_requests : le client cree/lit les siennes ; admin tout ---
create policy "vreq: client insert"
  on vehicle_requests for insert with check (client_id = auth.uid());
create policy "vreq: client lecture"
  on vehicle_requests for select using (client_id = auth.uid());
create policy "vreq: admin"
  on vehicle_requests for all using (is_admin()) with check (is_admin());

-- --- vehicle_orders : client lecture ; admin gere ---
create policy "vorders: client lecture"
  on vehicle_orders for select using (client_id = auth.uid());
create policy "vorders: client accept terms"
  on vehicle_orders for update using (client_id = auth.uid())
  with check (client_id = auth.uid());
create policy "vorders: admin"
  on vehicle_orders for all using (is_admin()) with check (is_admin());

-- --- vehicle_tracking : client lecture via sa commande ; admin ---
create policy "vtracking: client lecture"
  on vehicle_tracking for select using (
    exists (select 1 from vehicle_orders o
            where o.id = order_id and o.client_id = auth.uid())
  );
create policy "vtracking: admin"
  on vehicle_tracking for all using (is_admin()) with check (is_admin());

-- --- notifications : destinataire (client) ou admin pour le role admin ---
create policy "notif: destinataire lecture"
  on notifications for select using (
    user_id = auth.uid() or (target_role = 'admin' and is_admin())
  );
create policy "notif: destinataire maj (lu)"
  on notifications for update using (
    user_id = auth.uid() or (target_role = 'admin' and is_admin())
  );
create policy "notif: admin insert"
  on notifications for insert with check (is_admin());
-- (les notifications sont surtout creees cote serveur / fonctions security definer)

-- =====================================================================
-- Fonction : creer une demande de prix + notifier l'admin (atomique).
-- Appelable par le client (security definer contourne l'insert notifications).
-- =====================================================================
create or replace function create_vehicle_request(
  p_vehicle_reference text,
  p_customer_name     text,
  p_phone             text,
  p_whatsapp          text default null,
  p_email             text default null,
  p_country           text default null,
  p_city              text default null,
  p_message           text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  insert into vehicle_requests (
    client_id, vehicle_reference, customer_name, phone, whatsapp,
    email, country, city, message, status
  ) values (
    auth.uid(), p_vehicle_reference, p_customer_name, p_phone, p_whatsapp,
    p_email, p_country, p_city, p_message, 'en_attente_devis'
  ) returning id into v_id;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Nouvelle demande de devis',
          'Vehicule ' || p_vehicle_reference || ' — ' || p_customer_name,
          'vehicle_request', v_id);

  return v_id;
end;
$$;


-- #####################################################################
-- ### FICHIER : migrations/0006_storage_buckets.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Buckets Storage + policies
-- Cree les 2 buckets PRIVES attendus par l'application :
--   documents : cartes grises (1 dossier par utilisateur)
--   parts     : photos de pieces (demandes client / propositions partenaire)
--
-- Convention de chemin : <user_id>/<timestamp>.<ext>
-- => le 1er segment du chemin doit etre l'uid de l'appelant.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('documents', 'documents', false),
       ('parts', 'parts', false)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- documents (cartes grises) : chaque client gere son propre dossier ;
-- l'admin voit tout.
-- ---------------------------------------------------------------------
drop policy if exists "documents: proprietaire lecture" on storage.objects;
create policy "documents: proprietaire lecture"
  on storage.objects for select
  using (
    bucket_id = 'documents'
    and (owner = auth.uid() or (storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "documents: proprietaire ecriture" on storage.objects;
create policy "documents: proprietaire ecriture"
  on storage.objects for insert
  with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "documents: proprietaire maj" on storage.objects;
create policy "documents: proprietaire maj"
  on storage.objects for update
  using (
    bucket_id = 'documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "documents: proprietaire suppression" on storage.objects;
create policy "documents: proprietaire suppression"
  on storage.objects for delete
  using (
    bucket_id = 'documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

-- ---------------------------------------------------------------------
-- parts (photos de pieces) : l'auteur gere son dossier ; lecture ouverte
-- aux utilisateurs authentifies (le partenaire Coree et l'admin doivent
-- voir la photo envoyee par le client, et inversement).
-- ---------------------------------------------------------------------
drop policy if exists "parts: lecture authentifiee" on storage.objects;
create policy "parts: lecture authentifiee"
  on storage.objects for select
  using (bucket_id = 'parts' and auth.role() = 'authenticated');

drop policy if exists "parts: auteur ecriture" on storage.objects;
create policy "parts: auteur ecriture"
  on storage.objects for insert
  with check (
    bucket_id = 'parts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "parts: auteur maj" on storage.objects;
create policy "parts: auteur maj"
  on storage.objects for update
  using (
    bucket_id = 'parts'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "parts: auteur suppression" on storage.objects;
create policy "parts: auteur suppression"
  on storage.objects for delete
  using (
    bucket_id = 'parts'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );


-- #####################################################################
-- ### FICHIER : migrations/0007_public_catalog.sql
-- #####################################################################

-- =====================================================================
-- Teranga Parts — Catalogue vehicules consultable SANS COMPTE
--
-- Pourquoi : obliger un prospect a creer un compte avant meme de regarder
-- les vehicules fait chuter la conversion. Usage marketplace standard :
--   - catalogue visible par tous (visiteurs anonymes inclus)
--   - compte requis uniquement pour « Demander le prix »
--
-- Sans risque : vehicle_listings ne contient NI prix NI donnee personnelle,
-- uniquement des caracteristiques techniques et des photos publiques.
-- Toutes les autres tables restent protegees a l'identique.
-- =====================================================================

drop policy if exists "listings: lecture auth" on vehicle_listings;

create policy "listings: lecture publique"
  on vehicle_listings for select
  using (true);

-- L'ecriture reste strictement reservee a l'admin (policy inchangee,
-- rappelee ici pour memoire) :
--   create policy "listings: admin ecriture"
--     on vehicle_listings for all using (is_admin()) with check (is_admin());
