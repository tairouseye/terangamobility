-- =====================================================================
-- 0019 — prune_catalogue : garder un catalogue curé et plafonné
--
-- L'import (local) reconstruit à chaque passage l'ensemble à garder : les
-- annonces les plus récentes des marques déjà listées, priorité aux
-- électriques, plafonné à 400. Cette fonction DÉSACTIVE (is_active=false) tous
-- les autres véhicules DISPONIBLES qui ne sont pas dans la liste à garder.
--
-- Sûreté : ne touche JAMAIS les véhicules réservés/vendus (availability<>
-- 'available') — donc aucune commande client n'est impactée.
-- Réservé au service_role (l'import) : révoqué pour les autres rôles.
-- =====================================================================

create or replace function public.prune_catalogue(keep_refs text[])
returns int
language sql
security definer
set search_path = public
as $$
  with upd as (
    update public.vehicle_listings
    set is_active = false
    where availability = 'available'
      and is_active = true
      and not (reference = any(keep_refs))
    returning 1
  )
  select count(*)::int from upd;
$$;

revoke all on function public.prune_catalogue(text[]) from public;
-- (service_role contourne de toute façon ; on ne l'accorde à personne d'autre.)
