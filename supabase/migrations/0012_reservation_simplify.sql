-- =====================================================================
-- Teranga Parts — Reservation SIMPLIFIEE
--
-- Modele : le client reserve en 1 tap (gratuit) -> vehicule bloque 72 h ->
-- il paie les 70 % (multi-canal) pour confirmer la commande. Achat Encar
-- seulement apres reception verifiee (virements/mobile money annulables).
--
-- Remplace la version "2 paliers" (0011) : plus d'acompte de reservation.
-- =====================================================================

-- 1. Colonnes complementaires sur vehicle_orders.
alter table vehicle_orders
  add column if not exists deposit_reference text,
  add column if not exists deposit_proof_path text,
  add column if not exists deposit_reminded boolean not null default false,
  add column if not exists client_name text,
  add column if not exists client_whatsapp text;

-- 2. Reservation : cree la commande (statut en_attente_acompte, 72 h) et
--    verrouille le listing. Copie nom + WhatsApp du profil.
create or replace function reserve_vehicle(p_reference text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_price numeric;
  v_avail text;
  v_order uuid;
  v_name  text;
  v_wa    text;
begin
  if v_uid is null then raise exception 'Connexion requise'; end if;

  select price_fcfa, availability into v_price, v_avail
    from vehicle_listings where reference = p_reference for update;
  if v_price is null then raise exception 'Vehicule introuvable ou prix indisponible'; end if;
  if v_avail <> 'available' then raise exception 'Vehicule deja reserve'; end if;

  if exists (select 1 from vehicle_orders
              where client_id = v_uid and status = 'en_attente_acompte'
                and coalesce(deposit_paid, false) = false) then
    raise exception 'Vous avez deja une reservation en attente de paiement';
  end if;

  select full_name, whatsapp into v_name, v_wa from profiles where id = v_uid;

  insert into vehicle_orders (
    client_id, vehicle_reference, total_price, deposit_amount, balance_amount,
    reservation_deadline, status, terms_accepted, client_name, client_whatsapp
  ) values (
    v_uid, p_reference, v_price, round(v_price * 0.7), round(v_price * 0.3),
    now() + interval '72 hours', 'en_attente_acompte', true, v_name, v_wa
  ) returning id into v_order;

  update vehicle_listings
     set availability = 'reserved', reserved_order_id = v_order,
         reserved_until = now() + interval '72 hours'
   where reference = p_reference;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Nouvelle reservation vehicule',
          'Vehicule ' || p_reference || ' reserve — acompte 70% attendu sous 72 h.',
          'reservation', v_order);

  return v_order;
end;
$$;

-- 3. Le client declare le paiement des 70 % (methode + reference transaction).
create or replace function declare_vehicle_deposit(
  p_order_id  uuid,
  p_method    text,
  p_reference text
)
returns void language plpgsql security definer set search_path = public as $$
declare v_client uuid; v_ref text;
begin
  select client_id, vehicle_reference into v_client, v_ref
    from vehicle_orders where id = p_order_id;
  if v_client is null then raise exception 'Commande introuvable'; end if;
  if v_client <> auth.uid() then raise exception 'Acces refuse'; end if;

  update vehicle_orders
     set deposit_method = p_method, deposit_reference = p_reference
   where id = p_order_id;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Acompte 70% declare',
          'Vehicule ' || v_ref || ' — acompte declare (' || coalesce(p_method, '?') ||
          ', ref ' || coalesce(p_reference, '-') ||
          '). VERIFIER la reception (virements/mobile money annulables) avant de confirmer.',
          'payment', p_order_id);
end;
$$;

-- 4. Expiration + rappel (< 24 h). Cible desormais en_attente_acompte non paye.
create or replace function release_expired_reservations()
returns void language plpgsql security definer set search_path = public as $$
begin
  -- Rappel client a moins de 24 h de l'echeance (une seule fois).
  insert into notifications (user_id, title, body, type, related_id)
    select o.client_id, 'Reservation bientot expiree',
           'Il vous reste moins de 24 h pour payer l''acompte de 70% du vehicule '
             || o.vehicle_reference || '.',
           'payment', o.id
      from vehicle_orders o
     where o.status = 'en_attente_acompte'
       and coalesce(o.deposit_paid, false) = false
       and coalesce(o.deposit_reminded, false) = false
       and o.client_id is not null
       and o.reservation_deadline between now() and now() + interval '24 hours';

  update vehicle_orders set deposit_reminded = true
   where status = 'en_attente_acompte'
     and coalesce(deposit_paid, false) = false
     and coalesce(deposit_reminded, false) = false
     and reservation_deadline between now() and now() + interval '24 hours';

  -- Expiration des reservations non payees.
  update vehicle_orders set status = 'expiree'
   where status = 'en_attente_acompte'
     and coalesce(deposit_paid, false) = false
     and reservation_deadline < now();

  -- Liberation des listings dont la reservation n'est plus active.
  update vehicle_listings l
     set availability = 'available', reserved_order_id = null, reserved_until = null
   where l.availability = 'reserved'
     and (l.reserved_order_id is null
          or exists (select 1 from vehicle_orders o
                      where o.id = l.reserved_order_id and o.status = 'expiree'));
end;
$$;
