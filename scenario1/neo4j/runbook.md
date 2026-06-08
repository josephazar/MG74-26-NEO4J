# Runbook Neo4j — Scénario 1 : SochauxSense SAS

**Usage en direct.** Garder ce fichier ouvert à côté du diaporama Beamer. Pour chaque question : afficher la diapo → basculer ici → copier le bloc Cypher → l'exécuter dans **Neo4j Browser** (`http://localhost:7475/browser/`) → comparer le résultat avec la diapo SQL.

> Ce runbook suit le déroulé du diaporama en **4 parties** : (1) SQL dans DBeaver, (2) intro graphe + **échauffement Cypher générique** ci-dessous, (3) construction de SochauxSense + questions Q1→Q5, (4) verdict. Chaque commande Cypher correspond à **une diapo dédiée** dans `slides.pdf`. Niveau volontairement **basique** : `CREATE`, `MATCH`, `WHERE`, motifs de relations, et **un seul** chemin à longueur variable (`*`).

---

## Étape 0 — Préparation

Ouvrir Neo4j Desktop, démarrer la base, ouvrir le Browser : `http://localhost:7475/browser/`. Au cas où, partir d'une base vide :

```cypher
MATCH (n) DETACH DELETE n;
```

---

## Échauffement — Cypher générique  *(pendant la Partie 2, diapo « clauses de base »)*

But : faire toucher du doigt `CREATE` / `MATCH` / `RETURN` / `WHERE` sur un mini-exemple Alice/Bob **avant** d'attaquer SochauxSense.

**1. Créer deux noeuds et une relation :**
```cypher
CREATE (a:Person {name:'Alice'})-[:KNOWS]->(b:Person {name:'Bob'});
```

**2. Lire (MATCH … RETURN) :**
```cypher
MATCH (p:Person) RETURN p.name;
```

**3. Filtrer (WHERE) + suivre une relation :**
```cypher
MATCH (p:Person)-[:KNOWS]->(f:Person)
WHERE f.name = 'Bob'
RETURN p.name AS qui_connait_bob;
```

**4. Teaser longueur variable** (créer une petite chaîne puis la parcourir) :
```cypher
CREATE (:Person {name:'C1'})-[:KNOWS]->(:Person {name:'C2'})-[:KNOWS]->(:Person {name:'C3'});
```
```cypher
MATCH (a:Person {name:'C1'})-[:KNOWS*1..5]->(p)
RETURN DISTINCT p.name;   // * = 1 a 5 sauts ; on borne pour eviter les boucles
```

**5. On nettoie avant de construire l'usine :**
```cypher
MATCH (n) DETACH DELETE n;
```

> Point à marteler : `CREATE` crée **toujours** (relancer la commande 1 deux fois fabrique deux Alice). Pour « créer si absent », c'est `MERGE` — on le verra au Scénario 2.

---

## Construction du graphe SochauxSense  *(début de la Partie 3)*

1. **Construire** : ouvrir `build.cypher`, copier **BLOC 1** jusqu'au `;`, l'exécuter, puis faire pareil avec **BLOC 2 → BLOC 6**. Chaque bloc est autonome : il retrouve les nœuds précédents avec `MATCH`. Comme ce scénario illustre `CREATE`, exécuter chaque bloc une seule fois après reset.
2. **Vérifier** : on doit obtenir **25 nœuds** (1 Site, 2 Bâtiments, 3 Zones, 4 Machines, 5 Passerelles, 5 Capteurs, 2 Techniciens, 3 Alertes) :

```cypher
MATCH (n) RETURN count(n) AS noeuds;
```

3. **Vue d'ensemble** — l'usine entière dessinée :

```cypher
MATCH (n) RETURN n;
```

> 💡 *Astuce d'affichage* : dans le Browser, cliquer sur une puce de label (ex. `Gateway`) dans la légende en haut, puis régler une couleur et **Caption = `name`**. En 5 secondes le graphe devient lisible. À refaire pour `Machine`, `Sensor`, `Zone`.

---

## Q1 — Lister les capteurs de vibration  *(FR1)*

**Idée.** La requête la plus simple. Ici SQL et Cypher sont à **égalité** : une ligne chacun, aucune jointure. *À dire à voix haute : pour une simple recherche tabulaire, SQL est parfait — on ne survend pas le graphe.*

```cypher
MATCH (s:Sensor {type:'vibration'})
RETURN s.id, s.type, s.unit;
```

**Résultat attendu :** capteurs **1, 4, 5**.
**Comparer avec la diapo SQL :** `SELECT ... WHERE type='vibration'` — identique. Match nul.

---

## Q2 — Machines du bâtiment « Atelier Emboutissage »  *(FR2)*

**Idée.** On traverse Bâtiment → Zone → Machine. En SQL : **2 JOIN** + clauses `ON`. En Cypher : **un seul motif** qui se lit comme la question.

```cypher
MATCH (b:Building {name:'Atelier Emboutissage'})-[:HAS_ZONE]->(z:Zone)-[:HAS_MACHINE]->(m:Machine)
RETURN m.id, m.model, z.name AS zone, b.name AS batiment;
```

**Résultat attendu :** machines **1, 2, 3** (Presse Schuler-2000, Convoyeur-CX, Presse Schuler-1500).
**Comparer avec la diapo SQL :** 2 JOIN vs 1 motif. SQL reste lisible, mais la comptabilité des jointures commence.

---

## Q3 — Technicien responsable des alertes critiques  *(FR4)*

**Idée.** Chemin Alerte → Capteur → Machine → Zone → Technicien. En SQL : **5 JOIN sur 6 tables**, dont la table de jonction `Responsibility` (pure plomberie). En Cypher : **un chemin**, et la table de jonction **disparaît** — elle devient simplement la relation `RESPONSIBLE_FOR`.

```cypher
MATCH (a:Alert {severity:'critique'})-[:RAISED_BY]->(:Sensor)<-[:HAS_SENSOR]-(m:Machine)<-[:HAS_MACHINE]-(z:Zone)<-[:RESPONSIBLE_FOR]-(t:Technician)
RETURN a.id, a.severity, m.model AS machine, t.name AS technicien;
```

**Résultat attendu :** alerte **1** (critique) → **Presse Schuler-2000** → **Karim B.**
**Comparer avec la diapo SQL :** c'est ici que le public *ressent* le premier « impôt SQL ».

---

## Q4 — ⚡ LA REQUÊTE CLÉ : effet domino  *(FR5)*

**Idée.** La passerelle **GW-Edge-Core** tombe. Quels capteurs/machines perdent la connectivité, **à n'importe quelle profondeur** du maillage ? Profondeur **variable** ⇒ en SQL il faut une **CTE récursive** (`WITH RECURSIVE`, ancre + membre récursif + `UNION ALL`), une vraie construction de langage. En Cypher, la profondeur variable s'écrit avec **un seul caractère : `*`**.

```cypher
MATCH (root:Gateway {name:'GW-Edge-Core'})<-[:UPLINKS_TO*0..]-(:Gateway)<-[:CONNECTS_TO]-(s:Sensor)<-[:HAS_SENSOR]-(m:Machine)
RETURN s.id, s.type, m.model;
```

**Résultat attendu :** les **5 capteurs** s'éteignent (toutes les passerelles sont en aval de l'edge-core).

> **À expliquer sur le `*0..`** : `*0..` = « zéro saut ou plus » → inclut aussi les capteurs branchés *directement* sur la passerelle en panne. Avec `*1..` on les exclurait. Aparté (ne pas s'attarder) : `[*1..3]` borne la profondeur à 3 sauts.

> ⚠️ **Sens des flèches** (à vérifier avant le cours) : comme `(:Gateway)-[:UPLINKS_TO]->(parente)`, « en aval » se lit avec des flèches **entrantes** vers `root` : `(root)<-[:UPLINKS_TO*0..]-(...)`. Si la démo renvoie vide, c'est presque toujours un sens de flèche inversé.

**Comparer avec la diapo SQL :** la CTE récursive (≈ 10 lignes) vs un motif d'une ligne. **C'est la diapo « money ».**

---

## Q4 bis — Le sens inverse : on retourne la flèche  *(FR6)*

**Idée.** Pour un capteur donné, **remonter toute la chaîne** jusqu'à l'edge-core (diagnostic bout en bout). En SQL : il faut écrire une **deuxième** CTE récursive, de forme différente. En Cypher : **on inverse simplement la flèche**.

```cypher
MATCH chemin = (:Sensor {id:4})-[:CONNECTS_TO]->(:Gateway)-[:UPLINKS_TO*0..]->(:Gateway {name:'GW-Edge-Core'})
RETURN chemin;
```

**Résultat attendu :** le chemin **capteur 4 (S4 vibration) → GW-B1 → GW-B → GW-Edge-Core** (dessiné dans le Browser).
**Le point à marteler :** même question dans l'autre sens = en SQL une *nouvelle* requête récursive ; en Cypher, on a juste retourné `->`.

---

## Q5 — 🎨 La « forme » de la réponse : topologie complète  *(FR8)*

**Idée.** Topologie complète du capteur 1 (site → bâtiment → zone → machine → capteur → passerelle). En SQL : **une ligne plate** que l'humain doit recomposer mentalement. En Cypher : on retourne un **chemin** → Neo4j **dessine le graphe**.

```cypher
MATCH chemin = (si:Site)-[:HAS_BUILDING]->(:Building)-[:HAS_ZONE]->(:Zone)-[:HAS_MACHINE]->(:Machine)-[:HAS_SENSOR]->(s:Sensor {id:1})
MATCH (s)-[:CONNECTS_TO]->(g:Gateway)
RETURN chemin, g;
```

**Résultat attendu :** la chaîne **Usine Sochaux-Nord → Atelier Emboutissage → Ligne Presse A → Presse Schuler-2000 → capteur 1 (S1 vibration) → GW-A1**, affichée comme un **graphe connecté**.
**Comparer avec la diapo SQL :** la ligne plate vs le dessin. *« Ça, c'est la forme de la réponse. »* → effet « waouh » visuel.

---

## Réinitialisation (entre deux répétitions)

```cypher
MATCH (n) DETACH DELETE n;
```

Puis recoller les blocs de `build.cypher` dans l'ordre (**BLOC 1 → BLOC 6**) et revérifier `MATCH (n) RETURN count(n);` = **25**.

---

### Aide-mémoire : modèle du graphe

| Nœud | Relation | Vers | Cardinalité |
|---|---|---|---|
| Site | `:HAS_BUILDING` | Building | 1:N |
| Building | `:HAS_ZONE` | Zone | 1:N |
| Zone | `:HAS_MACHINE` | Machine | 1:N |
| Machine | `:HAS_SENSOR` | Sensor | 1:N |
| Sensor | `:CONNECTS_TO` | Gateway | N:1 |
| Gateway | `:UPLINKS_TO` | Gateway (parente) | N:1 *(récursif)* |
| Technician | `:RESPONSIBLE_FOR` | Zone | M:N |
| Alert | `:RAISED_BY` | Sensor | N:1 |
