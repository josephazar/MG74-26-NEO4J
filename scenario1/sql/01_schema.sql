-- =====================================================================
-- MG74 - Scenario 1 : SochauxSense SAS (smart-factory IoT)
-- Le consultant "naif" : modelisation relationnelle (SQLite)
-- Fichier 1/3 : SCHEMA
--
-- A executer dans l'ordre : 01_schema.sql -> 02_seed.sql -> 03_queries.sql
--
-- Dans DBeaver (recommande pour la demo) :
--   1. Nouvelle connexion -> SQLite -> creer un fichier mg74.db
--   2. Ouvrir un editeur SQL, coller ce fichier, tout executer (Alt+X)
--   3. Idem pour 02_seed.sql, puis lancer les requetes de 03_queries.sql
--      une par une (curseur sur la requete, Ctrl+Entree).
--
-- En ligne de commande (alternative) :
--   sqlite3 mg74.db < 01_schema.sql
--   sqlite3 mg74.db < 02_seed.sql
--   sqlite3 -header -column mg74.db < 03_queries.sql
-- =====================================================================

PRAGMA foreign_keys = ON;

-- Hierarchie physique : Site -> Building -> Zone -> Machine -> Sensor
CREATE TABLE Site (
  site_id   INTEGER PRIMARY KEY,
  name      TEXT NOT NULL,
  city      TEXT
);

CREATE TABLE Building (
  building_id INTEGER PRIMARY KEY,
  site_id     INTEGER NOT NULL REFERENCES Site(site_id),
  name        TEXT NOT NULL
);

CREATE TABLE Zone (
  zone_id     INTEGER PRIMARY KEY,
  building_id INTEGER NOT NULL REFERENCES Building(building_id),
  name        TEXT NOT NULL
);

CREATE TABLE Machine (
  machine_id  INTEGER PRIMARY KEY,
  zone_id     INTEGER NOT NULL REFERENCES Zone(zone_id),
  model       TEXT,
  criticality TEXT            -- 'critique' | 'normale'
);

-- Maillage reseau : une passerelle relaie via une passerelle PARENTE
-- (cle etrangere AUTO-REFERENTE) jusqu'a la passerelle edge-core.
CREATE TABLE Gateway (
  gateway_id        INTEGER PRIMARY KEY,
  zone_id           INTEGER REFERENCES Zone(zone_id),
  parent_gateway_id INTEGER REFERENCES Gateway(gateway_id),  -- <- auto-reference (mesh)
  name              TEXT NOT NULL
);

-- Un capteur appartient a une machine ET communique via une passerelle.
CREATE TABLE Sensor (
  sensor_id  INTEGER PRIMARY KEY,
  machine_id INTEGER NOT NULL REFERENCES Machine(machine_id),
  gateway_id INTEGER NOT NULL REFERENCES Gateway(gateway_id),
  type       TEXT,            -- 'vibration' | 'temperature' | 'current'
  unit       TEXT
);

CREATE TABLE Technician (
  tech_id INTEGER PRIMARY KEY,
  name    TEXT NOT NULL,
  team    TEXT
);

-- Responsabilite M:N : un technicien couvre plusieurs zones,
-- une zone peut avoir plusieurs techniciens -> table de JONCTION.
CREATE TABLE Responsibility (
  tech_id INTEGER NOT NULL REFERENCES Technician(tech_id),
  zone_id INTEGER NOT NULL REFERENCES Zone(zone_id),
  PRIMARY KEY (tech_id, zone_id)
);

CREATE TABLE Alert (
  alert_id  INTEGER PRIMARY KEY,
  sensor_id INTEGER NOT NULL REFERENCES Sensor(sensor_id),
  severity  TEXT,            -- 'critique' | 'haute' | ...
  ts        TEXT
);
