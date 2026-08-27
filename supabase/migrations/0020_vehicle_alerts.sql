-- =====================================================================
-- 0020 — Alertes véhicule (« Prévenez-moi »)
--
-- L'utilisateur enregistre une recherche (marque / carburant / prix max /
-- année mini). À chaque import quotidien, notify_alert_matches() rapproche les
-- NOUVEAUX véhicules (imported_at > dernière notif) et crée une notification
-- in-app par alerte qui a des correspondances. Réengage les acheteurs.
-- =====================================================================

create table if not exists public.vehicle_alerts (
  id              uuid primary key default gen_random_uuid(),
  created_by      uuid not null default auth.uid()
                    references auth.users(id) on delete cascade,
  label           text,             -- résumé lisible (« Électrique · ≤ 8M »)
  brand           text,             -- null = toutes marques
  fuel            text,             -- null = tous (ex. 'Electrique')
  price_max       numeric,          -- null = pas de plafond
  year_min        int,              -- null = pas de minimum
  active          boolean not null default true,
  last_notified_at timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

alter table public.vehicle_alerts enable row level security;

drop policy if exists alerts_owner_all on public.vehicle_alerts;
create policy alerts_owner_all on public.vehicle_alerts
  for all using (created_by = auth.uid())
  with check (created_by = auth.uid());

create index if not exists idx_vehicle_alerts_by on public.vehicle_alerts(created_by);

-- --- Rapprochement + notifications (appelé par l'import, service_role) -------
create or replace function public.notify_alert_matches()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  a record;
  n int;
  sent int := 0;
begin
  for a in select * from public.vehicle_alerts where active loop
    select count(*) into n
    from public.vehicle_listings l
    where l.is_active and l.availability = 'available'
      and l.imported_at > a.last_notified_at
      and (a.brand is null or l.brand = a.brand)
      and (a.fuel is null or l.fuel ilike a.fuel)
      and (a.price_max is null or l.price_fcfa <= a.price_max)
      and (a.year_min is null or l.year >= a.year_min);

    if n > 0 then
      insert into public.notifications (user_id, title, body, type)
      values (
        a.created_by,
        'Nouveaux véhicules pour votre alerte',
        n || ' véhicule(s) correspondent à « ' ||
          coalesce(nullif(a.label, ''), 'votre recherche') || ' ».',
        'alert'
      );
      sent := sent + 1;
    end if;

    update public.vehicle_alerts set last_notified_at = now() where id = a.id;
  end loop;
  return sent;
end;
$$;

revoke all on function public.notify_alert_matches() from public;
