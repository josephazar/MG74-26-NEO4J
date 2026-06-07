# Bien démarrer avec Neo4j Desktop

Ce dossier sert de point d'entrée avant les trois scénarios du cours. L'objectif est simple : installer Neo4j Desktop, créer une base locale, ouvrir l'interface de requêtes, puis charger les fichiers `build.cypher` des scénarios.

## 1. Ce qu'il faut installer

Pour ce cours, le plus pratique est **Neo4j Desktop** :

- il installe une base Neo4j locale sur votre machine ;
- il fournit une licence Developer de Neo4j Enterprise Edition pour un usage local personnel ;
- il embarque les outils visuels utiles pour le cours, notamment l'interface **Query**, qui permet d'écrire du Cypher et de visualiser le graphe ;
- il gère la version de Neo4j et le runtime Java nécessaire. Sur macOS, certains composants peuvent être téléchargés au moment de l'exécution.

Lien officiel : [Neo4j Desktop - Installation](https://neo4j.com/docs/desktop/current/installation/)

## 2. Prérequis

D'après la documentation actuelle de Neo4j Desktop :

| Système | Prérequis indicatif |
|---|---|
| macOS | macOS 10.10 ou plus récent |
| Windows | Windows 10 avec PowerShell 5.1 ou plus récent |
| Linux | Ubuntu 22.04 ou Debian 11 |

Prévoyez aussi :

- une connexion Internet pendant l'installation ;
- quelques Go d'espace disque libre ;
- un mot de passe que vous garderez pour votre instance locale Neo4j.

## 3. Télécharger Neo4j Desktop

1. Aller sur le [Neo4j Deployment Center](https://neo4j.com/deployment-center/).
2. Choisir **Neo4j Desktop**.
3. Télécharger la version correspondant à votre système : macOS, Windows ou Linux.

Si le site demande une adresse e-mail ou une création de compte, utilisez votre adresse habituelle d'étudiant ou une adresse personnelle. Pour le cours, aucun service cloud payant n'est nécessaire.

## 4. Installer selon votre système

### macOS

1. Ouvrir le fichier `.dmg` téléchargé.
2. Glisser **Neo4j Desktop** dans le dossier `Applications`.
3. Lancer Neo4j Desktop depuis `Applications`.
4. Si macOS bloque l'ouverture, vérifier dans `Réglages Système > Confidentialité et sécurité`.

### Windows

1. Ouvrir le fichier d'installation téléchargé.
2. Suivre les étapes affichées à l'écran.
3. Lancer Neo4j Desktop depuis le menu Démarrer.
4. Si Windows Defender affiche un avertissement, vérifier que le fichier vient bien du site officiel Neo4j.

### Linux

1. Télécharger le fichier `AppImage`.
2. Le rendre exécutable :

```bash
chmod +x NOM_DU_FICHIER.AppImage
```

3. Lancer l'application :

```bash
./NOM_DU_FICHIER.AppImage
```

## 5. Créer une instance locale

Dans Neo4j Desktop, une **instance** correspond à un serveur Neo4j local contenant au minimum la base système et une base utilisateur.

1. Au premier lancement, cliquer sur **Create instance**.
2. Donner un nom clair, par exemple `MG74`.
3. Garder la version Neo4j proposée par défaut, sauf consigne contraire.
4. Créer un utilisateur et un mot de passe.
5. Cliquer sur **Create**.
6. Démarrer l'instance avec le bouton lecture.

À retenir :

- dans Neo4j Desktop 2.x, une seule instance locale peut tourner à la fois ;
- si l'instance ne démarre pas, vérifiez qu'une autre instance Neo4j n'est pas déjà active ;
- si vous oubliez le mot de passe, Neo4j Desktop permet de le réinitialiser depuis le menu `...` de l'instance, instance arrêtée.

Documentation utile : [Neo4j Desktop - Instance management](https://neo4j.com/docs/desktop/current/operations/instance-management/)

## 6. Ouvrir l'interface de requêtes

Depuis la carte de votre instance :

1. Cliquer sur **Connect**.
2. Ouvrir **Query**.
3. Vous arrivez dans l'interface où écrire les requêtes Cypher.

Selon la version et la configuration, l'interface peut aussi être appelée **Neo4j Browser**. Par défaut, une installation locale expose souvent :

- Browser : `http://localhost:7474/browser`
- Bolt : `bolt://localhost:7687`

Dans les fichiers du cours, suivez toujours l'URL indiquée par le runbook si elle diffère, par exemple `http://localhost:7475/browser/`.

Documentation utile :

- [Neo4j Browser](https://neo4j.com/docs/browser/)
- [Connexion à une instance Neo4j](https://neo4j.com/docs/browser/operations/dbms-connection/)

## 7. Vérifier que tout fonctionne

Dans Query ou Browser, exécuter :

```cypher
CREATE (n:Test {name:'Neo4j fonctionne'})
RETURN n;
```

Vous devez voir un noeud dans le résultat graphique.

Nettoyer ensuite :

```cypher
MATCH (n) DETACH DELETE n;
```

Puis vérifier :

```cypher
MATCH (n) RETURN count(n) AS noeuds;
```

Le résultat doit être `0`.

## 8. Charger les scénarios du cours

Les scénarios sont dans :

- `scenario1/neo4j/`
- `scenario2/neo4j/`
- `scenario3/`

Pour les scénarios Neo4j :

1. Ouvrir le fichier `build.cypher`.
2. Copier le premier bloc jusqu'au `;`.
3. Coller dans Query ou Browser.
4. Exécuter.
5. Continuer bloc par bloc.

Important :

- **Scénario 1** utilise surtout `CREATE`. Travaillez sur une base vide et n'exécutez chaque bloc qu'une seule fois, sinon vous créez des doublons.
- **Scénario 2** utilise `MERGE`. Les blocs sont idempotents : relancer un bloc ne doit pas créer de doublons.

Avant de recommencer un scénario depuis zéro :

```cypher
MATCH (n) DETACH DELETE n;
```

## 9. Astuce d'affichage dans Browser

Quand un graphe s'affiche, Neo4j choisit parfois une propriété peu lisible comme texte du noeud.

Pour améliorer l'affichage :

1. Cliquer sur une pastille de label dans la légende, par exemple `Machine`, `Sensor`, `Product`.
2. Choisir une couleur.
3. Régler **Caption** sur `name` quand la propriété existe.

Pour les scénarios du cours, les noeuds principaux ont été préparés pour être lisibles avec `Caption = name`.

## 10. Ressources à consulter

### Installation et outils

- [Neo4j Desktop - Installation](https://neo4j.com/docs/desktop/current/installation/)
- [Neo4j Desktop - Instance management](https://neo4j.com/docs/desktop/current/operations/instance-management/)
- [Neo4j Browser](https://neo4j.com/docs/browser/)
- [Neo4j Browser - Connexion à une instance](https://neo4j.com/docs/browser/operations/dbms-connection/)

### Apprendre Cypher

- [Get started with Cypher](https://neo4j.com/docs/getting-started/cypher/)
- [Documentation Cypher](https://neo4j.com/docs/cypher/)
- [Cypher Manual](https://neo4j.com/docs/cypher-manual/current/)
- [Cypher Cheat Sheet](https://neo4j.com/docs/cypher-cheat-sheet/current/)

### Formations gratuites

- [GraphAcademy](https://graphacademy.neo4j.com/)
- [Neo4j Fundamentals](https://graphacademy.neo4j.com/courses/neo4j-fundamentals/)
- [Cypher Fundamentals](https://graphacademy.neo4j.com/courses/cypher-fundamentals/)
- [Graph Data Modeling Fundamentals](https://graphacademy.neo4j.com/courses/modeling-fundamentals/)

### Aide et communauté

- [Neo4j Community Forum](https://community.neo4j.com/)
- [Neo4j Sandbox](https://sandbox.neo4j.com/)
- [Neo4j Developer Blog](https://medium.com/neo4j)
- [Neo4j YouTube](https://www.youtube.com/user/neo4j)

## 11. Mini aide-mémoire Cypher

Créer un noeud :

```cypher
CREATE (:Person {name:'Alice'});
```

Créer sans doublonner :

```cypher
MERGE (:Person {name:'Alice'});
```

Lire des noeuds :

```cypher
MATCH (p:Person)
RETURN p.name;
```

Créer une relation :

```cypher
MATCH (a:Person {name:'Alice'})
MATCH (b:Person {name:'Bob'})
CREATE (a)-[:KNOWS]->(b);
```

Afficher tout le graphe courant :

```cypher
MATCH (n) RETURN n;
```

Supprimer tout le graphe courant :

```cypher
MATCH (n) DETACH DELETE n;
```
