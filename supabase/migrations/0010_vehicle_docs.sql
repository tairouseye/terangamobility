-- =====================================================================
-- Teranga Parts — Paiement vehicule confirme par l'admin + documents
--   (facture puis contrat) livres au client.
-- =====================================================================

-- 1. Colonnes : mode de paiement + chemins des documents dans Storage.
alter table vehicle_orders
  add column if not exists deposit_method text,
  add column if not exists balance_method text,
  add column if not exists invoice_path   text,
  add column if not exists contract_path  text;

-- 2. Le client declare avoir paye -> notifie l'admin.
--    (La RLS interdit au client d'inserer directement dans notifications.)
create or replace function declare_vehicle_payment(
  p_order_id uuid,
  p_kind     text -- 'deposit' | 'balance'
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

  insert into notifications (target_role, title, body, type, related_id)
  values ('admin',
          'Paiement declare par le client',
          'Vehicule ' || v_ref || ' — le client indique avoir paye ' ||
          case when p_kind = 'balance' then 'le solde' else 'l''acompte' end ||
          '. A verifier puis confirmer.',
          'payment', p_order_id);
end;
$$;

-- 3. Bucket prive des documents vehicule (factures, contrats).
insert into storage.buckets (id, name, public)
values ('contracts', 'contracts', false)
on conflict (id) do nothing;

drop policy if exists "contracts: admin tout" on storage.objects;
create policy "contracts: admin tout"
  on storage.objects for all
  using (bucket_id = 'contracts' and is_admin())
  with check (bucket_id = 'contracts' and is_admin());

drop policy if exists "contracts: client lecture dossier" on storage.objects;
create policy "contracts: client lecture dossier"
  on storage.objects for select
  using (
    bucket_id = 'contracts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
