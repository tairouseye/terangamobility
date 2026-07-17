-- =====================================================================
-- Teranga Parts — Buckets Storage + policies
-- Cree les 2 buckets PRIVES attendus par l'application :
--   documents : cartes grises (1 dossier par utilisateur)
--   parts     : photos de pieces (demandes client / propositions partenaire)
--
-- Convention de chemin : <user_id>/<timestamp>.<ext>
-- => le 1er segment du chemin doit etre l'uid de l'appelant.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('documents', 'documents', false),
       ('parts', 'parts', false)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- documents (cartes grises) : chaque client gere son propre dossier ;
-- l'admin voit tout.
-- ---------------------------------------------------------------------
drop policy if exists "documents: proprietaire lecture" on storage.objects;
create policy "documents: proprietaire lecture"
  on storage.objects for select
  using (
    bucket_id = 'documents'
    and (owner = auth.uid() or (storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "documents: proprietaire ecriture" on storage.objects;
create policy "documents: proprietaire ecriture"
  on storage.objects for insert
  with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "documents: proprietaire maj" on storage.objects;
create policy "documents: proprietaire maj"
  on storage.objects for update
  using (
    bucket_id = 'documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "documents: proprietaire suppression" on storage.objects;
create policy "documents: proprietaire suppression"
  on storage.objects for delete
  using (
    bucket_id = 'documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

-- ---------------------------------------------------------------------
-- parts (photos de pieces) : l'auteur gere son dossier ; lecture ouverte
-- aux utilisateurs authentifies (le partenaire Coree et l'admin doivent
-- voir la photo envoyee par le client, et inversement).
-- ---------------------------------------------------------------------
drop policy if exists "parts: lecture authentifiee" on storage.objects;
create policy "parts: lecture authentifiee"
  on storage.objects for select
  using (bucket_id = 'parts' and auth.role() = 'authenticated');

drop policy if exists "parts: auteur ecriture" on storage.objects;
create policy "parts: auteur ecriture"
  on storage.objects for insert
  with check (
    bucket_id = 'parts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "parts: auteur maj" on storage.objects;
create policy "parts: auteur maj"
  on storage.objects for update
  using (
    bucket_id = 'parts'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );

drop policy if exists "parts: auteur suppression" on storage.objects;
create policy "parts: auteur suppression"
  on storage.objects for delete
  using (
    bucket_id = 'parts'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_admin())
  );
