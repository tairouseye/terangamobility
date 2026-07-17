-- =====================================================================
-- Teranga Parts — V2 : flux commande vehicule (acompte/solde securises)
--
-- Le client ne doit pas pouvoir modifier librement sa commande : les
-- paiements passent par des fonctions security-definer qui verifient que la
-- commande lui appartient et qu'elle est dans le bon etat, puis notifient
-- l'admin.
-- =====================================================================

-- Acompte 70% : en_attente_acompte -> commande_confirmee
create or replace function pay_vehicle_deposit(
  p_order_id  uuid,
  p_method    text default null,
  p_reference text default null
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_client uuid;
  v_status vehicle_order_status;
  v_ref    text;
begin
  select client_id, status, vehicle_reference
    into v_client, v_status, v_ref
    from vehicle_orders where id = p_order_id;

  if v_client is null then raise exception 'Commande introuvable'; end if;
  if v_client <> auth.uid() then raise exception 'Acces refuse'; end if;
  if v_status <> 'en_attente_acompte' then
    raise exception 'L''acompte n''est pas attendu pour cette commande';
  end if;

  update vehicle_orders
     set deposit_paid = true, status = 'commande_confirmee'
   where id = p_order_id;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Acompte vehicule recu',
          'Vehicule ' || v_ref || ' — acompte 70% paye',
          'payment', p_order_id);
end;
$$;

-- Solde 30% : arrive_port -> pret_recuperation
create or replace function pay_vehicle_balance(
  p_order_id  uuid,
  p_method    text default null,
  p_reference text default null
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_client uuid;
  v_status vehicle_order_status;
  v_ref    text;
begin
  select client_id, status, vehicle_reference
    into v_client, v_status, v_ref
    from vehicle_orders where id = p_order_id;

  if v_client is null then raise exception 'Commande introuvable'; end if;
  if v_client <> auth.uid() then raise exception 'Acces refuse'; end if;
  if v_status <> 'arrive_port' then
    raise exception 'Le solde n''est pas encore attendu (vehicule pas au port)';
  end if;

  update vehicle_orders
     set balance_paid = true, status = 'pret_recuperation'
   where id = p_order_id;

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin', 'Solde vehicule recu',
          'Vehicule ' || v_ref || ' — solde 30% paye, pret a recuperer',
          'payment', p_order_id);
end;
$$;

-- Notifie le client a chaque changement de statut de sa commande vehicule.
create or replace function notify_vehicle_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status
     and new.client_id is not null then
    insert into notifications (user_id, title, body, type, related_id)
    values (new.client_id, 'Mise a jour de votre vehicule',
            'Nouveau statut : ' || new.status, 'tracking', new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_vehicle_status on vehicle_orders;
create trigger trg_notify_vehicle_status
  after update of status on vehicle_orders
  for each row execute function notify_vehicle_status();
