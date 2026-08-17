-- =====================================================================
-- 0018 — Notifications en temps réel
--
-- Ajoute `notifications` à la publication realtime pour que la cloche 🔔
-- se mette à jour toute seule (nouvelle notif / passage en « lu »), sans que
-- l'utilisateur ait à rouvrir un écran. La RLS existante s'applique au flux :
-- chacun ne reçoit que SES notifications (client) ou celles du rôle admin.
-- =====================================================================

-- REPLICA IDENTITY FULL : le flux realtime dispose de l'ancienne + la nouvelle
-- ligne (nécessaire pour filtrer proprement les UPDATE, ex. is_read).
alter table public.notifications replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
