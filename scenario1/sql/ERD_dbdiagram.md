# ERD du schéma SQL — SochauxSense (dbdiagram.io)

**Comment l'utiliser.** Aller sur <https://dbdiagram.io> → *Create new diagram* → coller le bloc **DBML** ci-dessous dans l'éditeur de gauche. Le diagramme se dessine automatiquement (on peut déplacer les tables, et exporter en PNG/PDF/SQL via *Export*).

> Ce DBML reproduit fidèlement `01_schema.sql` : 8 tables, les clés primaires (PK), les clés étrangères (FK), l'auto-référence de `Gateway` et la table de jonction `Responsibility`.

---

## Le code à coller (DBML)

```dbml
// =====================================================================
// SochauxSense SAS - schema relationnel (le "consultant naif")
// MG74 - Scenario 1   |   a coller dans https://dbdiagram.io
// =====================================================================

Project SochauxSense {
  database_type: 'SQLite'
  Note: 'Plateforme de maintenance predictive - modele relationnel. MG74 scenario 1.'
}

// ---- Hierarchie physique : Site > Building > Zone > Machine > Sensor ----
Table Site {
  site_id integer [pk]
  name text [not null]
  city text
  Note: 'Site industriel (usine).'
}

Table Building {
  building_id integer [pk]
  site_id integer [not null, ref: > Site.site_id]
  name text [not null]
  Note: 'Batiment, appartient a un site.'
}

Table Zone {
  zone_id integer [pk]
  building_id integer [not null, ref: > Building.building_id]
  name text [not null]
  Note: 'Zone / ligne de production dans un batiment.'
}

Table Machine {
  machine_id integer [pk]
  zone_id integer [not null, ref: > Zone.zone_id]
  model text
  criticality text [note: 'valeurs: critique, normale']
  Note: 'Equipement situe dans une zone.'
}

// ---- Reseau : maillage de passerelles (AUTO-REFERENCE) ----
Table Gateway {
  gateway_id integer [pk]
  zone_id integer [null, ref: > Zone.zone_id]
  parent_gateway_id integer [null, ref: > Gateway.gateway_id, note: 'passerelle parente (maillage recursif)']
  name text [not null]
  Note: 'Passerelle reseau. parent_gateway_id pointe vers la passerelle PARENTE, jusqu au coeur de reseau (edge-core). Une table qui se pointe elle-meme.'
}

Table Sensor {
  sensor_id integer [pk]
  machine_id integer [not null, ref: > Machine.machine_id]
  gateway_id integer [not null, ref: > Gateway.gateway_id]
  "type" text [note: 'valeurs: vibration, temperature, current']
  unit text
  Note: 'Capteur : appartient a une machine ET communique via une passerelle.'
}

// ---- Organisation humaine : M:N via table de jonction ----
Table Technician {
  tech_id integer [pk]
  name text [not null]
  team text
  Note: 'Technicien de maintenance.'
}

Table Responsibility {
  tech_id integer [ref: > Technician.tech_id]
  zone_id integer [ref: > Zone.zone_id]
  indexes {
    (tech_id, zone_id) [pk]
  }
  Note: 'TABLE DE JONCTION (M:N) : un technicien couvre plusieurs zones ; une zone peut avoir plusieurs techniciens.'
}

// ---- Evenements ----
Table Alert {
  alert_id integer [pk]
  sensor_id integer [not null, ref: > Sensor.sensor_id]
  severity text [note: 'valeurs: critique, haute']
  ts text [note: 'horodatage']
  Note: 'Alerte emise par un capteur.'
}

// ---- Regroupements visuels (couleurs dans dbdiagram) ----
TableGroup "Hierarchie physique" {
  Site
  Building
  Zone
  Machine
  Sensor
}
TableGroup "Reseau" {
  Gateway
}
TableGroup "Organisation et evenements" {
  Technician
  Responsibility
  Alert
}
```

---

## Comment l'expliquer aux étudiants

### 1. Trois blocs (les `TableGroup`, colorés dans dbdiagram)
- **Hiérarchie physique** : `Site → Building → Zone → Machine → Sensor`. Une chaîne de relations **1:N** (un site a plusieurs bâtiments, un bâtiment plusieurs zones, etc.). C'est l'arborescence « où se trouve quoi ».
- **Réseau** : `Gateway`. Le capteur *communique via* une passerelle, et les passerelles forment un maillage.
- **Organisation & événements** : `Technician`, `Responsibility`, `Alert`.

### 2. Lire les cardinalités (les « pattes d'oie »)
Chaque FK = une flèche **plusieurs → un**. Ex. : plusieurs `Building` pour un `Site`. À faire remarquer : tout est en **1:N**… *sauf* la responsabilité technicien/zone, qui est **M:N**.

### 3. Les DEUX pièges à montrer (ce sont eux qui justifient le passage au graphe)
1. **Auto-référence `Gateway.parent_gateway_id`** — la table `Gateway` se pointe **elle-même** (boucle sur le diagramme). C'est le maillage récursif : une passerelle relaie vers sa parente jusqu'à l'edge-core. ➜ *C'est précisément ce qui imposera la `WITH RECURSIVE` en **Q4**.*
2. **Table de jonction `Responsibility`** — pour modéliser un M:N en relationnel, il faut une **table intermédiaire** (sans données propres, juste deux FK). ➜ *Ce sont les jointures « en plus » de **Q3** ; en graphe, cette table disparaît et devient une relation `RESPONSIBLE_FOR`.*

### 4. Relier l'ERD aux 5 questions (Q1→Q5)
| Question | Tables / liens parcourus dans l'ERD |
|---|---|
| **Q1** capteurs de vibration | `Sensor` seul |
| **Q2** machines d'un bâtiment | `Building → Zone → Machine` (2 FK) |
| **Q3** technicien d'une alerte critique | `Alert → Sensor → Machine → Zone → Responsibility → Technician` (5 FK) |
| **Q4** effet domino | `Gateway` **sur elle-même** (auto-référence, profondeur variable) |
| **Q5** topologie d'un capteur | `Site → … → Sensor → Gateway` (toute la chaîne) |

> Message à faire passer : **le schéma est correct et complet** — rien à lui reprocher. La douleur n'apparaît qu'au moment des *requêtes* (Q3 et surtout Q4). C'est la transition idéale vers le bloc graphe.

---

## Variante (optionnelle) : avec des `enum`

Pour un rendu plus « propre » dans dbdiagram, on peut remplacer les colonnes `text` contraintes par des énumérations. À ajouter en haut, puis utiliser `criticality criticality_level`, `"type" sensor_type`, `severity alert_severity` :

```dbml
Enum criticality_level { critique  normale }
Enum sensor_type       { vibration  temperature  current }
Enum alert_severity    { critique  haute }
```

> Note : dans SQLite ces colonnes restent stockées en `TEXT` (pas de vrai type `ENUM`) — l'`enum` est ici purement pour la lisibilité du diagramme.
