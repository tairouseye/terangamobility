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
