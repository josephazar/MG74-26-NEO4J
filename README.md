# MG74 — Théorie des graphes & Neo4j

Supports de l'atelier **MG74** (théorie des graphes, Neo4j, modélisation de connaissances).
**Joseph Azar** — Maître de conférences, UMLP · chercheur, FEMTO-ST — CFAI Exincourt.

L'atelier est **scénarisé** : on joue le rôle d'un consultant face à de vrais besoins clients,
de la modélisation jusqu'aux requêtes.

> 📦 **Distribution.** En début de séance, le dépôt contient les scripts de construction
> (`scenario1/neo4j/build.cypher`, `scenario2/neo4j/build.cypher`), les **cahiers des charges** des
> scénarios 1 et 2, et le guide d'installation (`get_started/`). Le reste (diaporamas, *runbooks*,
> fichiers SQL, **énoncé du scénario 3**) est ajouté **en fin de séance**.

---

## 🚀 Pour démarrer

1. **Installer Neo4j Desktop** → voir le guide pas à pas : [`get_started/README.md`](get_started/README.md).
   On exécute les requêtes dans **Neo4j Browser / Query** (souvent `http://localhost:7474/browser` ;
   suivez l'URL indiquée par le *runbook*).
   > À installer **à la pause / chez vous / en autonomie** (Windows · Linux · macOS). Pendant la
   > séance, **suivez la démo** — pas besoin d'avoir Neo4j installé.
2. **Scénario 1 (partie SQL)** : un client SQL au choix — par ex. **DBeaver** + **SQLite**.

**Méthode commune (Neo4j) :** ouvrir `build.cypher`, exécuter les blocs **un par un** (jusqu'au `;`)
dans le Browser, vérifier le nombre de nœuds, puis suivre le `runbook.md` requête par requête.

---

## 📁 Contenu du dépôt

```
.
├── README.md                         # ce fichier
├── get_started/README.md             # installer Neo4j Desktop + premiers pas
├── cover.pdf                         # diapo d'introduction (intervenant + programme)
├── assets/                           # ressources graphiques du cours
│
├── scenario1/   — Pourquoi une base de données graphe ? (SQL vs Neo4j)
│   ├── cahier_des_charges.pdf        # le client SochauxSense (usine IoT)
│   ├── slides.pdf
│   ├── sql/                          # la solution relationnelle
│   │   ├── 01_schema.sql · 02_seed.sql · 03_queries.sql
│   │   └── ERD_dbdiagram.md          # schéma relationnel (à coller dans dbdiagram.io)
│   └── neo4j/
│       ├── build.cypher              # construire le graphe
│       └── runbook.md                # les requêtes Cypher, pas à pas
│
├── scenario2/   — Cypher en profondeur (e-commerce NOVANEST)
│   ├── cahier_des_charges.pdf
│   ├── slides.pdf
│   └── neo4j/
│       ├── build.cypher
│       └── runbook.md
│
└── scenario3/   — Exercice : à vous de jouer (médiathèque)
    └── cahier_des_charges.pdf        # l'énoncé (conception + 15 questions + CRUD)
```

## 🧭 Les trois scénarios

### Scénario 1 — Pourquoi une base de données graphe ?
Un intégrateur IoT (SochauxSense) doit modéliser un réseau de capteurs d'usine. On le fait **en SQL**
(SQLite), puis **en Neo4j**, et on compare les **mêmes** questions : où le relationnel suffit\dots et
où le graphe gagne nettement (parcours à profondeur variable, « forme » de la réponse).
**Notions :** nœud, label, relation, propriété ; `CREATE`, `MATCH`, `WHERE`, `RETURN` ; chemin de
longueur variable `*`.

### Scénario 2 — Cypher en profondeur (NOVANEST, e-commerce)
On **construit** un graphe e-commerce (`MERGE` + propriétés, y compris **sur les relations**) et on
l'**interroge** finement. **Notions :** CRUD (`MERGE`/`SET`/`DELETE`/`DETACH DELETE`), agrégations
(`count`, `sum`, `avg`, `collect`), `ORDER BY`/`LIMIT`, `DISTINCT`, `OPTIONAL MATCH` (pas à pas),
`WITH`, hiérarchie à longueur variable, **recommandation** (filtrage collaboratif), **chemins
pondérés** (`shortestPath()` + `reduce()`, pas à pas).

### Scénario 3 — À vous de jouer (médiathèque « LecturaPlus »)
Un **exercice complet** — votre entraînement à l'examen du 22/06. À partir du cahier des charges et des
données fournies, **vous** : (1) **concevez le modèle** (entités, relations, propriétés — *c'est à
vous*) ; (2) **construisez le graphe** en Cypher ; (3) réalisez les **opérations CRUD** ; (4) répondez
aux **15 questions** (du plus simple au plus exigeant).

*Atelier MG74 — Joseph Azar — UMLP · FEMTO-ST — joseph.azar@umlp.fr.*
