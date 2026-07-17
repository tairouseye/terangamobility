-- =====================================================================
-- Teranga Parts — Catalogue vehicules consultable SANS COMPTE
--
-- Pourquoi : obliger un prospect a creer un compte avant meme de regarder
-- les vehicules fait chuter la conversion. Usage marketplace standard :
--   - catalogue visible par tous (visiteurs anonymes inclus)
--   - compte requis uniquement pour « Demander le prix »
--
-- Sans risque : vehicle_listings ne contient NI prix NI donnee personnelle,
-- uniquement des caracteristiques techniques et des photos publiques.
-- Toutes les autres tables restent protegees a l'identique.
-- =====================================================================

drop policy if exists "listings: lecture auth" on vehicle_listings;

create policy "listings: lecture publique"
  on vehicle_listings for select
  using (true);

-- L'ecriture reste strictement reservee a l'admin (policy inchangee,
-- rappelee ici pour memoire) :
--   create policy "listings: admin ecriture"
--     on vehicle_listings for all using (is_admin()) with check (is_admin());
