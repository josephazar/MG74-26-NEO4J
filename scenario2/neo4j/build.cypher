// =====================================================================
// MG74 - Scenario 2 : NOVANEST (e-commerce / recommandation)
// Construction du graphe en Cypher (Neo4j)
//
// >>> EXECUTION PAR BLOCS <<<
// Copier-coller un BLOC a la fois dans Neo4j Browser.
// Chaque bloc est une instruction Cypher autonome : il reacquiert les
// noeuds necessaires avec MATCH/MERGE au lieu de reutiliser les variables
// du bloc precedent.
//
// Construit avec MERGE : IDEMPOTENT -> on peut relancer un bloc sans
// creer de doublons.
//
// Pour repartir de zero :   MATCH (n) DETACH DELETE n;
// Verification finale   :   MATCH (n) RETURN count(n);   // -> 41
// =====================================================================

// ===================== ETAPE A1 : Marques + categories =====================
MERGE (bNordia:Brand {name:'Nordia'})
MERGE (bLumio:Brand  {name:'Lumio'})
MERGE (bCassia:Brand {name:'Cassia'})
MERGE (cElec:Category   {name:'Electronique'}) SET cElec.level='racine'
MERGE (cMaison:Category {name:'Maison'})       SET cMaison.level='racine'
MERGE (cSmart:Category  {name:'Smartphones'})  SET cSmart.level='feuille'
MERGE (cAudio:Category  {name:'Audio'})        SET cAudio.level='feuille'
MERGE (cOrdi:Category   {name:'Ordinateurs'})  SET cOrdi.level='feuille'
MERGE (cCuis:Category   {name:'Cuisine'})      SET cCuis.level='feuille';

// ===================== ETAPE A2 : Produits =====================
MERGE (p1:Product  {id:1})  SET p1.name='Smartphone Aura X',      p1.price=699
MERGE (p2:Product  {id:2})  SET p2.name='Smartphone Aura Mini',   p2.price=499
MERGE (p3:Product  {id:3})  SET p3.name='Smartphone Pixel-N',     p3.price=599
MERGE (p4:Product  {id:4})  SET p4.name='Casque BassPro',         p4.price=149
MERGE (p5:Product  {id:5})  SET p5.name='Ecouteurs AirLite',      p5.price=99
MERGE (p6:Product  {id:6})  SET p6.name='Enceinte SoundOrb',      p6.price=199
MERGE (p7:Product  {id:7})  SET p7.name='Laptop ZenBook-14',      p7.price=1199
MERGE (p8:Product  {id:8})  SET p8.name='Laptop ProBook-15',      p8.price=1399
MERGE (p9:Product  {id:9})  SET p9.name='Souris ErgoClick',       p9.price=39
MERGE (p10:Product {id:10}) SET p10.name='Clavier MecaType',      p10.price=89
MERGE (p11:Product {id:11}) SET p11.name='Blender NutriMix',      p11.price=129
MERGE (p12:Product {id:12}) SET p12.name='Cafetiere BaristaOne',  p12.price=249
MERGE (p13:Product {id:13}) SET p13.name='Grille-pain ToastEdge', p13.price=59;

// ===================== ETAPE A3 : Clients =====================
// u11 = Kenza, sans aucun achat.
MERGE (u1:Customer  {id:1})  SET u1.name='Alice'
MERGE (u2:Customer  {id:2})  SET u2.name='Bruno'
MERGE (u3:Customer  {id:3})  SET u3.name='Chloe'
MERGE (u4:Customer  {id:4})  SET u4.name='David'
MERGE (u5:Customer  {id:5})  SET u5.name='Emma'
MERGE (u6:Customer  {id:6})  SET u6.name='Farid'
MERGE (u7:Customer  {id:7})  SET u7.name='Gaelle'
MERGE (u8:Customer  {id:8})  SET u8.name='Hugo'
MERGE (u9:Customer  {id:9})  SET u9.name='Ines'
MERGE (u10:Customer {id:10}) SET u10.name='Jonas'
MERGE (u11:Customer {id:11}) SET u11.name='Kenza';

// ===================== ETAPE A4 : Couche logistique =====================
MERGE (wLyon:Warehouse  {name:'Entrepot-Lyon'})
MERGE (wParis:Warehouse {name:'Entrepot-Paris'})
MERGE (hCentre:Hub {name:'Hub-Centre'})
MERGE (hSud:Hub    {name:'Hub-Sud'})
MERGE (hNord:Hub   {name:'Hub-Nord'})
MERGE (ctParis:City {name:'Paris'})
MERGE (ctLyon:City  {name:'Lyon'})
MERGE (ctLille:City {name:'Lille'});

// ===================== ETAPE B1 : Hierarchie des categories =====================
// Relation orientee : categorie feuille -> categorie racine.
MATCH (cElec:Category {name:'Electronique'})
MATCH (cMaison:Category {name:'Maison'})
MATCH (cSmart:Category {name:'Smartphones'})
MATCH (cAudio:Category {name:'Audio'})
MATCH (cOrdi:Category {name:'Ordinateurs'})
MATCH (cCuis:Category {name:'Cuisine'})
MERGE (cSmart)-[:SUBCATEGORY_OF]->(cElec)
MERGE (cAudio)-[:SUBCATEGORY_OF]->(cElec)
MERGE (cOrdi)-[:SUBCATEGORY_OF]->(cElec)
MERGE (cCuis)-[:SUBCATEGORY_OF]->(cMaison);

// ===================== ETAPE B2 : Produit -> categorie feuille =====================
MATCH (cSmart:Category {name:'Smartphones'})
MATCH (cAudio:Category {name:'Audio'})
MATCH (cOrdi:Category {name:'Ordinateurs'})
MATCH (cCuis:Category {name:'Cuisine'})
MATCH (p1:Product {id:1})
MATCH (p2:Product {id:2})
MATCH (p3:Product {id:3})
MATCH (p4:Product {id:4})
MATCH (p5:Product {id:5})
MATCH (p6:Product {id:6})
MATCH (p7:Product {id:7})
MATCH (p8:Product {id:8})
MATCH (p9:Product {id:9})
MATCH (p10:Product {id:10})
MATCH (p11:Product {id:11})
MATCH (p12:Product {id:12})
MATCH (p13:Product {id:13})
MERGE (p1)-[:IN_CATEGORY]->(cSmart)
MERGE (p2)-[:IN_CATEGORY]->(cSmart)
MERGE (p3)-[:IN_CATEGORY]->(cSmart)
MERGE (p4)-[:IN_CATEGORY]->(cAudio)
MERGE (p5)-[:IN_CATEGORY]->(cAudio)
MERGE (p6)-[:IN_CATEGORY]->(cAudio)
MERGE (p7)-[:IN_CATEGORY]->(cOrdi)
MERGE (p8)-[:IN_CATEGORY]->(cOrdi)
MERGE (p9)-[:IN_CATEGORY]->(cOrdi)
MERGE (p10)-[:IN_CATEGORY]->(cOrdi)
MERGE (p11)-[:IN_CATEGORY]->(cCuis)
MERGE (p12)-[:IN_CATEGORY]->(cCuis)
MERGE (p13)-[:IN_CATEGORY]->(cCuis);

// ===================== ETAPE B3 : Produit -> marque =====================
MATCH (bNordia:Brand {name:'Nordia'})
MATCH (bLumio:Brand {name:'Lumio'})
MATCH (bCassia:Brand {name:'Cassia'})
MATCH (p1:Product {id:1})
MATCH (p2:Product {id:2})
MATCH (p3:Product {id:3})
MATCH (p4:Product {id:4})
MATCH (p5:Product {id:5})
MATCH (p6:Product {id:6})
MATCH (p7:Product {id:7})
MATCH (p8:Product {id:8})
MATCH (p9:Product {id:9})
MATCH (p10:Product {id:10})
MATCH (p11:Product {id:11})
MATCH (p12:Product {id:12})
MATCH (p13:Product {id:13})
MERGE (p1)-[:MADE_BY]->(bNordia)
MERGE (p2)-[:MADE_BY]->(bNordia)
MERGE (p3)-[:MADE_BY]->(bCassia)
MERGE (p4)-[:MADE_BY]->(bLumio)
MERGE (p5)-[:MADE_BY]->(bLumio)
MERGE (p6)-[:MADE_BY]->(bCassia)
MERGE (p7)-[:MADE_BY]->(bNordia)
MERGE (p8)-[:MADE_BY]->(bCassia)
MERGE (p9)-[:MADE_BY]->(bLumio)
MERGE (p10)-[:MADE_BY]->(bLumio)
MERGE (p11)-[:MADE_BY]->(bNordia)
MERGE (p12)-[:MADE_BY]->(bCassia)
MERGE (p13)-[:MADE_BY]->(bLumio);

// ===================== ETAPE B4 : Client -> ville =====================
MATCH (ctParis:City {name:'Paris'})
MATCH (ctLyon:City {name:'Lyon'})
MATCH (ctLille:City {name:'Lille'})
MATCH (u1:Customer {id:1})
MATCH (u2:Customer {id:2})
MATCH (u3:Customer {id:3})
MATCH (u4:Customer {id:4})
MATCH (u5:Customer {id:5})
MATCH (u6:Customer {id:6})
MATCH (u7:Customer {id:7})
MATCH (u8:Customer {id:8})
MATCH (u9:Customer {id:9})
MATCH (u10:Customer {id:10})
MATCH (u11:Customer {id:11})
MERGE (u1)-[:LIVES_IN]->(ctParis)
MERGE (u2)-[:LIVES_IN]->(ctLyon)
MERGE (u3)-[:LIVES_IN]->(ctParis)
MERGE (u4)-[:LIVES_IN]->(ctLille)
MERGE (u5)-[:LIVES_IN]->(ctParis)
MERGE (u6)-[:LIVES_IN]->(ctLyon)
MERGE (u7)-[:LIVES_IN]->(ctLille)
MERGE (u8)-[:LIVES_IN]->(ctParis)
MERGE (u9)-[:LIVES_IN]->(ctLyon)
MERGE (u10)-[:LIVES_IN]->(ctLille)
MERGE (u11)-[:LIVES_IN]->(ctLyon);

// ===================== ETAPE B5 : Produit -> entrepot =====================
// Electronique a Lyon, cuisine a Paris.
MATCH (wLyon:Warehouse {name:'Entrepot-Lyon'})
MATCH (wParis:Warehouse {name:'Entrepot-Paris'})
MATCH (p1:Product {id:1})
MATCH (p2:Product {id:2})
MATCH (p3:Product {id:3})
MATCH (p4:Product {id:4})
MATCH (p5:Product {id:5})
MATCH (p6:Product {id:6})
MATCH (p7:Product {id:7})
MATCH (p8:Product {id:8})
MATCH (p9:Product {id:9})
MATCH (p10:Product {id:10})
MATCH (p11:Product {id:11})
MATCH (p12:Product {id:12})
MATCH (p13:Product {id:13})
MERGE (p1)-[:STOCKED_AT]->(wLyon)
MERGE (p2)-[:STOCKED_AT]->(wLyon)
MERGE (p3)-[:STOCKED_AT]->(wLyon)
MERGE (p4)-[:STOCKED_AT]->(wLyon)
MERGE (p5)-[:STOCKED_AT]->(wLyon)
MERGE (p6)-[:STOCKED_AT]->(wLyon)
MERGE (p7)-[:STOCKED_AT]->(wLyon)
MERGE (p8)-[:STOCKED_AT]->(wLyon)
MERGE (p9)-[:STOCKED_AT]->(wLyon)
MERGE (p10)-[:STOCKED_AT]->(wLyon)
MERGE (p11)-[:STOCKED_AT]->(wParis)
MERGE (p12)-[:STOCKED_AT]->(wParis)
MERGE (p13)-[:STOCKED_AT]->(wParis);

// ===================== ETAPE C1 : Achats =====================
// PURCHASED {date, qty, unitPrice} ; unitPrice = prix du produit.
MATCH (u1:Customer {id:1})
MATCH (u2:Customer {id:2})
MATCH (u3:Customer {id:3})
MATCH (u4:Customer {id:4})
MATCH (u5:Customer {id:5})
MATCH (u6:Customer {id:6})
MATCH (u7:Customer {id:7})
MATCH (u8:Customer {id:8})
MATCH (u9:Customer {id:9})
MATCH (u10:Customer {id:10})
MATCH (p1:Product {id:1})
MATCH (p3:Product {id:3})
MATCH (p4:Product {id:4})
MATCH (p5:Product {id:5})
MATCH (p6:Product {id:6})
MATCH (p7:Product {id:7})
MATCH (p8:Product {id:8})
MATCH (p9:Product {id:9})
MATCH (p10:Product {id:10})
MATCH (p11:Product {id:11})
MATCH (p12:Product {id:12})
MERGE (u1)-[:PURCHASED {date:'2026-06-01', qty:1, unitPrice:699}]->(p1)
MERGE (u1)-[:PURCHASED {date:'2026-06-01', qty:1, unitPrice:149}]->(p4)
MERGE (u2)-[:PURCHASED {date:'2026-06-02', qty:2, unitPrice:699}]->(p1)
MERGE (u2)-[:PURCHASED {date:'2026-06-02', qty:2, unitPrice:99}]->(p5)
MERGE (u3)-[:PURCHASED {date:'2026-06-03', qty:1, unitPrice:699}]->(p1)
MERGE (u3)-[:PURCHASED {date:'2026-06-03', qty:1, unitPrice:149}]->(p4)
MERGE (u3)-[:PURCHASED {date:'2026-06-03', qty:1, unitPrice:99}]->(p5)
MERGE (u4)-[:PURCHASED {date:'2026-06-04', qty:1, unitPrice:1199}]->(p7)
MERGE (u4)-[:PURCHASED {date:'2026-06-04', qty:1, unitPrice:39}]->(p9)
MERGE (u4)-[:PURCHASED {date:'2026-06-04', qty:1, unitPrice:89}]->(p10)
MERGE (u5)-[:PURCHASED {date:'2026-06-05', qty:1, unitPrice:149}]->(p4)
MERGE (u5)-[:PURCHASED {date:'2026-06-05', qty:1, unitPrice:99}]->(p5)
MERGE (u6)-[:PURCHASED {date:'2026-06-06', qty:1, unitPrice:599}]->(p3)
MERGE (u6)-[:PURCHASED {date:'2026-06-06', qty:1, unitPrice:199}]->(p6)
MERGE (u7)-[:PURCHASED {date:'2026-06-07', qty:1, unitPrice:699}]->(p1)
MERGE (u7)-[:PURCHASED {date:'2026-06-07', qty:1, unitPrice:149}]->(p4)
MERGE (u7)-[:PURCHASED {date:'2026-06-07', qty:1, unitPrice:199}]->(p6)
MERGE (u8)-[:PURCHASED {date:'2026-06-08', qty:1, unitPrice:1399}]->(p8)
MERGE (u8)-[:PURCHASED {date:'2026-06-08', qty:1, unitPrice:89}]->(p10)
MERGE (u9)-[:PURCHASED {date:'2026-06-09', qty:1, unitPrice:129}]->(p11)
MERGE (u9)-[:PURCHASED {date:'2026-06-09', qty:1, unitPrice:249}]->(p12)
MERGE (u10)-[:PURCHASED {date:'2026-06-10', qty:1, unitPrice:699}]->(p1)
MERGE (u10)-[:PURCHASED {date:'2026-06-10', qty:1, unitPrice:99}]->(p5);

// ===================== ETAPE C2 : Avis =====================
// RATED {stars, date}
MATCH (u1:Customer {id:1})
MATCH (u2:Customer {id:2})
MATCH (u3:Customer {id:3})
MATCH (u4:Customer {id:4})
MATCH (u5:Customer {id:5})
MATCH (u6:Customer {id:6})
MATCH (u7:Customer {id:7})
MATCH (u9:Customer {id:9})
MATCH (p1:Product {id:1})
MATCH (p3:Product {id:3})
MATCH (p4:Product {id:4})
MATCH (p5:Product {id:5})
MATCH (p7:Product {id:7})
MATCH (p12:Product {id:12})
MERGE (u1)-[:RATED {stars:5, date:'2026-06-11'}]->(p1)
MERGE (u2)-[:RATED {stars:4, date:'2026-06-11'}]->(p1)
MERGE (u3)-[:RATED {stars:5, date:'2026-06-11'}]->(p1)
MERGE (u7)-[:RATED {stars:3, date:'2026-06-11'}]->(p1)
MERGE (u1)-[:RATED {stars:4, date:'2026-06-12'}]->(p4)
MERGE (u3)-[:RATED {stars:5, date:'2026-06-12'}]->(p4)
MERGE (u7)-[:RATED {stars:4, date:'2026-06-12'}]->(p4)
MERGE (u2)-[:RATED {stars:3, date:'2026-06-13'}]->(p5)
MERGE (u5)-[:RATED {stars:4, date:'2026-06-13'}]->(p5)
MERGE (u4)-[:RATED {stars:5, date:'2026-06-14'}]->(p7)
MERGE (u6)-[:RATED {stars:2, date:'2026-06-14'}]->(p3)
MERGE (u9)-[:RATED {stars:4, date:'2026-06-14'}]->(p12);

// ===================== ETAPE C3 : Routes logistiques =====================
// SHIPS_TO {hours, cost} ; orientation : entrepot/hub -> hub/ville.
MATCH (wLyon:Warehouse {name:'Entrepot-Lyon'})
MATCH (hCentre:Hub {name:'Hub-Centre'})
MATCH (hSud:Hub {name:'Hub-Sud'})
MATCH (hNord:Hub {name:'Hub-Nord'})
MATCH (ctParis:City {name:'Paris'})
MERGE (wLyon)-[:SHIPS_TO {hours:6,  cost:20}]->(hCentre)
MERGE (wLyon)-[:SHIPS_TO {hours:4,  cost:35}]->(hSud)
MERGE (wLyon)-[:SHIPS_TO {hours:14, cost:95}]->(ctParis)
MERGE (hCentre)-[:SHIPS_TO {hours:5, cost:15}]->(hNord)
MERGE (hCentre)-[:SHIPS_TO {hours:9, cost:40}]->(ctParis)
MERGE (hSud)-[:SHIPS_TO {hours:3, cost:10}]->(hNord)
MERGE (hNord)-[:SHIPS_TO {hours:2, cost:8}]->(ctParis);
