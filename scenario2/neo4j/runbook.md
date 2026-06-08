# Runbook Neo4j — Scénario 2 : NOVANEST (e-commerce / recommandation)

**Usage en direct.** Garder ce fichier à côté du diaporama. Browser : `http://localhost:7475/browser/`. Pour chaque question : afficher la diapo → basculer ici → copier le bloc Cypher → l'exécuter → commenter le résultat.

> Suite du Scénario 1. Ici **100 % graphe** (plus de SQL). On construit le graphe **par étapes** (noeuds → relations → relations avec propriétés) puis on monte en puissance : agrégations → `OPTIONAL MATCH` → hiérarchie → recommandation → **chemin pondéré**. Chaque commande Cypher correspond à **une diapo dédiée** dans `slides.pdf`, même ordre.

---

## Étape 0 — Préparation

Démarrer la base, ouvrir le Browser. Partir d'une base vide :

```cypher
MATCH (n) DETACH DELETE n;
```

---

## Échauffement — `CREATE` vs `MERGE`  *(diapo « MERGE idempotent »)*

Point clé du Scénario 2 : `MERGE` = « **trouve ou crée** » → relançable sans doublonner (contrairement à `CREATE`).

```cypher
MERGE (b:Brand {name:'Nordia'}) RETURN b;
```
Relancer **deux fois** la même commande puis vérifier qu'il n'y a **qu'un** noeud Nordia :
```cypher
MATCH (b:Brand {name:'Nordia'}) RETURN count(b);   // -> 1, meme apres plusieurs MERGE
```
Convention : on `MERGE` sur la **clé naturelle** puis on `SET` le reste :
```cypher
MERGE (p:Product {id:1}) SET p.name='Smartphone Aura X', p.price=699 RETURN p;
```
Nettoyer avant la vraie construction :
```cypher
MATCH (n) DETACH DELETE n;
```

---

## Construction du graphe NOVANEST  *(Partie 2 — étapes A/B/C)*

Le fichier `build.cypher` est commenté en **3 étapes**, découpées en blocs exécutables un par un :
- **Étape A — Noeuds** (`A1 → A4`) : `MERGE` (clé) + `SET` (propriétés) — marques, catégories, produits, clients, et la couche logistique (entrepôts, hubs, villes).
- **Étape B — Relations structurelles** (`B1 → B5`, sans propriétés) : `SUBCATEGORY_OF`, `IN_CATEGORY`, `MADE_BY`, `LIVES_IN`, `STOCKED_AT`.
- **Étape C — Relations AVEC propriétés** (`C1 → C3`) : `PURCHASED{date,qty,unitPrice}`, `RATED{stars,date}`, et la logistique pondérée `SHIPS_TO{hours,cost}`.

**Construire** : ouvrir `build.cypher`, copier le premier bloc jusqu'au `;`, l'exécuter, puis avancer bloc par bloc jusqu'à **C3**. Les blocs utilisent `MERGE`, donc ils restent idempotents. Puis :

```cypher
MATCH (n) RETURN count(n) AS noeuds;   // -> 41
```
```cypher
MATCH (n) RETURN n;                     // vue d'ensemble : le graphe se dessine
```

> 💡 *Astuce Browser* : cliquer une puce de label (ex. `Product`) dans la légende, régler une couleur et **Caption = `name`**. Refaire pour `Customer`, `Category`, `Brand`.

---

## CRUD — modifier le graphe  *(Partie 3 — diapos CRUD)*

Les 4 opérations : **C**reate (`CREATE`/`MERGE`), **R**ead (`MATCH`), **U**pdate (`SET`/`REMOVE`), **D**elete (`DELETE`/`DETACH DELETE`). On travaille sur un produit **jetable (id 14)** qu'on supprime ensuite → retour à **41** nœuds (le jeu de données des Q1→Q12 reste intact).

**Ajouter (C) + relier :**
```cypher
MERGE (p:Product {id:14}) SET p.name='Tablette NoteTab', p.price=329
MERGE (p)-[:IN_CATEGORY]->(:Category {name:'Ordinateurs'})
MERGE (p)-[:MADE_BY]->(:Brand {name:'Nordia'});
```
**Mettre à jour (U)** — modifier / ajouter une propriété :
```cypher
MATCH (p:Product {id:14}) SET p.price = 299, p.enPromo = true RETURN p;
```
**Supprimer une relation (D) :**
```cypher
MATCH (:Product {id:14})-[r:MADE_BY]->(:Brand) DELETE r;
```
**Supprimer le nœud** — il faut `DETACH` (sinon `DELETE` échoue car il a des relations) :
```cypher
MATCH (p:Product {id:14}) DETACH DELETE p;
```
**Vérifier le retour à 41 :**
```cypher
MATCH (n) RETURN count(n);   // -> 41
```

---

## Comprendre `OPTIONAL MATCH` (pas à pas)  *(avant Q7)*

But : **compter les avis par produit**. Avec un `MATCH` classique, les produits **jamais notés disparaissent** (c'est un `INNER JOIN`) :
```cypher
MATCH (p:Product)
MATCH (:Customer)-[r:RATED]->(p)
RETURN p.name, count(r) AS nb_avis;
```
Avec `OPTIONAL MATCH`, on **garde tous les produits** (sans avis → `r = NULL`, et `count(NULL) = 0` — un `LEFT JOIN`) :
```cypher
MATCH (p:Product)
OPTIONAL MATCH (:Customer)-[r:RATED]->(p)
RETURN p.name, count(r) AS nb_avis;
```
> À retenir : « **tous** les produits, **et** leurs avis **s'ils en ont** ». On l'applique tout de suite (Q7 = produits sans avis, Q8 = clients sans achat).

---

## Q1 — Lister les smartphones  *(FR1)* — WHERE + ORDER BY

**Idée.** Un motif simple + filtre sur la catégorie reliée + tri.

```cypher
MATCH (p:Product)-[:IN_CATEGORY]->(:Category {name:'Smartphones'})
RETURN p.name, p.price ORDER BY p.price DESC;
```
**Résultat attendu :** Aura X (699), Pixel-N (599), Aura Mini (499).

---

## Q2 — Produits d'une marque  *(FR1)* — suivre une relation typée

```cypher
MATCH (p:Product)-[:MADE_BY]->(:Brand {name:'Lumio'})
RETURN p.name, p.price ORDER BY p.name;
```
**Résultat attendu (5) :** Casque BassPro, Clavier MecaType, Ecouteurs AirLite, Grille-pain ToastEdge, Souris ErgoClick.
**À dire :** suivre la flèche = la « jointure » disparaît (rappel Scénario 1).

---

## Q3 — Top 3 des best-sellers  *(FR5)* — agrégation `sum` + ORDER BY + LIMIT

**Idée.** Agréger une **propriété de relation** (`r.qty`) par produit.

```cypher
MATCH (:Customer)-[r:PURCHASED]->(p:Product)
RETURN p.name AS produit, sum(r.qty) AS unites_vendues
ORDER BY unites_vendues DESC LIMIT 3;
```
**Résultat attendu :** Aura X **6**, Ecouteurs AirLite **5**, Casque BassPro **4**.

---

## Q4 — Note moyenne par produit  *(FR5)* — `avg` + `count`

```cypher
MATCH (:Customer)-[r:RATED]->(p:Product)
RETURN p.name AS produit, round(avg(r.stars),2) AS note_moyenne, count(r) AS nb_avis
ORDER BY note_moyenne DESC;
```
**Résultat attendu :** ZenBook-14 5.0 (1), Casque BassPro 4.33 (3), Aura X 4.25 (4), Cafetiere BaristaOne 4.0 (1), Ecouteurs AirLite 3.5 (2), Pixel-N 2.0 (1).
⚠️ **[vérifier live]** le format de `round(...,2)`.

---

## Q5 — Dépense totale par client  *(FR5)* — `sum` d'une expression

```cypher
MATCH (c:Customer)-[r:PURCHASED]->()
RETURN c.name AS client, sum(r.qty * r.unitPrice) AS total_depense
ORDER BY total_depense DESC;
```
**Résultat attendu :** Bruno 1596, Hugo 1488, David 1327, Gaelle 1047, Chloe 947, Alice 848, Farid 798, Jonas 798, Ines 378, Emma 248. *(Kenza n'apparaît pas : aucun achat.)*

Enchaîner min / max / moyenne **globaux** avec `WITH` :
```cypher
MATCH (c:Customer)-[r:PURCHASED]->()
WITH c, sum(r.qty * r.unitPrice) AS t
RETURN min(t) AS mini, max(t) AS maxi, round(avg(t),0) AS moyen;
```
**Résultat attendu :** mini 248, maxi 1596, moyen ≈ 948 (947,5).

---

## Q6 — Catégories où un client a acheté  *(FR6)* — `DISTINCT` + `collect`

```cypher
MATCH (:Customer {name:'Alice'})-[:PURCHASED]->(:Product)-[:IN_CATEGORY]->(cat:Category)
RETURN collect(DISTINCT cat.name) AS categories_achetees;
```
**Résultat attendu :** Alice → ['Smartphones', 'Audio']. *(ordre de la liste non garanti.)*
**À dire :** `collect()` agrège des lignes en **liste** ; `DISTINCT` enlève les doublons.

---

## Q7 — Produits jamais notés  *(FR4)* — `OPTIONAL MATCH`

**Idée.** `OPTIONAL MATCH` = le « LEFT JOIN » : on garde les produits **même sans avis** (`r` vaut `NULL`).

```cypher
MATCH (p:Product)
OPTIONAL MATCH (:Customer)-[r:RATED]->(p)
WITH p, count(r) AS nb
WHERE nb = 0
RETURN p.name AS jamais_note ORDER BY p.name;
```
**Résultat attendu (7) :** Blender NutriMix, Clavier MecaType, Enceinte SoundOrb, Grille-pain ToastEdge, Laptop ProBook-15, Smartphone Aura Mini, Souris ErgoClick.

---

## Q8 — Clients sans aucun achat  *(FR3)* — `OPTIONAL MATCH` (côté client)

**Idée métier :** les repérer pour les **ré-engager** (promo, relance).

```cypher
MATCH (c:Customer)
OPTIONAL MATCH (c)-[pu:PURCHASED]->()
WITH c, count(pu) AS nb
WHERE nb = 0
RETURN c.name AS a_relancer;
```
**Résultat attendu :** Kenza.

---

## Q9 — `WITH` (pipeline) : produits bien notés ET leurs ventes  *(FR5)*

**Idée.** `WITH` passe un résultat intermédiaire (la note moyenne filtrée) à une **2e** interrogation (les ventes) — impossible en un seul `MATCH` plat.

```cypher
MATCH (:Customer)-[r:RATED]->(p:Product)
WITH p, avg(r.stars) AS note WHERE note >= 4.0
MATCH (:Customer)-[pu:PURCHASED]->(p)
RETURN p.name AS produit, round(note,2) AS note, sum(pu.qty) AS unites
ORDER BY unites DESC;
```
**Résultat attendu :** Aura X (4.25, 6 unités), Casque BassPro (4.33, 4), ZenBook-14 (5.0, 1), Cafetiere BaristaOne (4.0, 1).
⚠️ **[vérifier live]** le `WHERE` porte bien sur l'agrégat **après** `WITH`.

---

## Q10 — Produits d'une catégorie ET de ses sous-catégories  *(FR7)* — longueur variable

**Idée.** Le `*` du Scénario 1, réinvesti sur la **hiérarchie de catégories**.

```cypher
MATCH (p:Product)-[:IN_CATEGORY]->(:Category)-[:SUBCATEGORY_OF*0..]->(:Category {name:'Electronique'})
RETURN p.name ORDER BY p.name;
```
**Résultat attendu (10) :** tout sauf la Cuisine — Aura X, Aura Mini, Pixel-N, BassPro, AirLite, SoundOrb, ZenBook-14, ProBook-15, ErgoClick, MecaType.
*(Variante `'Maison'` → 3 : Blender, Cafetiere, Grille-pain.)*
⚠️ **[vérifier live]** sens des flèches `SUBCATEGORY_OF` (feuille → racine) : si vide, flèche inversée. `*0..` = « 0 saut ou plus ».

---

## Q11 — ⭐ RECOMMANDATION (filtrage collaboratif)  *(FR8)* — le wow

**NL :** « Pour Alice : les produits achetés par les clients qui ont acheté **les mêmes** produits qu'elle, en **excluant** ce qu'elle possède déjà, classés par fréquence. »

```cypher
MATCH (moi:Customer {name:'Alice'})-[:PURCHASED]->(commun:Product)
      <-[:PURCHASED]-(autre:Customer)-[:PURCHASED]->(reco:Product)
WHERE autre <> moi
  AND NOT (moi)-[:PURCHASED]->(reco)
RETURN reco.name AS recommandation, count(DISTINCT autre) AS clients_en_commun
ORDER BY clients_en_commun DESC, reco.name;
```
**Résultat attendu :** Ecouteurs AirLite **4**, Enceinte SoundOrb **1**. → recommander **Ecouteurs AirLite**.

⚠️ **[à marteler / vérifier live]**
- `autre <> moi` : exclut Alice elle-même.
- `NOT (moi)-[:PURCHASED]->(reco)` : exclut ce qu'Alice a déjà (Aura X, BassPro).
- `count(DISTINCT autre)` : compte les **clients** distincts, pas les chemins (sinon le classement est faussé). C'est **la** subtilité de la requête.

---

## Q12 — 🚚 CLIMAX : itinéraire de livraison  *(FR9)* — `shortestPath()` + `reduce()`

Contexte : livrer **Smartphone Aura X** (stocké à **Entrepot-Lyon**) au client **Alice** (à **Paris**). Plusieurs routes existent.

**a) Dessiner toutes les routes :**
```cypher
MATCH path = (:Warehouse {name:'Entrepot-Lyon'})-[:SHIPS_TO*1..4]->(:City {name:'Paris'})
RETURN path;
```

**Comprendre `reduce()` (pas à pas).** `reduce()` = une boucle qui **accumule** un résultat. Anatomie : `reduce(acc = depart, x IN liste | maj(acc, x))`. Exemple sur une liste de nombres :
```cypher
RETURN reduce(total = 0, x IN [20, 15, 8] | total + x) AS somme;   // -> 43
```
Déroulé : `0 → 0+20=20 → 20+15=35 → 35+8=43`. Sur un chemin, `relationships(p)` donne **la liste des arêtes** : on additionne leur propriété `.cost` (ci-dessous).

**b) `shortestPath()` — le moins de SAUTS (intégré à Neo4j) :**
```cypher
MATCH (w:Warehouse {name:'Entrepot-Lyon'}), (v:City {name:'Paris'})
MATCH p = shortestPath( (w)-[:SHIPS_TO*]->(v) )
RETURN [n IN nodes(p) | n.name] AS route, length(p) AS sauts;
```
**Résultat attendu :** [Entrepot-Lyon, Paris], **1 saut** — mais c'est la route directe à **95 €** / **14 h** !

**c) Coût & durée RÉELS de chaque route via `reduce()`, classés :**
```cypher
MATCH p = (w:Warehouse {name:'Entrepot-Lyon'})-[:SHIPS_TO*1..4]->(v:City {name:'Paris'})
RETURN [n IN nodes(p) | n.name] AS route,
       reduce(c=0, r IN relationships(p) | c + r.cost)  AS cout_total,
       reduce(h=0, r IN relationships(p) | h + r.hours) AS duree_totale
ORDER BY cout_total ASC;
```
**Résultat attendu (le moins cher en tête) :**
- Entrepot-Lyon → Hub-Centre → Hub-Nord → Paris : **43 €**, 13 h (3 sauts)
- Entrepot-Lyon → Hub-Sud → Hub-Nord → Paris : 53 €, 9 h
- Entrepot-Lyon → Hub-Centre → Paris : 60 €, 15 h
- Entrepot-Lyon → Paris : 95 €, 14 h

**d) Le plus rapide** = même requête, `ORDER BY duree_totale ASC` → Entrepot-Lyon → Hub-Sud → Hub-Nord → Paris (**9 h**, 53 €).

⚠️ **Caveat honnête (à dire) :** `shortestPath()` minimise le **nombre de sauts**, pas le coût ni la durée. Pour le vrai coût/temps, on **somme** les propriétés des relations du chemin avec `reduce()` puis on classe avec `ORDER BY`. **3 critères → 3 itinéraires gagnants.**
⚠️ **[vérifier live]** sens des `SHIPS_TO` (entrepôt → … → ville) ; borne `*1..4`.

---

## Réinitialisation (entre deux répétitions)

```cypher
MATCH (n) DETACH DELETE n;
```
Puis recoller les blocs de `build.cypher` dans l'ordre (`A1 → C3`, `MERGE` → idempotent) et revérifier `MATCH (n) RETURN count(n);` = **41**.

---

### Aide-mémoire : modèle du graphe

| Nœud | Relation | Vers | Propriétés | Cardinalité |
|---|---|---|---|---|
| Product | `:IN_CATEGORY` | Category | — | N:1 |
| Category | `:SUBCATEGORY_OF` | Category (parente) | — | N:1 *(récursif)* |
| Product | `:MADE_BY` | Brand | — | N:1 |
| Customer | `:PURCHASED` | Product | date, qty, unitPrice | M:N |
| Customer | `:RATED` | Product | stars, date | M:N |
| Customer | `:LIVES_IN` | City | — | N:1 |
| Product | `:STOCKED_AT` | Warehouse | — | N:1 |
| Warehouse/Hub | `:SHIPS_TO` | Hub/City | hours, cost | 1:N *(pondérée)* |
