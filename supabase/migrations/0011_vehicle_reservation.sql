-- =====================================================================
-- Teranga Parts — Reservation vehicule (verrouillage rapide)
--
-- Probleme : une annonce Encar est volatile. Entre le "coup de coeur" du
-- client et l'arrivee de l'argent (cash = lent), le vehicule peut nous
-- echapper. Solution : un petit acompte de RESERVATION (montant fixe,
-- mobile money) verrouille le vehicule 48 h et declenche sa securisation
-- sur Encar ; le gros acompte (cash/virement, RDV agence) suit.
-- =====================================================================

-- 1. Nouveaux statuts de commande (enum). ADD VALUE hors transaction : a
--    lancer AVANT toute utilisation (appels Management API separes).
alter type vehicle_order_status add value if not exists 'en_attente_reservation' before 'en_attente_acompte';
alter type vehicle_order_status add value if not exists 'reservee' before 'en_attente_acompte';
alter type vehicle_order_status add value if not exists 'expiree';

-- 2. Colonnes reservation sur vehicle_orders.
alter table vehicle_orders
  add column if not exists reservation_fee      numeric,
  add column if not exists reservation_paid     boolean not null default false,
  add column if not exists reservation_method   text,
  add column if not exists reservation_deadline timestamptz,
  add column if not exists deposit_appointment_at timestamptz;

-- 3. Disponibilite sur vehicle_listings.
alter table vehicle_listings
  add column if not exists availability     text not null default 'available', -- available|reserved|sold|unavailable
  add column if not exists reserved_order_id uuid,
  add column if not exists reserved_until    timestamptz;
create index if not exists idx_listings_availability on vehicle_listings(availability);

-- 4. RPC client : reserver un vehicule (cree la commande + verrouille le listing).
create or replace function reserve_vehicle(
  p_reference       text,
  p_reservation_fee numeric
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_price  numeric;
  v_avail  text;
  v_order  uuid;
begin
  if v_uid is null then raise exception 'Connexion requise'; end if;

  select price_fcfa, availability into v_price, v_avail
    from vehicle_listings where reference = p_reference for update;

  if v_price is null then raise exception 'Vehicule introuvable ou prix indisponible'; end if;
  if v_avail <> 'available' then raise exception 'Vehicule deja reserve'; end if;

  -- Une seule reservation active (non payee) a la fois par client.
  if exists (select 1 from vehicle_orders
              where client_id = v_uid and status = 'en_attente_reservation') then
    raise exception 'Vous avez deja une reservation en attente de paiement';
  end if;

  insert into vehicle_orders (
    client_id, vehicle_reference, total_price, deposit_amount, balance_amount,
    reservation_fee, reservation_deadline, status, terms_accepted
  ) values (
    v_uid, p_reference, v_price,
    round(v_price * 0.7), round(v_price * 0.3),
    p_reservation_fee, now() + interval '48 hours',
    'en_attente_reservation', true
  ) returning id into v_order;

  update vehicle_listings
     set availability = 'reserved',
         reserved_order_id = v_order,
         reserved_until = now() + interval '48 hours'
   where reference = p_reference;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Nouvelle reservation vehicule',
          'Vehicule ' || p_reference || ' reserve — acompte de reservation attendu (48 h).',
          'reservation', v_order);

  return v_order;
end;
$$;

-- 5. RPC client : declarer le paiement de l'acompte de reservation.
create or replace function declare_reservation_payment(
  p_order_id uuid,
  p_method   text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_client uuid;
  v_ref    text;
begin
  select client_id, vehicle_reference into v_client, v_ref
    from vehicle_orders where id = p_order_id;
  if v_client is null then raise exception 'Commande introuvable'; end if;
  if v_client <> auth.uid() then raise exception 'Acces refuse'; end if;

  update vehicle_orders set reservation_method = p_method where id = p_order_id;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Acompte de reservation declare',
          'Vehicule ' || v_ref || ' — le client indique avoir paye la reservation (' ||
          coalesce(p_method, '?') || '). A verifier puis confirmer.',
          'payment', p_order_id);
end;
$$;

-- 6. RPC admin : relacher une reservation (annulation) + liberer le listing.
create or replace function admin_release_reservation(p_order_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Reserve a l''administrateur'; end if;

  update vehicle_orders set status = 'expiree' where id = p_order_id;

  update vehicle_listings
     set availability = 'available', reserved_order_id = null, reserved_until = null
   where reserved_order_id = p_order_id;
end;
$$;

-- 7. Expiration automatique : reservations non payees > 48 h -> expiree,
--    et liberation des listings dont la reservation n'est plus active.
create or replace function release_expired_reservations()
returns void
language plpgsql security definer set search_path = public as $$
begin
  update vehicle_orders
     set status = 'expiree'
   where status = 'en_attente_reservation'
     and coalesce(reservation_paid, false) = false
     and reservation_deadline < now();

  update vehicle_listings l
     set availability = 'available', reserved_order_id = null, reserved_until = null
   where l.availability = 'reserved'
     and (
       l.reserved_order_id is null
       or exists (select 1 from vehicle_orders o
                   where o.id = l.reserved_order_id and o.status = 'expiree')
     );
end;
$$;

-- 8. Planification (toutes les 15 min) via pg_cron.
select cron.schedule(
  'release-expired-reservations',
  '*/15 * * * *',
  $$ select release_expired_reservations(); $$
);
