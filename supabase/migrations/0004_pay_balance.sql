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
