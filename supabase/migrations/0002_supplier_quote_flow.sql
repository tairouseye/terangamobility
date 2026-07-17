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
