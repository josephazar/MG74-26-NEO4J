-- =====================================================================
-- MG74 - Scenario 1 : SochauxSense SAS
-- Fichier 2/3 : DONNEES D'EXEMPLE (19 entites)
-- Les identifiants refletent exactement ceux du graphe Neo4j (build.cypher).
-- =====================================================================

-- Site / Buildings / Zones --------------------------------------------
INSERT INTO Site (site_id, name, city) VALUES
  (1, 'Usine Sochaux-Nord', 'Sochaux');

INSERT INTO Building (building_id, site_id, name) VALUES
  (1, 1, 'Atelier Emboutissage'),
  (2, 1, 'Atelier Montage');

INSERT INTO Zone (zone_id, building_id, name) VALUES
  (1, 1, 'Ligne Presse A'),
  (2, 1, 'Ligne Presse B'),
  (3, 2, 'Ligne Montage 1');

-- Machines -------------------------------------------------------------
INSERT INTO Machine (machine_id, zone_id, model, criticality) VALUES
  (1, 1, 'Presse Schuler-2000', 'critique'),
  (2, 1, 'Convoyeur-CX',        'normale'),
  (3, 2, 'Presse Schuler-1500', 'critique'),
  (4, 3, 'Robot-KUKA-KR16',     'critique');

-- Maillage des passerelles (parent_gateway_id pointe vers la PARENTE) --
--   GW-Edge-Core (1)
--     |- GW-A (2)        -> GW-A1 (3)
--     |- GW-B (4)        -> GW-B1 (5)
INSERT INTO Gateway (gateway_id, zone_id, parent_gateway_id, name) VALUES
  (1, NULL, NULL, 'GW-Edge-Core'),
  (2, 1,    1,    'GW-A'),
  (3, 1,    2,    'GW-A1'),
  (4, 2,    1,    'GW-B'),
  (5, 2,    4,    'GW-B1');

-- Capteurs (machine + passerelle) -------------------------------------
INSERT INTO Sensor (sensor_id, machine_id, gateway_id, type, unit) VALUES
  (1, 1, 3, 'vibration',   'mm/s'),
  (2, 1, 3, 'temperature', 'C'),
  (3, 2, 2, 'current',     'A'),
  (4, 3, 5, 'vibration',   'mm/s'),
  (5, 4, 4, 'vibration',   'mm/s');

-- Techniciens + responsabilites (M:N) ---------------------------------
INSERT INTO Technician (tech_id, name, team) VALUES
  (1, 'Karim B.',  'Maintenance Presses'),
  (2, 'Sophie L.', 'Maintenance Robotique');

INSERT INTO Responsibility (tech_id, zone_id) VALUES
  (1, 1),
  (1, 2),
  (2, 3);

-- Alertes --------------------------------------------------------------
INSERT INTO Alert (alert_id, sensor_id, severity, ts) VALUES
  (1, 1, 'critique', '2026-06-05 08:12'),
  (2, 4, 'haute',    '2026-06-05 09:40'),
  (3, 1, 'haute',    '2026-06-06 07:55');
