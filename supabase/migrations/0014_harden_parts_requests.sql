-- =====================================================================
-- Teranga Parts — Durcissement parts_requests (audit SEC-03)
--
-- La policy client etait ALL : un client pouvait modifier le statut de sa
-- demande de piece (falsification de flux) ou la supprimer. On la remplace
-- par des policies ciblees : SELECT + INSERT + DELETE de ses propres lignes,
-- sans UPDATE (le statut n'est fait avancer que par l'admin).
-- =====================================================================

drop policy if exists "requests: client proprietaire" on parts_requests;

create policy "requests: client select" on parts_requests
  for select using (client_id = auth.uid());

create policy "requests: client insert" on parts_requests
  for insert with check (client_id = auth.uid());

create policy "requests: client delete" on parts_requests
  for delete using (client_id = auth.uid());
