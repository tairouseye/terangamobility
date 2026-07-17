-- =====================================================================
-- A COLLER EN UNE FOIS dans le SQL Editor de Supabase (projet TerangaParts)
-- https://supabase.com/dashboard/project/dfjikxgklnvqgjlexurv/sql/new
--
-- Contenu :
--   1) Migration 0007 — rendre le catalogue vehicules PUBLIC (sans compte)
--   2) 8 vehicules d'exemple (source = 'seed_test', supprimables plus tard)
--
-- Relancable sans risque.
-- =====================================================================


-- #####################################################################
-- ### 1) CATALOGUE PUBLIC (migration 0007)  — idempotent
-- #####################################################################
drop policy if exists "listings: lecture auth" on vehicle_listings;
drop policy if exists "listings: lecture publique" on vehicle_listings;

create policy "listings: lecture publique"
  on vehicle_listings for select
  using (true);


-- #####################################################################
-- ### 2) VEHICULES D'EXEMPLE (donnees de test, variees pour les filtres)
-- #####################################################################
insert into vehicle_listings (
  reference, source, brand, model, year, version, engine, displacement,
  mileage_km, transmission, fuel, color, doors, steering, location,
  condition, options, description, photos, is_active
) values

('EC-SF19-001', 'seed_test', 'Hyundai', 'Santa Fe', 2019,
 '2.2 CRDi 4WD Premium', '2.2 CRDi Diesel', '2199 cc',
 78000, 'Automatique', 'Diesel', 'Blanc', 5, 'left', 'Incheon, Coree du Sud',
 'Occasion - excellent etat',
 ARRAY['Climatisation','GPS','Camera de recul','Sieges cuir','Toit ouvrant','Regulateur de vitesse'],
 'Hyundai Santa Fe 2019 en tres bon etat, entretien a jour, ideal familial. 7 places, transmission integrale 4WD.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Santa%20Fe%202019%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Santa%20Fe%202019%20-%202',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Santa%20Fe%202019%20-%203'],
 true),

('EC-SOR20-014', 'seed_test', 'Kia', 'Sorento', 2020,
 '2.2 CRDi Signature', '2.2 CRDi Diesel', '2151 cc',
 52000, 'Automatique', 'Diesel', 'Noir', 5, 'left', 'Busan, Coree du Sud',
 'Occasion - tres bon etat',
 ARRAY['Climatisation automatique','GPS','Camera 360','Sieges chauffants','Hayon electrique'],
 'Kia Sorento 2020 Signature, faible kilometrage, full options.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Sorento%202020%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Sorento%202020%20-%202',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Sorento%202020%20-%203'],
 true),

('EC-TUC18-102', 'seed_test', 'Hyundai', 'Tucson', 2018,
 '2.0 GDi Style', '2.0 GDi Essence', '1999 cc',
 96000, 'Automatique', 'Essence', 'Gris', 5, 'left', 'Seoul, Coree du Sud',
 'Occasion - bon etat',
 ARRAY['Climatisation','Bluetooth','Camera de recul'],
 'Hyundai Tucson 2018 essence, fiable et economique.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Tucson%202018%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Tucson%202018%20-%202'],
 true),

('EC-MOR21-045', 'seed_test', 'Kia', 'Morning', 2021,
 '1.0 Comfort', '1.0 Essence', '998 cc',
 31000, 'Automatique', 'Essence', 'Rouge', 5, 'left', 'Incheon, Coree du Sud',
 'Occasion - comme neuf',
 ARRAY['Climatisation','Bluetooth'],
 'Kia Morning 2021 citadine, tres faible kilometrage, parfaite pour la ville.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Morning%202021%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Morning%202021%20-%202'],
 true),

('EC-G80-19-007', 'seed_test', 'Genesis', 'G80', 2019,
 '3.3 T-GDi AWD', '3.3 T-GDi Essence', '3342 cc',
 64000, 'Automatique', 'Essence', 'Bleu nuit', 4, 'left', 'Seoul, Coree du Sud',
 'Occasion - excellent etat',
 ARRAY['Cuir Nappa','Toit ouvrant panoramique','Sono premium','Sieges ventiles','Aide au stationnement'],
 'Genesis G80 berline premium, confort et performances. Vehicule de direction.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Genesis%20G80%202019%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Genesis%20G80%202019%20-%202',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Genesis%20G80%202019%20-%203'],
 true),

('EC-REX17-233', 'seed_test', 'SsangYong', 'Rexton', 2017,
 '2.2 e-XDi 4WD', '2.2 e-XDi Diesel', '2157 cc',
 121000, 'Manuelle', 'Diesel', 'Argent', 5, 'left', 'Daegu, Coree du Sud',
 'Occasion - etat correct',
 ARRAY['Climatisation','4x4','Attelage','Barres de toit'],
 'SsangYong Rexton 2017 boite manuelle, robuste, adapte aux routes difficiles.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=SsangYong%20Rexton%202017%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=SsangYong%20Rexton%202017%20-%202'],
 true),

('EC-NIRO20-088', 'seed_test', 'Kia', 'Niro', 2020,
 '1.6 GDi Hybrid', '1.6 GDi Hybride', '1580 cc',
 45000, 'Automatique', 'Hybride', 'Blanc', 5, 'left', 'Seoul, Coree du Sud',
 'Occasion - tres bon etat',
 ARRAY['Climatisation automatique','GPS','Camera de recul','Regulateur adaptatif'],
 'Kia Niro hybride 2020, tres economique en carburant.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Niro%20Hybride%202020%20-%201',
       'https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Kia%20Niro%20Hybride%202020%20-%202'],
 true),

('EC-ACC16-311', 'seed_test', 'Hyundai', 'Accent', 2016,
 '1.4 MPi', '1.4 MPi Essence', '1368 cc',
 112000, 'Manuelle', 'Essence', 'Noir', 4, 'left', 'Busan, Coree du Sud',
 'Occasion - etat correct',
 ARRAY['Climatisation','Vitres electriques'],
 'Hyundai Accent 2016, berline economique, entretien simple et pieces disponibles.',
 ARRAY['https://placehold.co/800x450/1C1C1E/FFFFFF/png?text=Hyundai%20Accent%202016%20-%201'],
 true)

on conflict (reference) do nothing;


-- #####################################################################
-- ### VERIFICATION (doit renvoyer 8 lignes)
-- #####################################################################
select reference, brand, model, year, fuel, transmission, color, mileage_km
from vehicle_listings
where source = 'seed_test'
order by brand, model;
