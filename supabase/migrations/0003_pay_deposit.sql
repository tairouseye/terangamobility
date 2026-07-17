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
