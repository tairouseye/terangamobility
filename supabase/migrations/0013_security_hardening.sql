-- =====================================================================
-- Teranga Parts — Durcissement securite (audit)
--
-- La RLS est ROW-level, pas COLUMN-level : une policy UPDATE "ligne m'appartient"
-- laisse le client modifier N'IMPORTE QUELLE colonne de SA ligne. Deux failles
-- d'elevation de privilege en decoulaient :
--   1. profiles : un client pouvait se donner le role 'admin'.
--   2. vehicle_orders : un client pouvait se marquer paye/commande confirmee.
-- On les neutralise par des triggers BEFORE UPDATE qui, pour un utilisateur
-- CONNECTE non-admin, remettent les colonnes protegees a leur ancienne valeur.
-- Les contextes serveur (auth.uid() null : cron, service_role, SQL admin) et
-- les RPC legitimes (drapeau de bypass) ne sont pas brides.
-- =====================================================================

-- 1. profiles : interdit le changement de role par un non-admin connecte.
create or replace function prevent_profile_privilege_escalation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not is_admin() then
    new.role := old.role;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_no_escalation on profiles;
create trigger trg_profiles_no_escalation before update on profiles
  for each row execute function prevent_profile_privilege_escalation();

-- 2. vehicle_orders : le client ne peut modifier que terms_accepted et
--    deposit_appointment_at ; tout le reste (paiements, statut, montants,
--    documents, expedition) est verrouille cote client.
create or replace function guard_vehicle_order_client_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not is_admin()
     and coalesce(current_setting('app.order_guard_bypass', true), '') <> '1' then
    new.total_price          := old.total_price;
    new.deposit_amount       := old.deposit_amount;
    new.balance_amount       := old.balance_amount;
    new.reservation_fee      := old.reservation_fee;
    new.deposit_paid         := old.deposit_paid;
    new.balance_paid         := old.balance_paid;
    new.reservation_paid     := old.reservation_paid;
    new.status               := old.status;
    new.deposit_method       := old.deposit_method;
    new.deposit_reference    := old.deposit_reference;
    new.reservation_method   := old.reservation_method;
    new.client_id            := old.client_id;
    new.vehicle_reference    := old.vehicle_reference;
    new.invoice_path         := old.invoice_path;
    new.contract_path        := old.contract_path;
    new.tracking_number      := old.tracking_number;
    new.shipping_company     := old.shipping_company;
    new.reservation_deadline := old.reservation_deadline;
    new.estimated_departure  := old.estimated_departure;
    new.estimated_arrival    := old.estimated_arrival;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_vorders_guard on vehicle_orders;
create trigger trg_vorders_guard before update on vehicle_orders
  for each row execute function guard_vehicle_order_client_update();

-- 3. La RPC legitime de declaration d'acompte pose le drapeau de bypass
--    (transaction-local) pour pouvoir ecrire deposit_method/deposit_reference.
create or replace function declare_vehicle_deposit(p_order_id uuid, p_method text, p_reference text)
returns void language plpgsql security definer set search_path = public as $$
declare v_client uuid; v_ref text;
begin
  select client_id, vehicle_reference into v_client, v_ref from vehicle_orders where id = p_order_id;
  if v_client is null then raise exception 'Commande introuvable'; end if;
  if v_client <> auth.uid() then raise exception 'Acces refuse'; end if;
  perform set_config('app.order_guard_bypass', '1', true);
  update vehicle_orders set deposit_method = p_method, deposit_reference = p_reference
   where id = p_order_id;
  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Acompte 70% declare',
          'Vehicule ' || v_ref || ' — acompte declare (' || coalesce(p_method, '?') ||
          ', ref ' || coalesce(p_reference, '-') ||
          '). VERIFIER la reception (virements/mobile money annulables) avant de confirmer.',
          'payment', p_order_id);
end;
$$;
