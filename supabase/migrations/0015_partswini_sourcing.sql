-- =====================================================================
-- Teranga Parts — Sourcing pieces via Partswini (Autowini)
--
-- Integration ASSISTEE : l'admin source la piece sur Partswini (catalogue +
-- WhatsApp fournisseur), puis saisit la proposition dans l'appli. On trace la
-- provenance sur la proposition fournisseur. Ces champs sont INTERNES : le
-- client n'a aucune policy sur suppliers_quotes (source masquee d'office).
-- =====================================================================

alter table suppliers_quotes
  add column if not exists source     text,   -- ex. 'partswini'
  add column if not exists source_url text;   -- lien du listing (interne)
