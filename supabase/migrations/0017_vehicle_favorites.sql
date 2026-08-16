-- =====================================================================
-- 0017 — Favoris véhicules (« J'aime »)
--
-- Permet à TOUT utilisateur connecté (client comme admin) de marquer des
-- véhicules « qui pourraient l'intéresser » et de les retrouver ensuite.
-- Chacun ne voit et ne gère QUE ses propres favoris.
-- =====================================================================

create table if not exists public.vehicle_favorites (
  id          uuid primary key default gen_random_uuid(),
  reference   text not null,                 -- reference du vehicule (EC-...)
  note        text,                          -- annotation libre (optionnel)
  created_by  uuid not null default auth.uid()
                references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (reference, created_by)
);

alter table public.vehicle_favorites enable row level security;

-- Chaque utilisateur connecté gère UNIQUEMENT ses propres favoris.
drop policy if exists fav_owner_all on public.vehicle_favorites;
create policy fav_owner_all on public.vehicle_favorites
  for all using (created_by = auth.uid())
  with check (created_by = auth.uid());

create index if not exists idx_vehicle_favorites_by
  on public.vehicle_favorites(created_by);
create index if not exists idx_vehicle_favorites_ref
  on public.vehicle_favorites(reference);
