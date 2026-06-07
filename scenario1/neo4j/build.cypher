// =====================================================================
// MG74 - Scenario 1 : SochauxSense SAS (smart-factory IoT)
// Le BON consultant : modelisation orientee graphe (Neo4j)
//
// >>> EXECUTION PAR BLOCS <<<
// Copier-coller un BLOC a la fois dans Neo4j Browser.
// Chaque bloc est une instruction Cypher autonome : il reacquiert les
// noeuds necessaires avec MATCH au lieu de reutiliser les variables du
// bloc precedent.
// Attention : ce scenario utilise CREATE. Executer chaque bloc une fois
// apres reset ; relancer un bloc deja execute cree des doublons.
//
// Pour repartir de zero avant de (re)construire :
//   MATCH (n) DETACH DELETE n;
// Verification finale :
//   MATCH (n) RETURN count(n);   // -> 25
// =====================================================================

// ===================== BLOC 1 : Site / Buildings / Zones =====================
CREATE (site:Site {id:1, name:'Usine Sochaux-Nord', city:'Sochaux'})
CREATE (b1:Building {id:1, name:'Atelier Emboutissage'})
CREATE (b2:Building {id:2, name:'Atelier Montage'})
CREATE (z1:Zone {id:1, name:'Ligne Presse A'})
CREATE (z2:Zone {id:2, name:'Ligne Presse B'})
CREATE (z3:Zone {id:3, name:'Ligne Montage 1'})
CREATE (site)-[:HAS_BUILDING]->(b1)
CREATE (site)-[:HAS_BUILDING]->(b2)
CREATE (b1)-[:HAS_ZONE]->(z1)
CREATE (b1)-[:HAS_ZONE]->(z2)
CREATE (b2)-[:HAS_ZONE]->(z3);

// ===================== BLOC 2 : Machines =====================
MATCH (z1:Zone {id:1})
MATCH (z2:Zone {id:2})
MATCH (z3:Zone {id:3})
CREATE (m1:Machine {id:1, name:'Presse Schuler-2000', model:'Presse Schuler-2000', criticality:'critique'})
CREATE (m2:Machine {id:2, name:'Convoyeur-CX',        model:'Convoyeur-CX',        criticality:'normale'})
CREATE (m3:Machine {id:3, name:'Presse Schuler-1500', model:'Presse Schuler-1500', criticality:'critique'})
CREATE (m4:Machine {id:4, name:'Robot-KUKA-KR16',     model:'Robot-KUKA-KR16',     criticality:'critique'})
CREATE (z1)-[:HAS_MACHINE]->(m1)
CREATE (z1)-[:HAS_MACHINE]->(m2)
CREATE (z2)-[:HAS_MACHINE]->(m3)
CREATE (z3)-[:HAS_MACHINE]->(m4);

// ===================== BLOC 3 : Passerelles =====================
// UPLINKS_TO pointe vers la PARENTE.
//   GW-Edge-Core (1)
//     |- GW-A (2) -> GW-A1 (3)
//     |- GW-B (4) -> GW-B1 (5)
CREATE (gEdge:Gateway {id:1, name:'GW-Edge-Core'})
CREATE (gA:Gateway   {id:2, name:'GW-A'})
CREATE (gA1:Gateway  {id:3, name:'GW-A1'})
CREATE (gB:Gateway   {id:4, name:'GW-B'})
CREATE (gB1:Gateway  {id:5, name:'GW-B1'})
CREATE (gA)-[:UPLINKS_TO]->(gEdge)
CREATE (gA1)-[:UPLINKS_TO]->(gA)
CREATE (gB)-[:UPLINKS_TO]->(gEdge)
CREATE (gB1)-[:UPLINKS_TO]->(gB);

// ===================== BLOC 4 : Capteurs =====================
// Capteur CONNECTS_TO une passerelle ; Machine HAS_SENSOR capteur.
MATCH (m1:Machine {id:1})
MATCH (m2:Machine {id:2})
MATCH (m3:Machine {id:3})
MATCH (m4:Machine {id:4})
MATCH (gA:Gateway {id:2})
MATCH (gA1:Gateway {id:3})
MATCH (gB:Gateway {id:4})
MATCH (gB1:Gateway {id:5})
CREATE (s1:Sensor {id:1, name:'S1 vibration',   type:'vibration',   unit:'mm/s'})
CREATE (s2:Sensor {id:2, name:'S2 temperature', type:'temperature', unit:'C'})
CREATE (s3:Sensor {id:3, name:'S3 current',     type:'current',     unit:'A'})
CREATE (s4:Sensor {id:4, name:'S4 vibration',   type:'vibration',   unit:'mm/s'})
CREATE (s5:Sensor {id:5, name:'S5 vibration',   type:'vibration',   unit:'mm/s'})
CREATE (m1)-[:HAS_SENSOR]->(s1)
CREATE (m1)-[:HAS_SENSOR]->(s2)
CREATE (m2)-[:HAS_SENSOR]->(s3)
CREATE (m3)-[:HAS_SENSOR]->(s4)
CREATE (m4)-[:HAS_SENSOR]->(s5)
CREATE (s1)-[:CONNECTS_TO]->(gA1)
CREATE (s2)-[:CONNECTS_TO]->(gA1)
CREATE (s3)-[:CONNECTS_TO]->(gA)
CREATE (s4)-[:CONNECTS_TO]->(gB1)
CREATE (s5)-[:CONNECTS_TO]->(gB);

// ===================== BLOC 5 : Techniciens + responsabilites =====================
MATCH (z1:Zone {id:1})
MATCH (z2:Zone {id:2})
MATCH (z3:Zone {id:3})
CREATE (t1:Technician {id:1, name:'Karim B.',  team:'Maintenance Presses'})
CREATE (t2:Technician {id:2, name:'Sophie L.', team:'Maintenance Robotique'})
CREATE (t1)-[:RESPONSIBLE_FOR]->(z1)
CREATE (t1)-[:RESPONSIBLE_FOR]->(z2)
CREATE (t2)-[:RESPONSIBLE_FOR]->(z3);

// ===================== BLOC 6 : Alertes =====================
MATCH (s1:Sensor {id:1})
MATCH (s4:Sensor {id:4})
CREATE (a1:Alert {id:1, severity:'critique', ts:'2026-06-05 08:12'})
CREATE (a2:Alert {id:2, severity:'haute',    ts:'2026-06-05 09:40'})
CREATE (a3:Alert {id:3, severity:'haute',    ts:'2026-06-06 07:55'})
CREATE (a1)-[:RAISED_BY]->(s1)
CREATE (a2)-[:RAISED_BY]->(s4)
CREATE (a3)-[:RAISED_BY]->(s1);
