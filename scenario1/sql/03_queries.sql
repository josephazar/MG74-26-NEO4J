-- =====================================================================
-- MG74 - Scenario 1 : SochauxSense SAS
-- Fichier 3/3 : LES 5 QUESTIONS METIER (cote SQL)
-- De la plus simple (Q1, egalite avec Cypher) a la plus douloureuse
-- (Q4, CTE recursive). Comparer chaque requete avec sa jumelle Cypher.
--
-- DBeaver : placer le curseur sur une requete et faire Ctrl+Entree
-- pour l'executer seule. (Pas de commandes ".headers/.mode" ici :
-- ce sont des commandes du CLI sqlite3, pas du SQL -> DBeaver planterait.)
-- =====================================================================


-- =====================================================================
-- Q1 (FR1) - Lister les capteurs de vibration.
-- SQL : 1 ligne. Cypher : 1 ligne. EGALITE -> SQL est parfait ici.
-- Attendu : capteurs 1, 4, 5.
-- =====================================================================
SELECT sensor_id, type, unit
FROM Sensor
WHERE type = 'vibration';


-- =====================================================================
-- Q2 (FR2) - Machines du batiment 'Atelier Emboutissage'.
-- 2 JOIN. SQL reste OK, mais la "comptabilite" des jointures commence.
-- Attendu : machines 1, 2, 3.
-- =====================================================================
SELECT m.machine_id, m.model, z.name AS zone, b.name AS building
FROM Machine m
JOIN Zone     z ON m.zone_id     = z.zone_id
JOIN Building b ON z.building_id = b.building_id
WHERE b.name = 'Atelier Emboutissage';


-- =====================================================================
-- Q3 (FR4) - Pour chaque alerte CRITIQUE, le technicien responsable.
-- Chemin : Alert -> Sensor -> Machine -> Zone -> (Responsibility) -> Technician
-- 5 JOIN sur 6 tables. La table de jonction Responsibility est de la
-- pure "plomberie" que le lecteur doit decoder.
-- Attendu : alerte 1 (critique) -> Presse Schuler-2000 -> Karim B.
-- =====================================================================
SELECT a.alert_id, a.severity, m.model AS machine, t.name AS technician
FROM Alert a
JOIN Sensor         s ON a.sensor_id  = s.sensor_id
JOIN Machine        m ON s.machine_id = m.machine_id
JOIN Zone           z ON m.zone_id    = z.zone_id
JOIN Responsibility r ON z.zone_id    = r.zone_id
JOIN Technician     t ON r.tech_id    = t.tech_id
WHERE a.severity = 'critique';


-- =====================================================================
-- Q4 (FR5) - *** LA REQUETE CLE ***
-- La passerelle GW-Edge-Core (id=1) tombe en panne. Quels capteurs et
-- machines perdent la connectivite, A N'IMPORTE QUELLE PROFONDEUR ?
-- => Profondeur VARIABLE -> il faut une CTE RECURSIVE (WITH RECURSIVE).
--    Ancre + membre recursif + UNION ALL : une construction de langage
--    a part entiere. En Cypher, ce sera un seul caractere : *.
-- Attendu : les 5 passerelles en aval -> les 5 capteurs s'eteignent.
-- =====================================================================
WITH RECURSIVE downstream(gateway_id, name) AS (
    SELECT gateway_id, name FROM Gateway WHERE gateway_id = 1   -- ancre : la passerelle en panne
  UNION ALL
    SELECT g.gateway_id, g.name                                  -- membre recursif :
    FROM Gateway g                                               --   toute passerelle dont la
    JOIN downstream d ON g.parent_gateway_id = d.gateway_id      --   parente est deja "en aval"
)
SELECT s.sensor_id, s.type, m.model AS machine
FROM Sensor s
JOIN downstream d ON s.gateway_id  = d.gateway_id
JOIN Machine   m ON s.machine_id = m.machine_id
ORDER BY s.sensor_id;


-- =====================================================================
-- Q4 bis (FR6) - Sens INVERSE : pour un capteur, remonter TOUTE la
-- chaine de connectivite jusqu'a l'edge-core (diagnostic bout en bout).
-- En Cypher : on inverse simplement la fleche. En SQL : c'est une
-- DEUXIEME CTE recursive, de forme differente.
-- Attendu (capteur 4) : GW-B1 -> GW-B -> GW-Edge-Core.
-- =====================================================================
WITH RECURSIVE uplink(gateway_id, name, parent_gateway_id, depth) AS (
    SELECT g.gateway_id, g.name, g.parent_gateway_id, 0
    FROM Gateway g
    JOIN Sensor s ON s.gateway_id = g.gateway_id
    WHERE s.sensor_id = 4                                        -- ancre : la passerelle du capteur
  UNION ALL
    SELECT p.gateway_id, p.name, p.parent_gateway_id, u.depth + 1
    FROM Gateway p
    JOIN uplink u ON u.parent_gateway_id = p.gateway_id          -- on remonte vers la parente
)
SELECT depth, gateway_id, name FROM uplink ORDER BY depth;


-- =====================================================================
-- Q5 (FR8) - Topologie complete du capteur 1 (site -> ... -> passerelle).
-- SQL renvoie UNE SEULE LIGNE PLATE que l'humain doit recomposer
-- mentalement en une chaine. Cypher renverra un CHEMIN -> Neo4j dessine
-- le graphe. C'est la "forme" de la reponse.
-- Attendu : Usine Sochaux-Nord | Atelier Emboutissage | Ligne Presse A
--           | Presse Schuler-2000 | vibration | GW-A1
-- =====================================================================
SELECT si.name AS site, b.name AS building, z.name AS zone,
       m.model AS machine, s.type AS sensor, g.name AS gateway
FROM Sensor s
JOIN Machine  m  ON s.machine_id = m.machine_id
JOIN Zone     z  ON m.zone_id    = z.zone_id
JOIN Building b  ON z.building_id = b.building_id
JOIN Site     si ON b.site_id    = si.site_id
JOIN Gateway  g  ON s.gateway_id = g.gateway_id
WHERE s.sensor_id = 1;
