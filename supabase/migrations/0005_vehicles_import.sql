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
