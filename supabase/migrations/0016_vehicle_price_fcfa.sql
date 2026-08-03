-- 0016 — Prix affiche en FCFA sur le catalogue vehicules.
--
-- Cette colonne existait en PRODUCTION mais n'avait jamais ete capturee dans une
-- migration (derive de schema). On la formalise ici pour que le depot reste la
-- source de verite. Renseignee par la fonction d'import `encar-import`
-- (prix converti depuis le won + marge, arrondi commercial). Lue par l'app.

alter table public.vehicle_listings
  add column if not exists price_fcfa numeric;
