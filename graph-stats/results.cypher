// Neo4j query + result report


// ==================================================
// QUERY 1
// ==================================================
// POLE Crime Investigation - Graph Stats and Analytics
// Group 4: Amn Naqvi and Rayyan Shah

// SECTION 0: SETUP, VERSION CHECK, AND CLEANUP

// Query 0.1 - Neo4j version for reproducibility.
CALL dbms.components()
YIELD name, versions, edition
RETURN name, versions, edition;

// RESULT 1
// --------------------------------------------------
// name | versions | edition
// Neo4j Kernel | ["2026.03.1"] | enterprise
// Cypher | ["5","25"] | 

// ==================================================
// QUERY 2
// ==================================================
// Query 0.2 - GDS version for reproducibility.
RETURN gds.version() AS gdsVersion;

// RESULT 2
// --------------------------------------------------
// gdsVersion
// 2026.03.0

// ==================================================
// QUERY 3
// ==================================================
// Query 0.3 - Remove only properties written by our analysis scripts.
MATCH (n)
REMOVE n.communityId,
       n.componentId,
       n.socialCommunityId,
       n.socialComponentId,
       n.revisedSocialCommunityId,
       n.revisedSocialComponentId;

// RESULT 3
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 4
// ==================================================
// Query 0.4 - Drop old in-memory GDS projections.
CALL gds.graph.drop('graphStatsSocialGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// RESULT 4
// --------------------------------------------------
// droppedGraph
// No rows returned

// ==================================================
// QUERY 5
// ==================================================
// Query 0.5 - Create lookup indexes used by common queries.
CREATE INDEX person_name_idx IF NOT EXISTS
FOR (p:Person) ON (p.name);

// RESULT 5
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 6
// ==================================================
CREATE INDEX crime_date_idx IF NOT EXISTS
FOR (c:Crime) ON (c.date);

// RESULT 6
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 7
// ==================================================
CREATE INDEX location_address_idx IF NOT EXISTS
FOR (l:Location) ON (l.address);

// RESULT 7
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 8
// ==================================================
// SECTION 1: SCHEMA VALIDATION

// Query 1.1 - Node labels and counts.
MATCH (n)
RETURN labels(n)[0] AS label,
       count(n) AS count
ORDER BY count DESC;

// RESULT 8
// --------------------------------------------------
// label | count
// Crime | 28762
// Location | 14904
// PostCode | 14196
// Officer | 1000
// Vehicle | 1000
// PhoneCall | 534
// Person | 369
// Phone | 328
// Email | 328
// Area | 93
// Object | 7

// ==================================================
// QUERY 9
// ==================================================
// Query 1.2 - Relationship types and counts.
MATCH ()-[r]->()
RETURN type(r) AS relationshipType,
       count(r) AS count
ORDER BY count DESC;

// RESULT 9
// --------------------------------------------------
// relationshipType | count
// OCCURRED_AT | 28762
// INVESTIGATED_BY | 28762
// HAS_POSTCODE | 14904
// LOCATION_IN_AREA | 14904
// POSTCODE_IN_AREA | 14196
// INVOLVED_IN | 985
// KNOWS | 586
// CALLER | 534
// CALLED | 534
// CURRENT_ADDRESS | 368
// HAS_PHONE | 328
// HAS_EMAIL | 328
// KNOWS_SN | 241
// FAMILY_REL | 155
// KNOWS_PHONE | 118
// KNOWS_LW | 80
// PARTY_TO | 55
// PREDICTED_KNOWS_EXPLAINABLE | 4

// ==================================================
// QUERY 10
// ==================================================
// Query 1.3 - Full schema map: which labels each relationship connects.
MATCH (a)-[r]->(b)
RETURN labels(a) AS sourceLabels,
       type(r) AS relationshipType,
       labels(b) AS targetLabels,
       count(r) AS relationships,
       count(DISTINCT a) AS distinctSources,
       count(DISTINCT b) AS distinctTargets
ORDER BY relationships DESC, relationshipType;

// RESULT 10
// --------------------------------------------------
// sourceLabels | relationshipType | targetLabels | relationships | distinctSources | distinctTargets
// ["Crime"] | INVESTIGATED_BY | ["Officer"] | 28762 | 28762 | 1000
// ["Crime"] | OCCURRED_AT | ["Location"] | 28762 | 28762 | 13302
// ["Location"] | HAS_POSTCODE | ["PostCode"] | 14904 | 14904 | 14196
// ["Location"] | LOCATION_IN_AREA | ["Area"] | 14904 | 14904 | 92
// ["PostCode"] | POSTCODE_IN_AREA | ["Area"] | 14196 | 14196 | 81
// ["Vehicle"] | INVOLVED_IN | ["Crime"] | 978 | 978 | 978
// ["Person"] | KNOWS | ["Person"] | 586 | 233 | 312
// ["PhoneCall"] | CALLED | ["Phone"] | 534 | 534 | 236
// ["PhoneCall"] | CALLER | ["Phone"] | 534 | 534 | 236
// ["Person"] | CURRENT_ADDRESS | ["Location"] | 368 | 368 | 298
// ["Person"] | HAS_EMAIL | ["Email"] | 328 | 328 | 328
// ["Person"] | HAS_PHONE | ["Phone"] | 328 | 328 | 328
// ["Person"] | KNOWS_SN | ["Person"] | 241 | 38 | 241
// ["Person"] | FAMILY_REL | ["Person"] | 155 | 104 | 104
// ["Person"] | KNOWS_PHONE | ["Person"] | 118 | 118 | 118
// ["Person"] | KNOWS_LW | ["Person"] | 80 | 60 | 62
// ["Person"] | PARTY_TO | ["Crime"] | 55 | 29 | 55
// ["Object"] | INVOLVED_IN | ["Crime"] | 7 | 7 | 3
// ["Person"] | PREDICTED_KNOWS_EXPLAINABLE | ["Person"] | 4 | 3 | 4

// ==================================================
// QUERY 11
// ==================================================
// Query 1.4 - Person properties.
MATCH (p:Person)
RETURN keys(p) AS personProperties
LIMIT 1;

// RESULT 11
// --------------------------------------------------
// personProperties
// ["surname","nhs_no","name"]

// ==================================================
// QUERY 12
// ==================================================
// Query 1.5 - Crime properties.
MATCH (c:Crime)
RETURN keys(c) AS crimeProperties
LIMIT 1;

// RESULT 12
// --------------------------------------------------
// crimeProperties
// ["date","crimeTypeClass","id","type","last_outcome"]

// ==================================================
// QUERY 13
// ==================================================
// Query 1.6 - Location properties.
MATCH (l:Location)
RETURN keys(l) AS locationProperties
LIMIT 1;

// RESULT 13
// --------------------------------------------------
// locationProperties
// ["latitude","postcode","longitude","address"]

// ==================================================
// QUERY 14
// ==================================================
// Query 1.7 - Vehicle properties.
MATCH (v:Vehicle)
RETURN keys(v) AS vehicleProperties
LIMIT 1;

// RESULT 14
// --------------------------------------------------
// vehicleProperties
// ["model","reg","make","year"]

// ==================================================
// QUERY 15
// ==================================================
// Query 1.8 - Crime date range.
MATCH (c:Crime)
WHERE c.date IS NOT NULL
RETURN min(c.date) AS earliestCrimeDate,
       max(c.date) AS latestCrimeDate;

// RESULT 15
// --------------------------------------------------
// earliestCrimeDate | latestCrimeDate
// 1/08/2017 | 9/08/2017

// ==================================================
// QUERY 16
// ==================================================
// Query 1.9 - Crime types.
MATCH (c:Crime)
WHERE c.type IS NOT NULL
RETURN c.type AS crimeType,
       count(c) AS incidents
ORDER BY incidents DESC, crimeType;

// RESULT 16
// --------------------------------------------------
// crimeType | incidents
// Violence and sexual offences | 8765
// Public order | 4839
// Criminal damage and arson | 3587
// Burglary | 2807
// Vehicle crime | 2598
// Other theft | 2140
// Shoplifting | 1427
// Other crime | 651
// Robbery | 541
// Theft from the person | 423
// Bicycle theft | 414
// Drugs | 333
// Possession of weapons | 236

// ==================================================
// QUERY 17
// ==================================================
// Query 1.10 - Total graph size.
MATCH (n)
WITH count(n) AS totalNodes
MATCH ()-[r]->()
RETURN totalNodes,
       count(r) AS totalRelationships;

// RESULT 17
// --------------------------------------------------
// totalNodes | totalRelationships
// 61521 | 105844

// ==================================================
// QUERY 18
// ==================================================
// Query 1.11 - Degree summary across all stored nodes.
MATCH (n)
OPTIONAL MATCH (n)-[r]-()
WITH n, count(r) AS degree
RETURN avg(degree) AS averageDegree,
       min(degree) AS minimumDegree,
       max(degree) AS maximumDegree;

// RESULT 18
// --------------------------------------------------
// averageDegree | minimumDegree | maximumDegree
// 3.440906357178846 | 0 | 1321

// ==================================================
// QUERY 19
// ==================================================
// Query 1.12 - Isolated Person nodes.
MATCH (p:Person)
WHERE NOT (p)--()
RETURN count(p) AS isolatedPersons;

// RESULT 19
// --------------------------------------------------
// isolatedPersons
// 1

// ==================================================
// QUERY 20
// ==================================================
// SECTION 2: LINK VIABILITY AUDIT

// Query 2.1 - Which link families are strong enough to carry the project?
CALL {
    MATCH (p:Person)
    WITH count(p) AS sources
    MATCH (c:Crime)
    WITH sources, count(c) AS targets
    MATCH (p:Person)-[r:PARTY_TO]->(c:Crime)
    RETURN 'Person -> Crime' AS linkFamily,
           'PARTY_TO' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT p) AS coveredSources,
           count(DISTINCT c) AS coveredTargets,
           'Too sparse and sensitive for main prediction target.' AS reading

    UNION ALL

    MATCH (c:Crime)
    WITH count(c) AS sources
    MATCH (l:Location)
    WITH sources, count(l) AS targets
    MATCH (c:Crime)-[r:OCCURRED_AT]->(l:Location)
    RETURN 'Crime -> Location' AS linkFamily,
           'OCCURRED_AT' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT c) AS coveredSources,
           count(DISTINCT l) AS coveredTargets,
           'Strongest channel: complete crime coverage and clear hotspot interpretation.' AS reading

    UNION ALL

    MATCH (p:Person)
    WITH count(p) AS sources
    MATCH (q:Person)
    WITH sources, count(q) AS targets
    MATCH (p:Person)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]->(q:Person)
    RETURN 'Person -> Person' AS linkFamily,
           'KNOWS, KNOWS_SN, KNOWS_PHONE, KNOWS_LW, FAMILY_REL' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT p) AS coveredSources,
           count(DISTINCT q) AS coveredTargets,
           'Best GDS structure for centrality, communities, and graph ML social-link prediction.' AS reading

    UNION ALL

    MATCH (p:Person)
    WITH count(p) AS sources
    MATCH (l:Location)
    WITH sources, count(l) AS targets
    MATCH (p:Person)-[r:CURRENT_ADDRESS]->(l:Location)
    RETURN 'Person -> Location' AS linkFamily,
           'CURRENT_ADDRESS' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT p) AS coveredSources,
           count(DISTINCT l) AS coveredTargets,
           'Useful for context/exposure only. Not evidence of guilt.' AS reading

    UNION ALL

    MATCH (v:Vehicle)
    WITH count(v) AS sources
    MATCH (c:Crime)
    WITH sources, count(c) AS targets
    MATCH (v:Vehicle)-[r:INVOLVED_IN]->(c:Crime)
    RETURN 'Vehicle -> Crime' AS linkFamily,
           'INVOLVED_IN' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT v) AS coveredSources,
           count(DISTINCT c) AS coveredTargets,
           'Moderate descriptive context. Weak prediction target because vehicles rarely repeat.' AS reading

    UNION ALL

    MATCH (call:PhoneCall)
    WITH count(call) AS sources
    MATCH (phone:Phone)
    WITH sources, count(phone) AS targets
    MATCH (call:PhoneCall)-[r:CALLER|CALLED]->(phone:Phone)
    RETURN 'PhoneCall -> Phone' AS linkFamily,
           'CALLER, CALLED' AS relationshipTypes,
           sources,
           targets,
           count(r) AS observedLinks,
           count(DISTINCT call) AS coveredSources,
           count(DISTINCT phone) AS coveredTargets,
           'Useful communication context if linked back through Person -> Phone.' AS reading
}
RETURN linkFamily,
       relationshipTypes,
       observedLinks,
       coveredSources,
       sources,
       round(1000.0 * coveredSources / sources) / 10.0 AS sourceCoveragePercent,
       coveredTargets,
       targets,
       round(1000.0 * coveredTargets / targets) / 10.0 AS targetCoveragePercent,
       CASE
         WHEN sources * targets = 0 THEN null
         ELSE round(1000000.0 * observedLinks / (sources * targets)) / 10000.0
       END AS pairDensityPercent,
       reading
ORDER BY observedLinks DESC;

// RESULT 20
// --------------------------------------------------
// linkFamily | relationshipTypes | observedLinks | coveredSources | sources | sourceCoveragePercent | coveredTargets | targets | targetCoveragePercent | pairDensityPercent | reading
// Crime -> Location | OCCURRED_AT | 28762 | 28762 | 28762 | 100.0 | 13302 | 14904 | 89.3 | 0.0067 | Strongest channel: complete crime coverage and clear hotspot interpretation.
// Person -> Person | KNOWS, KNOWS_SN, KNOWS_PHONE, KNOWS_LW, FAMILY_REL | 1180 | 234 | 369 | 63.4 | 314 | 369 | 85.1 | 0.8666 | Best GDS structure for centrality, communities, and graph ML social-link prediction.
// PhoneCall -> Phone | CALLER, CALLED | 1068 | 534 | 534 | 100.0 | 236 | 328 | 72.0 | 0.6098 | Useful communication context if linked back through Person -> Phone.
// Vehicle -> Crime | INVOLVED_IN | 978 | 978 | 1000 | 97.8 | 978 | 28762 | 3.4 | 0.0034 | Moderate descriptive context. Weak prediction target because vehicles rarely repeat.
// Person -> Location | CURRENT_ADDRESS | 368 | 368 | 369 | 99.7 | 298 | 14904 | 2.0 | 0.0067 | Useful for context/exposure only. Not evidence of guilt.
// Person -> Crime | PARTY_TO | 55 | 29 | 369 | 7.9 | 55 | 28762 | 0.2 | 0.0005 | Too sparse and sensitive for main prediction target.

// ==================================================
// QUERY 21
// ==================================================
// Query 2.2 - Person-Crime sparsity in plain numbers.
MATCH (p:Person)
WITH count(p) AS persons
MATCH (c:Crime)
WITH persons, count(c) AS crimes
MATCH (:Person)-[:PARTY_TO]-(:Crime)
WITH persons, crimes, count(*) AS observedPartyTo
RETURN persons,
       crimes,
       observedPartyTo,
       persons * crimes AS possiblePersonCrimePairs,
       persons * crimes - observedPartyTo AS nonObservedPairs,
       round(1000000.0 * observedPartyTo / (persons * crimes)) / 10000.0 AS positiveClassPercent,
       'PARTY_TO should be treated as sparse observed context, not the main automated prediction target.' AS reading;

// RESULT 21
// --------------------------------------------------
// persons | crimes | observedPartyTo | possiblePersonCrimePairs | nonObservedPairs | positiveClassPercent | reading
// 369 | 28762 | 55 | 10613178 | 10613123 | 0.0005 | PARTY_TO should be treated as sparse observed context, not the main automated prediction target.

// ==================================================
// QUERY 22
// ==================================================
// Query 2.3 - Crimes with no observed Person link.
MATCH (c:Crime)
OPTIONAL MATCH (p:Person)-[:PARTY_TO]-(c)
WITH c, count(p) AS linkedPeople
RETURN count(c) AS crimes,
       sum(CASE WHEN linkedPeople > 0 THEN 1 ELSE 0 END) AS crimesWithObservedPersonLink,
       sum(CASE WHEN linkedPeople = 0 THEN 1 ELSE 0 END) AS crimesWithoutObservedPersonLink,
       round(1000.0 * sum(CASE WHEN linkedPeople > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS crimePersonCoveragePercent;

// RESULT 22
// --------------------------------------------------
// crimes | crimesWithObservedPersonLink | crimesWithoutObservedPersonLink | crimePersonCoveragePercent
// 28762 | 55 | 28707 | 0.2

// ==================================================
// QUERY 23
// ==================================================
// SECTION 3: CRIME-LOCATION HOTSPOTS AND AREA PROFILES

// Query 3.1 - Crime-location coverage.
MATCH (c:Crime)
OPTIONAL MATCH (c)-[:OCCURRED_AT]->(l:Location)
WITH c, count(l) AS locationLinks
RETURN count(c) AS crimes,
       sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) AS crimesWithLocation,
       sum(CASE WHEN locationLinks = 0 THEN 1 ELSE 0 END) AS crimesWithoutLocation,
       round(1000.0 * sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS locationCoveragePercent;

// RESULT 23
// --------------------------------------------------
// crimes | crimesWithLocation | crimesWithoutLocation | locationCoveragePercent
// 28762 | 28762 | 0 | 100.0

// ==================================================
// QUERY 24
// ==================================================
// Query 3.2 - Top repeat locations by incident count.
MATCH (c:Crime)-[:OCCURRED_AT]->(l:Location)
WITH l.address AS location,
     count(c) AS incidents,
     count(DISTINCT c.type) AS distinctCrimeTypes,
     collect(DISTINCT c.type)[0..6] AS exampleCrimeTypes
RETURN location,
       incidents,
       distinctCrimeTypes,
       exampleCrimeTypes,
       CASE
         WHEN incidents >= 100 THEN 'Very high repeat-place priority'
         WHEN incidents >= 30 THEN 'High repeat-place priority'
         ELSE 'Moderate repeat-place priority'
       END AS hotspotReading
ORDER BY incidents DESC, distinctCrimeTypes DESC, location
LIMIT 20;

// RESULT 24
// --------------------------------------------------
// location | incidents | distinctCrimeTypes | exampleCrimeTypes | hotspotReading
// Parking Area | 811 | 13 | ["Drugs","Public order","Other theft","Theft from the person","Violence and sexual offences","Criminal damage and arson"] | Very high repeat-place priority
// Supermarket | 614 | 13 | ["Shoplifting","Violence and sexual offences","Criminal damage and arson","Public order","Other crime","Theft from the person"] | Very high repeat-place priority
// Shopping Area | 594 | 13 | ["Shoplifting","Burglary","Other theft","Theft from the person","Public order","Robbery"] | Very high repeat-place priority
// Nightclub | 336 | 13 | ["Public order","Other theft","Burglary","Vehicle crime","Shoplifting","Drugs"] | Very high repeat-place priority
// Petrol Station | 331 | 13 | ["Other theft","Public order","Vehicle crime","Burglary","Robbery","Violence and sexual offences"] | Very high repeat-place priority
// Sports/Recreation Area | 169 | 12 | ["Criminal damage and arson","Other theft","Burglary","Public order","Violence and sexual offences","Vehicle crime"] | Very high repeat-place priority
// Piccadilly | 166 | 11 | ["Public order","Violence and sexual offences","Theft from the person","Other crime","Robbery","Shoplifting"] | Very high repeat-place priority
// Pedestrian Subway | 115 | 13 | ["Other crime","Other theft","Robbery","Violence and sexual offences","Drugs","Public order"] | Very high repeat-place priority
// Hospital | 113 | 11 | ["Criminal damage and arson","Vehicle crime","Violence and sexual offences","Public order","Other crime","Other theft"] | Very high repeat-place priority
// Bus/Coach Station | 100 | 11 | ["Violence and sexual offences","Public order","Bicycle theft","Theft from the person","Other theft","Burglary"] | Very high repeat-place priority
// Further/Higher Educational Building | 74 | 11 | ["Robbery","Public order","Violence and sexual offences","Vehicle crime","Shoplifting","Other crime"] | High repeat-place priority
// Police Station | 73 | 12 | ["Violence and sexual offences","Criminal damage and arson","Vehicle crime","Possession of weapons","Burglary","Public order"] | High repeat-place priority
// Prison | 73 | 6 | ["Violence and sexual offences","Other crime","Public order","Drugs","Vehicle crime","Robbery"] | High repeat-place priority
// Theatre/Concert Hall | 54 | 10 | ["Burglary","Criminal damage and arson","Other theft","Public order","Vehicle crime","Violence and sexual offences"] | High repeat-place priority
// Park/Open Space | 49 | 10 | ["Other theft","Public order","Vehicle crime","Violence and sexual offences","Criminal damage and arson","Bicycle theft"] | High repeat-place priority
// 182 Waterson Avenue | 35 | 4 | ["Violence and sexual offences","Other theft","Drugs","Bicycle theft"] | High repeat-place priority
// 43 Walker's Croft | 35 | 3 | ["Public order","Violence and sexual offences","Other theft"] | High repeat-place priority
// Conference/Exhibition Centre | 31 | 7 | ["Violence and sexual offences","Other theft","Bicycle theft","Shoplifting","Public order","Criminal damage and arson"] | High repeat-place priority
// 136 A5185 | 30 | 7 | ["Public order","Other theft","Criminal damage and arson","Robbery","Violence and sexual offences","Shoplifting"] | High repeat-place priority
// 185 Albion Street | 29 | 8 | ["Violence and sexual offences","Other theft","Criminal damage and arson","Burglary","Public order","Robbery"] | Moderate repeat-place priority

// ==================================================
// QUERY 25
// ==================================================
// Query 3.3 - Top areas by crime volume and crime-type diversity.
MATCH (c:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)
RETURN elementId(a) AS areaId,
       count(c) AS incidents,
       count(DISTINCT c.type) AS distinctCrimeTypes
ORDER BY incidents DESC, distinctCrimeTypes DESC
LIMIT 20;

// RESULT 25
// --------------------------------------------------
// areaId | incidents | distinctCrimeTypes
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17012 | 975 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 814 | 12
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16992 | 766 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17079 | 699 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17102 | 623 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17195 | 562 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16983 | 562 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17004 | 562 | 12
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17124 | 540 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17091 | 509 | 12
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16963 | 507 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:61511 | 505 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 497 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17029 | 490 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16996 | 490 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16994 | 466 | 12
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17002 | 457 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16976 | 454 | 13
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17000 | 436 | 13

// ==================================================
// QUERY 26
// ==================================================
// Query 3.4 - Area crime-type profiles.
MATCH (c:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)
WITH elementId(a) AS areaId,
     c.type AS crimeType,
     count(c) AS incidents
ORDER BY areaId, incidents DESC, crimeType
WITH areaId,
     sum(incidents) AS totalIncidents,
     collect(crimeType + ' (' + toString(incidents) + ')')[0..5] AS dominantCrimeTypes
RETURN areaId,
       totalIncidents,
       dominantCrimeTypes,
       'Area profile supports place-based prioritisation, not person accusation.' AS areaReading
ORDER BY totalIncidents DESC
LIMIT 20;

// RESULT 26
// --------------------------------------------------
// areaId | totalIncidents | dominantCrimeTypes | areaReading
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17012 | 975 | ["Violence and sexual offences (249)","Public order (129)","Theft from the person (123)","Other theft (113)","Vehicle crime (79)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | ["Violence and sexual offences (242)","Public order (182)","Criminal damage and arson (92)","Burglary (84)","Other theft (69)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 814 | ["Violence and sexual offences (223)","Public order (149)","Criminal damage and arson (117)","Vehicle crime (94)","Burglary (93)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16992 | 766 | ["Violence and sexual offences (234)","Public order (184)","Criminal damage and arson (113)","Vehicle crime (59)","Burglary (55)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17079 | 699 | ["Violence and sexual offences (187)","Public order (174)","Criminal damage and arson (119)","Burglary (51)","Other theft (51)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17102 | 623 | ["Violence and sexual offences (204)","Public order (111)","Criminal damage and arson (80)","Burglary (53)","Shoplifting (49)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17195 | 562 | ["Violence and sexual offences (197)","Public order (124)","Criminal damage and arson (72)","Burglary (50)","Vehicle crime (34)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17004 | 562 | ["Violence and sexual offences (195)","Public order (93)","Criminal damage and arson (86)","Burglary (55)","Vehicle crime (46)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16983 | 562 | ["Violence and sexual offences (144)","Public order (99)","Burglary (87)","Criminal damage and arson (58)","Vehicle crime (54)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17124 | 540 | ["Violence and sexual offences (176)","Public order (100)","Criminal damage and arson (98)","Other theft (40)","Vehicle crime (34)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17091 | 509 | ["Violence and sexual offences (148)","Public order (79)","Criminal damage and arson (78)","Shoplifting (52)","Burglary (49)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16963 | 507 | ["Violence and sexual offences (181)","Public order (86)","Criminal damage and arson (64)","Shoplifting (52)","Other theft (35)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:61511 | 505 | ["Violence and sexual offences (178)","Public order (82)","Criminal damage and arson (56)","Burglary (46)","Other theft (37)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 497 | ["Violence and sexual offences (107)","Public order (86)","Burglary (83)","Vehicle crime (67)","Criminal damage and arson (54)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17029 | 490 | ["Violence and sexual offences (175)","Criminal damage and arson (74)","Public order (71)","Burglary (38)","Vehicle crime (38)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16996 | 490 | ["Violence and sexual offences (154)","Public order (89)","Burglary (63)","Vehicle crime (49)","Criminal damage and arson (46)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16994 | 466 | ["Violence and sexual offences (159)","Public order (88)","Criminal damage and arson (63)","Vehicle crime (48)","Burglary (31)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17002 | 457 | ["Violence and sexual offences (168)","Public order (88)","Criminal damage and arson (43)","Vehicle crime (41)","Burglary (39)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16976 | 454 | ["Violence and sexual offences (166)","Public order (68)","Criminal damage and arson (58)","Vehicle crime (37)","Burglary (36)"] | Area profile supports place-based prioritisation, not person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17000 | 436 | ["Violence and sexual offences (163)","Criminal damage and arson (74)","Burglary (43)","Vehicle crime (37)","Other theft (36)"] | Area profile supports place-based prioritisation, not person accusation.

// ==================================================
// QUERY 27
// ==================================================
// Query 3.5 - Crime-to-crime repeat patterns at the same location and type.
MATCH (c1:Crime)-[:OCCURRED_AT]->(l:Location)<-[:OCCURRED_AT]-(c2:Crime)
WHERE elementId(c1) < elementId(c2)
  AND c1.type IS NOT NULL
  AND c1.type = c2.type
WITH l.address AS location,
     c1.type AS crimeType,
     count(*) AS sameTypeCrimePairs
RETURN location,
       crimeType,
       sameTypeCrimePairs,
       'Historical repeat pattern only.' AS patternReading
ORDER BY sameTypeCrimePairs DESC
LIMIT 20;

// RESULT 27
// --------------------------------------------------
// location | crimeType | sameTypeCrimePairs | patternReading
// Shopping Area | Shoplifting | 1405 | Historical repeat pattern only.
// Piccadilly | Violence and sexual offences | 1081 | Historical repeat pattern only.
// Supermarket | Shoplifting | 511 | Historical repeat pattern only.
// 43 Walker's Croft | Violence and sexual offences | 496 | Historical repeat pattern only.
// 182 Waterson Avenue | Violence and sexual offences | 435 | Historical repeat pattern only.
// Bus/Coach Station | Shoplifting | 367 | Historical repeat pattern only.
// Parking Area | Violence and sexual offences | 359 | Historical repeat pattern only.
// Piccadilly | Public order | 325 | Historical repeat pattern only.
// Prison | Violence and sexual offences | 308 | Historical repeat pattern only.
// Nightclub | Violence and sexual offences | 301 | Historical repeat pattern only.
// Shopping Area | Public order | 286 | Historical repeat pattern only.
// Piccadilly | Drugs | 253 | Historical repeat pattern only.
// Piccadilly | Robbery | 190 | Historical repeat pattern only.
// Prison | Other crime | 148 | Historical repeat pattern only.
// Shopping Area | Violence and sexual offences | 148 | Historical repeat pattern only.
// Shopping Area | Other theft | 144 | Historical repeat pattern only.
// Parking Area | Other theft | 144 | Historical repeat pattern only.
// Hospital | Violence and sexual offences | 142 | Historical repeat pattern only.
// Nightclub | Theft from the person | 129 | Historical repeat pattern only.
// Supermarket | Violence and sexual offences | 120 | Historical repeat pattern only.

// ==================================================
// QUERY 28
// ==================================================
// SECTION 4: PERSON SOCIAL GRAPH GDS ANALYTICS

// Query 4.1 - Person-Person relationship mix.
MATCH (:Person)-[r]->(:Person)
RETURN type(r) AS relationshipType,
       count(r) AS directedLinks,
       count(DISTINCT startNode(r)) AS distinctSources,
       count(DISTINCT endNode(r)) AS distinctTargets
ORDER BY directedLinks DESC;

// RESULT 28
// --------------------------------------------------
// relationshipType | directedLinks | distinctSources | distinctTargets
// KNOWS | 586 | 233 | 312
// KNOWS_SN | 241 | 38 | 241
// FAMILY_REL | 155 | 104 | 104
// KNOWS_PHONE | 118 | 118 | 118
// KNOWS_LW | 80 | 60 | 62
// PREDICTED_KNOWS_EXPLAINABLE | 4 | 3 | 4

// ==================================================
// QUERY 29
// ==================================================
// Query 4.2 - Social coverage among Person nodes.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN count(p) AS people,
       sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) AS sociallyConnectedPeople,
       sum(CASE WHEN socialDegree = 0 THEN 1 ELSE 0 END) AS sociallyIsolatedPeople,
       round(1000.0 * sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS sociallyConnectedPercent;

// RESULT 29
// --------------------------------------------------
// people | sociallyConnectedPeople | sociallyIsolatedPeople | sociallyConnectedPercent
// 369 | 346 | 23 | 93.8

// ==================================================
// QUERY 30
// ==================================================
// Query 4.3 - Person social degree distribution.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN socialDegree,
       count(p) AS people
ORDER BY socialDegree DESC
LIMIT 25;

// RESULT 30
// --------------------------------------------------
// socialDegree | people
// 26 | 1
// 24 | 1
// 23 | 1
// 22 | 1
// 21 | 1
// 20 | 8
// 19 | 1
// 18 | 4
// 17 | 3
// 16 | 8
// 15 | 3
// 14 | 6
// 13 | 1
// 12 | 7
// 10 | 19
// 8 | 62
// 7 | 4
// 6 | 62
// 4 | 97
// 3 | 2
// 2 | 54
// 0 | 23

// ==================================================
// QUERY 31
// ==================================================
// Query 4.4 - Project the Person social graph into GDS memory.
CALL gds.graph.project(
    'graphStatsSocialGraph',
    'Person',
    {
        KNOWS: {orientation: 'UNDIRECTED'},
        KNOWS_SN: {orientation: 'UNDIRECTED'},
        KNOWS_PHONE: {orientation: 'UNDIRECTED'},
        KNOWS_LW: {orientation: 'UNDIRECTED'},
        FAMILY_REL: {orientation: 'UNDIRECTED'}
    }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName,
       nodeCount,
       relationshipCount,
       CASE
         WHEN nodeCount <= 1 THEN 0.0
         ELSE round(1000000.0 * relationshipCount / (nodeCount * (nodeCount - 1))) / 1000000.0
       END AS approximateDensity;

// RESULT 31
// --------------------------------------------------
// graphName | nodeCount | relationshipCount | approximateDensity
// graphStatsSocialGraph | 369 | 2360 | 0.01738

// ==================================================
// QUERY 32
// ==================================================
// Query 4.5 - Degree centrality: most directly connected people.
CALL gds.degree.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS degreeConnections
ORDER BY degreeConnections DESC, person
LIMIT 15;

// RESULT 32
// --------------------------------------------------
// person | degreeConnections
// Amanda Alexander | 26.0
// Annie Duncan | 24.0
// Andrew Foster | 23.0
// Bruce Baker | 22.0
// Brian Austin | 21.0
// Alan Hicks | 20.0
// Andrea George | 20.0
// Andrea Phillips | 20.0
// Ann Fox | 20.0
// Anne Rice | 20.0
// Antonio Hernandez | 20.0
// Arthur Willis | 20.0
// Benjamin Hamilton | 20.0
// Bonnie Gilbert | 19.0
// Adam Bradley | 18.0

// ==================================================
// QUERY 33
// ==================================================
// Query 4.6 - PageRank: socially influential people.
CALL gds.pageRank.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS pageRankScore
ORDER BY pageRankScore DESC, person
LIMIT 15;

// RESULT 33
// --------------------------------------------------
// person | pageRankScore
// Amanda Alexander | 3.2667833583686665
// Annie Duncan | 2.89678603353112
// Andrew Foster | 2.894794341135535
// Bruce Baker | 2.822567072978813
// Anne Rice | 2.7969665137210935
// Andrea Phillips | 2.7506492488498555
// Brian Austin | 2.699913308714905
// Alan Hicks | 2.681403581558681
// Benjamin Hamilton | 2.6585626233061443
// Annie George | 2.5970715145727956
// Ann Fox | 2.5931305477413673
// Andrea George | 2.5825806428164855
// Antonio Hernandez | 2.53466972433342
// Andrea George | 2.444045418874138
// Bonnie Gilbert | 2.4257982846647392

// ==================================================
// QUERY 34
// ==================================================
// Query 4.7 - Betweenness centrality: social bridges.
CALL gds.betweenness.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS betweennessScore
ORDER BY betweennessScore DESC, person
LIMIT 15;

// RESULT 34
// --------------------------------------------------
// person | betweennessScore
// Annie Duncan | 5265.919100301027
// Ann Fox | 5113.770628757344
// Amanda Alexander | 4592.153661401946
// Bruce Baker | 4178.821491582495
// Andrew Foster | 3747.2121510395127
// Anne Rice | 3421.5997927227913
// Alan Hicks | 3349.5212320432584
// Amy Murphy | 3296.8468390964053
// Adam Bradley | 3265.0343553257662
// Arthur Willis | 3244.145328701536
// Andrea George | 3235.129968441948
// Andrea Montgomery | 3201.492146465926
// Andrea George | 3187.636532927497
// Amanda Robertson | 3087.717505856972
// Andrea Phillips | 2910.476804892748

// ==================================================
// QUERY 35
// ==================================================
// Query 4.8 - Louvain community detection on the social graph.
CALL gds.louvain.write(
    'graphStatsSocialGraph',
    {writeProperty: 'revisedSocialCommunityId'}
)
YIELD communityCount, modularity
RETURN communityCount,
       modularity,
       CASE
         WHEN modularity >= 0.5 THEN 'Strong community structure'
         WHEN modularity >= 0.3 THEN 'Moderate community structure'
         ELSE 'Weak community structure'
       END AS communityReading;

// RESULT 35
// --------------------------------------------------
// communityCount | modularity | communityReading
// 41 | 0.6709580580293019 | Strong community structure

// ==================================================
// QUERY 36
// ==================================================
// Query 4.9 - Largest social communities.
MATCH (p:Person)
WHERE p.revisedSocialCommunityId IS NOT NULL
WITH p.revisedSocialCommunityId AS communityId,
     collect(p.name + ' ' + coalesce(p.surname, '')) AS members,
     count(p) AS people
RETURN communityId,
       people,
       members[0..8] AS exampleMembers
ORDER BY people DESC, communityId
LIMIT 15;

// RESULT 36
// --------------------------------------------------
// communityId | people | exampleMembers
// 249 | 32 | ["Mary Peters","Irene Austin","Harry Garrett","Eugene Ferguson","Douglas Cole","Wanda Webb","Kevin Hawkins","Jennifer Gray"]
// 351 | 32 | ["Todd Hamilton","Benjamin Hamilton","Diane Cox","Ryan Castillo","Dennis Ford","Justin Arnold","Donna Jordan","Norma Payne"]
// 328 | 31 | ["Scott Kelly","Rose Crawford","Christine Brown","Heather Howard","Rachel Bradley","Rachel Hunter","Diane Wagner","Judith Moore"]
// 122 | 28 | ["Mildred Kelly","Stephen Perez","Lawrence Warren","Paul Nguyen","Stephanie Lynch","Ashley Bennett","Janice Coleman","Patrick Sanders"]
// 226 | 26 | ["Nancy Campbell","Todd Garcia","Rachel Turner","Ashley Robertson","Carl Hayes","Rose Parker","Phyllis Murray","Joshua Black"]
// 197 | 24 | ["Peter Burns","Craig Gordon","Bobby Thompson","Brian Austin","George Grant","Jeremy Barnes","Richard Hanson","Eric Black"]
// 329 | 23 | ["Thomas Harrison","Timothy Garza","Larry Turner","Phillip Carr","Jonathan Russell","Barbara Moreno","Jessica Foster","Phillip Perry"]
// 237 | 22 | ["Phillip Myers","Mary Young","Stephanie Hughes","Pamela Gibson","Maria Hughes","Lawrence Stephens","Raymond Williamson","Jennifer Rogers"]
// 331 | 22 | ["Sharon White","Anne Nguyen","Carlos Chavez","Melissa Warren","Paul Arnold","Philip Scott","Linda Baker","Rebecca Long"]
// 188 | 20 | ["Antonio Washington","Gregory Rodriguez","Louis Parker","Kathleen Rogers","Brenda West","Henry Coleman","Douglas Martin","Jacqueline Holmes"]
// 162 | 16 | ["Denise Rodriguez","Nicholas Mason","Rebecca Lee","Jeffrey Lewis","Alice Mcdonald","Randy Edwards","Matthew Phillips","Annie George"]
// 251 | 16 | ["Philip Mason","Dennis Mcdonald","Sandra Ruiz","David Mills","Kelly Peterson","Amanda Robertson","Richard Coleman","Elizabeth Anderson"]
// 91 | 15 | ["Michael Mason","Lois Hernandez","Lillian Porter","Richard Green","Barbara Torres","Nicholas Woods","Ann Fox","Carolyn Hawkins"]
// 215 | 15 | ["Jerry Fernandez","Stephen Lee","Gary Lane","Anne Rice","Johnny Fox","Karen Evans","Billy Boyd","Denise Butler"]
// 239 | 10 | ["William Dixon","Raymond Walker","Kathleen Peters","Diana Murray","Kathy Wheeler","Alan Ward","Jack Powell","Phillip Williamson"]

// ==================================================
// QUERY 37
// ==================================================
// Query 4.10 - Social communities with observed crime context.
MATCH (p:Person)
WHERE p.revisedSocialCommunityId IS NOT NULL
OPTIONAL MATCH (p)-[:PARTY_TO]-(c:Crime)
WITH p.revisedSocialCommunityId AS communityId,
     p.name + ' ' + coalesce(p.surname, '') AS memberName,
     count(c) AS observedCrimeLinks,
     collect(DISTINCT c.type) AS personCrimeTypes
WITH communityId,
     collect(memberName)[0..8] AS exampleMembers,
     count(memberName) AS people,
     sum(CASE WHEN observedCrimeLinks > 0 THEN 1 ELSE 0 END) AS crimeLinkedPeople,
     sum(observedCrimeLinks) AS totalObservedPartyToLinks,
     collect(personCrimeTypes) AS crimeTypeLists
UNWIND crimeTypeLists AS crimeTypeList
UNWIND crimeTypeList AS crimeType
WITH communityId,
     exampleMembers,
     people,
     crimeLinkedPeople,
     totalObservedPartyToLinks,
     collect(DISTINCT crimeType)[0..6] AS crimeTypes
WHERE totalObservedPartyToLinks > 0
RETURN communityId,
       people,
       crimeLinkedPeople,
       totalObservedPartyToLinks,
       round(1000.0 * crimeLinkedPeople / people) / 10.0 AS crimeLinkedPeoplePercent,
       crimeTypes,
       exampleMembers,
       'Community-level context is stronger and safer than individual automatic accusation.' AS reading
ORDER BY totalObservedPartyToLinks DESC, crimeLinkedPeoplePercent DESC
LIMIT 15;

// RESULT 37
// --------------------------------------------------
// communityId | people | crimeLinkedPeople | totalObservedPartyToLinks | crimeLinkedPeoplePercent | crimeTypes | exampleMembers | reading
// 239 | 10 | 8 | 29 | 80.0 | ["Drugs","Vehicle crime","Robbery"] | ["William Dixon","Raymond Walker","Kathleen Peters","Diana Murray","Kathy Wheeler","Alan Ward","Jack Powell","Phillip Williamson"] | Community-level context is stronger and safer than individual automatic accusation.
// 237 | 22 | 6 | 9 | 27.3 | ["Violence and sexual offences","Criminal damage and arson","Burglary","Vehicle crime","Robbery"] | ["Phillip Myers","Mary Young","Stephanie Hughes","Pamela Gibson","Maria Hughes","Lawrence Stephens","Raymond Williamson","Jennifer Rogers"] | Community-level context is stronger and safer than individual automatic accusation.
// 331 | 22 | 3 | 5 | 13.6 | ["Robbery","Public order"] | ["Sharon White","Anne Nguyen","Carlos Chavez","Melissa Warren","Paul Arnold","Philip Scott","Linda Baker","Rebecca Long"] | Community-level context is stronger and safer than individual automatic accusation.
// 226 | 26 | 3 | 3 | 11.5 | ["Criminal damage and arson","Burglary","Vehicle crime"] | ["Nancy Campbell","Todd Garcia","Rachel Turner","Ashley Robertson","Carl Hayes","Rose Parker","Phyllis Murray","Joshua Black"] | Community-level context is stronger and safer than individual automatic accusation.
// 351 | 32 | 3 | 3 | 9.4 | ["Robbery","Theft from the person"] | ["Todd Hamilton","Benjamin Hamilton","Diane Cox","Ryan Castillo","Dennis Ford","Justin Arnold","Donna Jordan","Norma Payne"] | Community-level context is stronger and safer than individual automatic accusation.
// 251 | 16 | 2 | 2 | 12.5 | ["Violence and sexual offences","Public order"] | ["Philip Mason","Dennis Mcdonald","Sandra Ruiz","David Mills","Kelly Peterson","Amanda Robertson","Richard Coleman","Elizabeth Anderson"] | Community-level context is stronger and safer than individual automatic accusation.
// 162 | 16 | 1 | 1 | 6.3 | ["Violence and sexual offences"] | ["Denise Rodriguez","Nicholas Mason","Rebecca Lee","Jeffrey Lewis","Alice Mcdonald","Randy Edwards","Matthew Phillips","Annie George"] | Community-level context is stronger and safer than individual automatic accusation.
// 122 | 28 | 1 | 1 | 3.6 | ["Violence and sexual offences"] | ["Mildred Kelly","Stephen Perez","Lawrence Warren","Paul Nguyen","Stephanie Lynch","Ashley Bennett","Janice Coleman","Patrick Sanders"] | Community-level context is stronger and safer than individual automatic accusation.
// 328 | 31 | 1 | 1 | 3.2 | ["Violence and sexual offences"] | ["Scott Kelly","Rose Crawford","Christine Brown","Heather Howard","Rachel Bradley","Rachel Hunter","Diane Wagner","Judith Moore"] | Community-level context is stronger and safer than individual automatic accusation.
// 249 | 32 | 1 | 1 | 3.1 | ["Vehicle crime"] | ["Mary Peters","Irene Austin","Harry Garrett","Eugene Ferguson","Douglas Cole","Wanda Webb","Kevin Hawkins","Jennifer Gray"] | Community-level context is stronger and safer than individual automatic accusation.

// ==================================================
// QUERY 38
// ==================================================
// Query 4.11 - Weakly connected components on the social graph.
CALL gds.wcc.write(
    'graphStatsSocialGraph',
    {writeProperty: 'revisedSocialComponentId'}
)
YIELD componentCount, componentDistribution
RETURN componentCount,
       componentDistribution;

// RESULT 38
// --------------------------------------------------
// componentCount | componentDistribution
// 26 | {"p1":1,"p5":1,"max":342,"p90":2,"p50":1,"p95":2,"p10":1,"p75":1,"p99":342,"p25":1,"min":1,"mean":14.192307692307692,"p999":342}

// ==================================================
// QUERY 39
// ==================================================
// Query 4.12 - Social component size distribution.
MATCH (p:Person)
WHERE p.revisedSocialComponentId IS NOT NULL
RETURN p.revisedSocialComponentId AS componentId,
       count(p) AS people
ORDER BY people DESC
LIMIT 15;

// RESULT 39
// --------------------------------------------------
// componentId | people
// 0 | 342
// 95 | 2
// 86 | 2
// 25 | 1
// 39 | 1
// 40 | 1
// 38 | 1
// 82 | 1
// 67 | 1
// 88 | 1
// 94 | 1
// 26 | 1
// 96 | 1
// 102 | 1
// 22 | 1

// ==================================================
// QUERY 40
// ==================================================
// Query 4.13 - Example shortest path between two people.
MATCH (a:Person {name: 'Todd'})
WITH a LIMIT 1
MATCH (b:Person {name: 'Rachel'})
WITH a, b LIMIT 1
MATCH path = shortestPath((a)-[*..10]-(b))
RETURN path;

// RESULT 40
// --------------------------------------------------
// path
// [{"revisedSocialCommunityId":351,"revisedSocialComponentId":0,"nhs_no":"117-66-8129","surname":"Hamilton","name":"Todd"},{"rel_type":"SIBLING"},{"revisedSocialCommunityId":351,"revisedSocialComponentId":0,"nhs_no":"991-70-5333","surname":"Hamilton","name":"Benjamin"},{},{"revisedSocialCommunityId":226,"revisedSocialComponentId":0,"nhs_no":"690-09-2036","surname":"Murray","name":"Phyllis"},{},{"revisedSocialCommunityId":226,"revisedSocialComponentId":0,"nhs_no":"543-43-9738","surname":"Weaver","name":"Wanda"},{},{"revisedSocialCommunityId":226,"revisedSocialComponentId":0,"nhs_no":"556-15-9637","surname":"Mccoy","name":"Angela"},{},{"revisedSocialCommunityId":226,"revisedSocialComponentId":0,"nhs_no":"595-90-8809","surname":"Garcia","name":"Todd"},{},{"revisedSocialCommunityId":226,"revisedSocialComponentId":0,"nhs_no":"556-65-1110","surname":"Turner","name":"Rachel"}]

// ==================================================
// QUERY 41
// ==================================================
// SECTION 5: PERSON-LOCATION, VEHICLE, AND PHONE CONTEXT

// Query 5.1 - Person current-address coverage.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:CURRENT_ADDRESS]->(l:Location)
WITH p, count(l) AS addressLinks
RETURN count(p) AS people,
       sum(CASE WHEN addressLinks > 0 THEN 1 ELSE 0 END) AS peopleWithCurrentAddress,
       sum(CASE WHEN addressLinks = 0 THEN 1 ELSE 0 END) AS peopleWithoutCurrentAddress,
       round(1000.0 * sum(CASE WHEN addressLinks > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS addressCoveragePercent;

// RESULT 41
// --------------------------------------------------
// people | peopleWithCurrentAddress | peopleWithoutCurrentAddress | addressCoveragePercent
// 369 | 368 | 1 | 99.7

// ==================================================
// QUERY 42
// ==================================================
// Query 5.2 - People whose current address also appears as a crime location.
MATCH (p:Person)-[:CURRENT_ADDRESS]->(l:Location)
OPTIONAL MATCH (c:Crime)-[:OCCURRED_AT]->(l)
WITH p, l, count(c) AS incidentsAtAddress, collect(DISTINCT c.type)[0..6] AS crimeTypes
WHERE incidentsAtAddress > 0
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       l.address AS currentAddress,
       incidentsAtAddress,
       crimeTypes,
       'Context only: address exposure is not evidence of guilt.' AS reading
ORDER BY incidentsAtAddress DESC, person
LIMIT 25;

// RESULT 42
// --------------------------------------------------
// person | currentAddress | incidentsAtAddress | crimeTypes | reading
// Harry Sims | 181 Cayton Street | 9 | ["Violence and sexual offences","Theft from the person","Criminal damage and arson","Public order","Burglary"] | Context only: address exposure is not evidence of guilt.
// Nicholas Watson | 181 Cayton Street | 9 | ["Violence and sexual offences","Theft from the person","Criminal damage and arson","Public order","Burglary"] | Context only: address exposure is not evidence of guilt.
// Patricia Carr | 48 Cheapside Square | 8 | ["Public order","Shoplifting","Burglary"] | Context only: address exposure is not evidence of guilt.
// Anne Nguyen | 146 Gloucester Street | 6 | ["Burglary","Violence and sexual offences","Robbery","Theft from the person"] | Context only: address exposure is not evidence of guilt.
// Craig Marshall | 51 Henry Street | 6 | ["Violence and sexual offences","Criminal damage and arson","Other theft","Public order"] | Context only: address exposure is not evidence of guilt.
// Dorothy Hall | 13 Brindale Road | 6 | ["Violence and sexual offences","Robbery","Criminal damage and arson"] | Context only: address exposure is not evidence of guilt.
// Frances Chapman | 111 Blackshaw Lane | 6 | ["Criminal damage and arson","Other theft","Violence and sexual offences","Possession of weapons"] | Context only: address exposure is not evidence of guilt.
// Gary Hawkins | 49 Pelham Street | 6 | ["Other theft","Vehicle crime","Violence and sexual offences"] | Context only: address exposure is not evidence of guilt.
// Kathy Harper | 13 Brindale Road | 6 | ["Violence and sexual offences","Robbery","Criminal damage and arson"] | Context only: address exposure is not evidence of guilt.
// Kelly Fields | 111 Blackshaw Lane | 6 | ["Criminal damage and arson","Other theft","Violence and sexual offences","Possession of weapons"] | Context only: address exposure is not evidence of guilt.
// Ruth Hansen | 13 Brindale Road | 6 | ["Violence and sexual offences","Robbery","Criminal damage and arson"] | Context only: address exposure is not evidence of guilt.
// Barbara Torres | 157 Carrill Grove | 5 | ["Violence and sexual offences","Other theft","Vehicle crime","Public order","Criminal damage and arson"] | Context only: address exposure is not evidence of guilt.
// Daniel Stanley | 79 Gaythorn Street | 5 | ["Criminal damage and arson","Public order","Other theft","Theft from the person","Vehicle crime"] | Context only: address exposure is not evidence of guilt.
// Gloria Owens | 37 Teer Street | 5 | ["Robbery","Public order","Vehicle crime","Violence and sexual offences"] | Context only: address exposure is not evidence of guilt.
// Heather Howard | 33 Avon Road | 5 | ["Violence and sexual offences","Public order"] | Context only: address exposure is not evidence of guilt.
// Jeffrey Campbell | 37 Teer Street | 5 | ["Robbery","Public order","Vehicle crime","Violence and sexual offences"] | Context only: address exposure is not evidence of guilt.
// Jeffrey Nguyen | 2 Nursery Lane | 5 | ["Violence and sexual offences","Public order","Other theft","Shoplifting"] | Context only: address exposure is not evidence of guilt.
// Lillian Porter | 155 Olanyian Drive | 5 | ["Other theft","Vehicle crime","Bicycle theft"] | Context only: address exposure is not evidence of guilt.
// Lois Hernandez | 155 Olanyian Drive | 5 | ["Other theft","Vehicle crime","Bicycle theft"] | Context only: address exposure is not evidence of guilt.
// Patricia Wheeler | 26 Calderburn Close | 5 | ["Public order","Criminal damage and arson","Violence and sexual offences","Vehicle crime"] | Context only: address exposure is not evidence of guilt.
// Richard Green | 157 Carrill Grove | 5 | ["Violence and sexual offences","Other theft","Vehicle crime","Public order","Criminal damage and arson"] | Context only: address exposure is not evidence of guilt.
// Amy Watson | 163 Sandpiper Close | 4 | ["Criminal damage and arson","Public order","Possession of weapons"] | Context only: address exposure is not evidence of guilt.
// Christopher Oliver | 148 Tig Fold Road | 4 | ["Violence and sexual offences","Criminal damage and arson","Public order","Bicycle theft"] | Context only: address exposure is not evidence of guilt.
// Denise Rodriguez | 27 Maiden Close | 4 | ["Shoplifting","Criminal damage and arson","Other theft"] | Context only: address exposure is not evidence of guilt.
// Kathleen Rogers | 88 Broadley Avenue | 4 | ["Violence and sexual offences"] | Context only: address exposure is not evidence of guilt.

// ==================================================
// QUERY 43
// ==================================================
// Query 5.3 - What INVOLVED_IN actually connects.
MATCH (x)-[r:INVOLVED_IN]->(c:Crime)
RETURN labels(x)[0] AS involvedLabel,
       count(r) AS relationships,
       count(DISTINCT x) AS distinctEntities,
       count(DISTINCT c) AS distinctCrimes
ORDER BY relationships DESC;

// RESULT 43
// --------------------------------------------------
// involvedLabel | relationships | distinctEntities | distinctCrimes
// Vehicle | 978 | 978 | 978
// Object | 7 | 7 | 3

// ==================================================
// QUERY 44
// ==================================================
// Query 5.4 - Vehicle involvement by crime type.
MATCH (v:Vehicle)-[:INVOLVED_IN]->(c:Crime)
RETURN c.type AS crimeType,
       count(*) AS vehicleCrimeLinks,
       count(DISTINCT v) AS vehicles,
       count(DISTINCT c) AS crimes
ORDER BY vehicleCrimeLinks DESC;

// RESULT 44
// --------------------------------------------------
// crimeType | vehicleCrimeLinks | vehicles | crimes
// Vehicle crime | 978 | 978 | 978

// ==================================================
// QUERY 45
// ==================================================
// Query 5.5 - Repeated vehicle involvement check.
MATCH (v:Vehicle)
OPTIONAL MATCH (v)-[:INVOLVED_IN]->(c:Crime)
WITH v, count(c) AS linkedCrimes
RETURN linkedCrimes,
       count(v) AS vehicles,
       CASE
         WHEN linkedCrimes <= 1 THEN 'Weak for vehicle link prediction'
         ELSE 'Potential repeated vehicle pattern'
       END AS reading
ORDER BY linkedCrimes DESC;

// RESULT 45
// --------------------------------------------------
// linkedCrimes | vehicles | reading
// 1 | 978 | Weak for vehicle link prediction
// 0 | 22 | Weak for vehicle link prediction

// ==================================================
// QUERY 46
// ==================================================
// Query 5.6 - Phone coverage for Person nodes.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:HAS_PHONE]->(phone:Phone)
WITH p, count(phone) AS phones
RETURN count(p) AS people,
       sum(CASE WHEN phones > 0 THEN 1 ELSE 0 END) AS peopleWithPhone,
       sum(CASE WHEN phones = 0 THEN 1 ELSE 0 END) AS peopleWithoutPhone,
       round(1000.0 * sum(CASE WHEN phones > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS phoneCoveragePercent;

// RESULT 46
// --------------------------------------------------
// people | peopleWithPhone | peopleWithoutPhone | phoneCoveragePercent
// 369 | 328 | 41 | 88.9

// ==================================================
// QUERY 47
// ==================================================
// Query 5.7 - People with the most linked phone calls.
MATCH (p:Person)-[:HAS_PHONE]->(phone:Phone)
OPTIONAL MATCH (call:PhoneCall)-[:CALLER|CALLED]->(phone)
WITH p, count(DISTINCT call) AS callCount
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       callCount
ORDER BY callCount DESC, person
LIMIT 20;

// RESULT 47
// --------------------------------------------------
// person | callCount
// Dorothy Hall | 10
// Kimberly Wood | 10
// Andrew Foster | 8
// Angela Mccoy | 8
// Ann Fox | 8
// Anne Nguyen | 8
// Benjamin Hamilton | 8
// Bobby Thompson | 8
// Brandon Martin | 8
// Bruce Baker | 8
// Craig Marshall | 8
// Frances Sullivan | 8
// Harold Robertson | 8
// Henry Jacobs | 8
// Jack Reyes | 8
// Jacqueline Holmes | 8
// Janet Cunningham | 8
// Janice Coleman | 8
// Jerry Johnston | 8
// Jessica Kelly | 8

// ==================================================
// QUERY 48
// ==================================================
// SECTION 6: EXPLAINABLE GML-READY SIGNALS

// Query 6.1 - Candidate Person-Person links by Common Neighbours.
MATCH (p1:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(shared:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH p1,
     p2,
     count(DISTINCT shared) AS commonNeighbours,
     collect(DISTINCT shared.name + ' ' + coalesce(shared.surname, ''))[0..5] AS exampleSharedNeighbours
WHERE commonNeighbours >= 3
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       commonNeighbours,
       exampleSharedNeighbours,
       'Explainable candidate social link for human review.' AS reading
ORDER BY commonNeighbours DESC, personA, personB
LIMIT 25;

// RESULT 48
// --------------------------------------------------
// personA | personB | commonNeighbours | exampleSharedNeighbours | reading
// Amanda Alexander | Kathryn Allen | 3 | ["Benjamin Hamilton","Denise Brown","Wanda Webb"] | Explainable candidate social link for human review.
// Jessica Kelly | Alan Ward | 3 | ["Brian Morales","Phillip Williamson","Kathy Wheeler"] | Explainable candidate social link for human review.
// Roy Dean | Harry Lopez | 3 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Explainable candidate social link for human review.
// Roy Dean | Jonathan Hunt | 3 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Explainable candidate social link for human review.

// ==================================================
// QUERY 49
// ==================================================
// Query 6.2 - Candidate Person-Person links by Adamic Adar style score.
MATCH (p1:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(shared:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH DISTINCT p1, p2, shared
MATCH (shared)-[sharedRel:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p1,
     p2,
     shared,
     count(sharedRel) AS sharedDegree
WITH p1,
     p2,
     count(shared) AS commonNeighbours,
     sum(CASE WHEN sharedDegree <= 1 THEN 0.0 ELSE 1.0 / log(sharedDegree) END) AS adamicAdarScore,
     collect(shared.name + ' ' + coalesce(shared.surname, ''))[0..5] AS exampleSharedNeighbours
WHERE commonNeighbours >= 2
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       commonNeighbours,
       adamicAdarScore,
       exampleSharedNeighbours,
       'Higher score means more specific shared social context.' AS reading
ORDER BY adamicAdarScore DESC, commonNeighbours DESC
LIMIT 25;

// RESULT 49
// --------------------------------------------------
// personA | personB | commonNeighbours | adamicAdarScore | exampleSharedNeighbours | reading
// Jessica Kelly | Alan Ward | 3 | 1.2710185681883481 | ["Brian Morales","Phillip Williamson","Kathy Wheeler"] | Higher score means more specific shared social context.
// Amanda Alexander | Kathryn Allen | 3 | 1.2490010295615737 | ["Benjamin Hamilton","Denise Brown","Wanda Webb"] | Higher score means more specific shared social context.
// Roy Dean | Harry Lopez | 3 | 1.150622159140651 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Higher score means more specific shared social context.
// Roy Dean | Jonathan Hunt | 3 | 1.150622159140651 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Higher score means more specific shared social context.
// Bruce Baker | Jeffrey Campbell | 2 | 1.1162212531024944 | ["Gloria Owens","Mildred Kelly"] | Higher score means more specific shared social context.
// Justin Arnold | Arthur Willis | 2 | 1.0743036443092429 | ["Donna Jordan","Amy Murphy"] | Higher score means more specific shared social context.
// Angela Mccoy | Phillip Perry | 2 | 1.039008973514235 | ["Todd Garcia","Roy Dean"] | Higher score means more specific shared social context.
// Ernest Thompson | Andrea George | 2 | 1.039008973514235 | ["Louis Hughes","Ruby Reynolds"] | Higher score means more specific shared social context.
// Amy Murphy | Ann Fox | 2 | 0.9605402309330919 | ["Justin Arnold","Jessica Kelly"] | Higher score means more specific shared social context.
// Dorothy Hall | Arthur Willis | 2 | 0.9481928242730024 | ["Kathy Harper","Kimberly Wood"] | Higher score means more specific shared social context.
// Doris Nichols | Dorothy Hall | 2 | 0.9151928288662396 | ["Ruth Hansen","Kathy Harper"] | Higher score means more specific shared social context.
// Jessica Kelly | Kathleen Peters | 2 | 0.9151928288662396 | ["Phillip Williamson","Diana Murray"] | Higher score means more specific shared social context.
// Diana Murray | Alan Ward | 2 | 0.9151928288662396 | ["Kathleen Peters","Kathy Wheeler"] | Higher score means more specific shared social context.
// Patricia Butler | Arthur Willis | 2 | 0.9151928288662396 | ["Michael Martin","Kathy Harper"] | Higher score means more specific shared social context.
// Raymond Walker | Alan Ward | 2 | 0.9151928288662396 | ["Kathleen Peters","Phillip Williamson"] | Higher score means more specific shared social context.
// Patricia Hanson | Donald Johnston | 2 | 0.9151928288662396 | ["Joshua Mccoy","Peter Turner"] | Higher score means more specific shared social context.
// Wayne Nguyen | Nancy Hughes | 2 | 0.9040868828124409 | ["John Jacobs","Adam Bradley"] | Higher score means more specific shared social context.
// Amy Murphy | Donna Jordan | 2 | 0.8919188272465812 | ["Arthur Willis","Justin Arnold"] | Higher score means more specific shared social context.
// Phillip Williamson | Diana Murray | 2 | 0.8833279513448324 | ["Jessica Kelly","Kathleen Peters"] | Higher score means more specific shared social context.
// Christopher Oliver | Arthur Willis | 2 | 0.8727686069953721 | ["Jason Hamilton","Annie Duncan"] | Higher score means more specific shared social context.
// Kathleen Peters | Kathy Wheeler | 2 | 0.8415721071852287 | ["Diana Murray","Alan Ward"] | Higher score means more specific shared social context.
// Bonnie Gilbert | Pamela Gibson | 2 | 0.833854470827749 | ["Amy Bailey","Stephanie Hughes"] | Higher score means more specific shared social context.
// Stephanie Hughes | Amy Bailey | 2 | 0.8205216188580964 | ["Pamela Gibson","Bonnie Gilbert"] | Higher score means more specific shared social context.
// Michael Martin | Kathy Harper | 2 | 0.814706547658322 | ["Patricia Butler","Arthur Willis"] | Higher score means more specific shared social context.
// Jason Hamilton | Annie Duncan | 2 | 0.814706547658322 | ["Christopher Oliver","Arthur Willis"] | Higher score means more specific shared social context.

// ==================================================
// QUERY 50
// ==================================================
// Query 6.3 - Candidate Person-Person context links through shared residential area.
MATCH (p1:Person)-[:CURRENT_ADDRESS]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)<-[:LOCATION_IN_AREA]-(:Location)<-[:CURRENT_ADDRESS]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH p1,
     p2,
     a
MATCH (c:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a)
WITH p1,
     p2,
     elementId(a) AS sharedAreaId,
     count(c) AS areaIncidents,
     count(DISTINCT c.type) AS areaCrimeTypes
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       sharedAreaId,
       areaIncidents,
       areaCrimeTypes,
       'Shared area context only. Not evidence of association or guilt.' AS reading
ORDER BY areaIncidents DESC, personA, personB
LIMIT 25;

// RESULT 50
// --------------------------------------------------
// personA | personB | sharedAreaId | areaIncidents | areaCrimeTypes | reading
// Eric Gutierrez | Scott Taylor | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Eric Gutierrez | Todd Garcia | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Eric Gutierrez | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Irene Austin | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Jeremy Barnes | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Juan King | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Louis Hughes | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Nicholas Mason | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Patricia Carr | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Rachel Turner | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Scott Taylor | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Harold Oliver | Todd Garcia | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Eric Gutierrez | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Jeremy Barnes | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Juan King | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Nicholas Mason | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Scott Taylor | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Irene Austin | Todd Garcia | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Jeremy Barnes | Eric Gutierrez | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Jeremy Barnes | Nicholas Mason | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Jeremy Barnes | Scott Taylor | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Jeremy Barnes | Todd Garcia | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Juan King | Eric Gutierrez | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Juan King | Jeremy Barnes | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.
// Juan King | Nicholas Mason | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | 13 | Shared area context only. Not evidence of association or guilt.

// ==================================================
// QUERY 51
// ==================================================
// Query 6.4 - Hotspots with a dominant crime type.
MATCH (c:Crime)-[:OCCURRED_AT]->(l:Location)
WITH l.address AS location,
     c.type AS crimeType,
     count(c) AS typeIncidents
ORDER BY location, typeIncidents DESC, crimeType
WITH location,
     sum(typeIncidents) AS totalIncidents,
     collect({crimeType: crimeType, incidents: typeIncidents}) AS profile
WITH location,
     totalIncidents,
     profile[0] AS dominant,
     profile[0..5] AS topCrimeProfile
WHERE totalIncidents >= 20
RETURN location,
       totalIncidents,
       dominant.crimeType AS dominantCrimeType,
       dominant.incidents AS dominantIncidents,
       round(1000.0 * dominant.incidents / totalIncidents) / 10.0 AS dominantSharePercent,
       topCrimeProfile,
       'Strong place profile for hotspot prioritisation.' AS reading
ORDER BY dominantSharePercent DESC, totalIncidents DESC
LIMIT 25;

// RESULT 51
// --------------------------------------------------
// location | totalIncidents | dominantCrimeType | dominantIncidents | dominantSharePercent | topCrimeProfile | reading
// 43 Walker's Croft | 35 | Violence and sexual offences | 32 | 91.4 | [{"incidents":32,"crimeType":"Violence and sexual offences"},{"incidents":2,"crimeType":"Public order"},{"incidents":1,"crimeType":"Other theft"}] | Strong place profile for hotspot prioritisation.
// 182 Waterson Avenue | 35 | Violence and sexual offences | 30 | 85.7 | [{"incidents":30,"crimeType":"Violence and sexual offences"},{"incidents":3,"crimeType":"Other theft"},{"incidents":1,"crimeType":"Bicycle theft"},{"incidents":1,"crimeType":"Drugs"}] | Strong place profile for hotspot prioritisation.
// 109 Soho Street | 20 | Shoplifting | 13 | 65.0 | [{"incidents":13,"crimeType":"Shoplifting"},{"incidents":3,"crimeType":"Violence and sexual offences"},{"incidents":2,"crimeType":"Public order"},{"incidents":1,"crimeType":"Other theft"},{"incidents":1,"crimeType":"Vehicle crime"}] | Strong place profile for hotspot prioritisation.
// 135 Barracks Road | 20 | Other crime | 12 | 60.0 | [{"incidents":12,"crimeType":"Other crime"},{"incidents":7,"crimeType":"Violence and sexual offences"},{"incidents":1,"crimeType":"Public order"}] | Strong place profile for hotspot prioritisation.
// 10 Central Drive | 24 | Violence and sexual offences | 14 | 58.3 | [{"incidents":14,"crimeType":"Violence and sexual offences"},{"incidents":3,"crimeType":"Public order"},{"incidents":3,"crimeType":"Vehicle crime"},{"incidents":2,"crimeType":"Criminal damage and arson"},{"incidents":1,"crimeType":"Drugs"}] | Strong place profile for hotspot prioritisation.
// 185 Albion Street | 29 | Violence and sexual offences | 16 | 55.2 | [{"incidents":16,"crimeType":"Violence and sexual offences"},{"incidents":3,"crimeType":"Other theft"},{"incidents":3,"crimeType":"Public order"},{"incidents":2,"crimeType":"Criminal damage and arson"},{"incidents":2,"crimeType":"Theft from the person"}] | Strong place profile for hotspot prioritisation.
// 55 Plate Street | 22 | Violence and sexual offences | 12 | 54.5 | [{"incidents":12,"crimeType":"Violence and sexual offences"},{"incidents":7,"crimeType":"Public order"},{"incidents":1,"crimeType":"Criminal damage and arson"},{"incidents":1,"crimeType":"Possession of weapons"},{"incidents":1,"crimeType":"Robbery"}] | Strong place profile for hotspot prioritisation.
// 175 Richmond Street | 24 | Violence and sexual offences | 12 | 50.0 | [{"incidents":12,"crimeType":"Violence and sexual offences"},{"incidents":3,"crimeType":"Public order"},{"incidents":3,"crimeType":"Robbery"},{"incidents":2,"crimeType":"Other theft"},{"incidents":2,"crimeType":"Theft from the person"}] | Strong place profile for hotspot prioritisation.
// 38 International Approach | 20 | Other theft | 10 | 50.0 | [{"incidents":10,"crimeType":"Other theft"},{"incidents":3,"crimeType":"Public order"},{"incidents":3,"crimeType":"Theft from the person"},{"incidents":3,"crimeType":"Vehicle crime"},{"incidents":1,"crimeType":"Possession of weapons"}] | Strong place profile for hotspot prioritisation.
// 74 Back Market Street | 21 | Violence and sexual offences | 10 | 47.6 | [{"incidents":10,"crimeType":"Violence and sexual offences"},{"incidents":6,"crimeType":"Public order"},{"incidents":4,"crimeType":"Criminal damage and arson"},{"incidents":1,"crimeType":"Other crime"}] | Strong place profile for hotspot prioritisation.
// 136 A5185 | 30 | Violence and sexual offences | 14 | 46.7 | [{"incidents":14,"crimeType":"Violence and sexual offences"},{"incidents":9,"crimeType":"Public order"},{"incidents":2,"crimeType":"Criminal damage and arson"},{"incidents":2,"crimeType":"Other theft"},{"incidents":1,"crimeType":"Other crime"}] | Strong place profile for hotspot prioritisation.
// Prison | 73 | Violence and sexual offences | 34 | 46.6 | [{"incidents":34,"crimeType":"Violence and sexual offences"},{"incidents":24,"crimeType":"Other crime"},{"incidents":7,"crimeType":"Public order"},{"incidents":6,"crimeType":"Drugs"},{"incidents":1,"crimeType":"Robbery"}] | Strong place profile for hotspot prioritisation.
// 11 The Gateway | 24 | Violence and sexual offences | 11 | 45.8 | [{"incidents":11,"crimeType":"Violence and sexual offences"},{"incidents":9,"crimeType":"Public order"},{"incidents":3,"crimeType":"Drugs"},{"incidents":1,"crimeType":"Other crime"}] | Strong place profile for hotspot prioritisation.
// Bus/Coach Station | 100 | Shoplifting | 45 | 45.0 | [{"incidents":45,"crimeType":"Shoplifting"},{"incidents":19,"crimeType":"Violence and sexual offences"},{"incidents":11,"crimeType":"Public order"},{"incidents":8,"crimeType":"Other theft"},{"incidents":4,"crimeType":"Theft from the person"}] | Strong place profile for hotspot prioritisation.
// Shopping Area | 594 | Shoplifting | 251 | 42.3 | [{"incidents":251,"crimeType":"Shoplifting"},{"incidents":91,"crimeType":"Public order"},{"incidents":64,"crimeType":"Violence and sexual offences"},{"incidents":60,"crimeType":"Other theft"},{"incidents":30,"crimeType":"Theft from the person"}] | Strong place profile for hotspot prioritisation.
// 197 Marron Place | 27 | Other theft | 11 | 40.7 | [{"incidents":11,"crimeType":"Other theft"},{"incidents":4,"crimeType":"Theft from the person"},{"incidents":4,"crimeType":"Violence and sexual offences"},{"incidents":3,"crimeType":"Public order"},{"incidents":3,"crimeType":"Robbery"}] | Strong place profile for hotspot prioritisation.
// 45 Taplin Drive | 21 | Public order | 8 | 38.1 | [{"incidents":8,"crimeType":"Public order"},{"incidents":5,"crimeType":"Shoplifting"},{"incidents":3,"crimeType":"Violence and sexual offences"},{"incidents":2,"crimeType":"Bicycle theft"},{"incidents":2,"crimeType":"Theft from the person"}] | Strong place profile for hotspot prioritisation.
// Sports/Recreation Area | 169 | Violence and sexual offences | 61 | 36.1 | [{"incidents":61,"crimeType":"Violence and sexual offences"},{"incidents":25,"crimeType":"Public order"},{"incidents":22,"crimeType":"Criminal damage and arson"},{"incidents":21,"crimeType":"Burglary"},{"incidents":17,"crimeType":"Other theft"}] | Strong place profile for hotspot prioritisation.
// Conference/Exhibition Centre | 31 | Violence and sexual offences | 11 | 35.5 | [{"incidents":11,"crimeType":"Violence and sexual offences"},{"incidents":6,"crimeType":"Public order"},{"incidents":4,"crimeType":"Criminal damage and arson"},{"incidents":3,"crimeType":"Other theft"},{"incidents":3,"crimeType":"Shoplifting"}] | Strong place profile for hotspot prioritisation.
// Supermarket | 614 | Shoplifting | 214 | 34.9 | [{"incidents":214,"crimeType":"Shoplifting"},{"incidents":120,"crimeType":"Public order"},{"incidents":103,"crimeType":"Violence and sexual offences"},{"incidents":44,"crimeType":"Other theft"},{"incidents":39,"crimeType":"Criminal damage and arson"}] | Strong place profile for hotspot prioritisation.
// Hospital | 113 | Violence and sexual offences | 38 | 33.6 | [{"incidents":38,"crimeType":"Violence and sexual offences"},{"incidents":26,"crimeType":"Other theft"},{"incidents":16,"crimeType":"Criminal damage and arson"},{"incidents":14,"crimeType":"Public order"},{"incidents":6,"crimeType":"Vehicle crime"}] | Strong place profile for hotspot prioritisation.
// 45 Union Buildings | 26 | Public order | 8 | 30.8 | [{"incidents":8,"crimeType":"Public order"},{"incidents":7,"crimeType":"Violence and sexual offences"},{"incidents":4,"crimeType":"Other theft"},{"incidents":2,"crimeType":"Burglary"},{"incidents":2,"crimeType":"Criminal damage and arson"}] | Strong place profile for hotspot prioritisation.
// Police Station | 73 | Public order | 21 | 28.8 | [{"incidents":21,"crimeType":"Public order"},{"incidents":12,"crimeType":"Criminal damage and arson"},{"incidents":12,"crimeType":"Violence and sexual offences"},{"incidents":6,"crimeType":"Drugs"},{"incidents":5,"crimeType":"Other theft"}] | Strong place profile for hotspot prioritisation.
// Pedestrian Subway | 115 | Violence and sexual offences | 33 | 28.7 | [{"incidents":33,"crimeType":"Violence and sexual offences"},{"incidents":18,"crimeType":"Public order"},{"incidents":14,"crimeType":"Criminal damage and arson"},{"incidents":10,"crimeType":"Shoplifting"},{"incidents":8,"crimeType":"Other theft"}] | Strong place profile for hotspot prioritisation.
// Park/Open Space | 49 | Vehicle crime | 14 | 28.6 | [{"incidents":14,"crimeType":"Vehicle crime"},{"incidents":13,"crimeType":"Violence and sexual offences"},{"incidents":9,"crimeType":"Public order"},{"incidents":4,"crimeType":"Other theft"},{"incidents":3,"crimeType":"Bicycle theft"}] | Strong place profile for hotspot prioritisation.

// ==================================================
// QUERY 52
// ==================================================
// Query 6.5 - Monthly crime trend by crime type.
MATCH (c:Crime)
WHERE c.date IS NOT NULL
WITH substring(toString(c.date), 0, 7) AS crimeMonth,
     c.type AS crimeType,
     count(c) AS incidents
RETURN crimeMonth,
       crimeType,
       incidents
ORDER BY crimeMonth, incidents DESC, crimeType
LIMIT 60;

// RESULT 52
// --------------------------------------------------
// crimeMonth | crimeType | incidents
// 1/08/20 | Violence and sexual offences | 314
// 1/08/20 | Public order | 141
// 1/08/20 | Criminal damage and arson | 110
// 1/08/20 | Burglary | 101
// 1/08/20 | Vehicle crime | 92
// 1/08/20 | Other theft | 50
// 1/08/20 | Shoplifting | 45
// 1/08/20 | Other crime | 18
// 1/08/20 | Theft from the person | 17
// 1/08/20 | Robbery | 10
// 1/08/20 | Bicycle theft | 9
// 1/08/20 | Possession of weapons | 9
// 1/08/20 | Drugs | 7
// 10/08/2 | Violence and sexual offences | 283
// 10/08/2 | Public order | 156
// 10/08/2 | Criminal damage and arson | 127
// 10/08/2 | Burglary | 98
// 10/08/2 | Vehicle crime | 96
// 10/08/2 | Other theft | 90
// 10/08/2 | Other crime | 32
// 10/08/2 | Shoplifting | 31
// 10/08/2 | Robbery | 16
// 10/08/2 | Theft from the person | 15
// 10/08/2 | Bicycle theft | 11
// 10/08/2 | Drugs | 9
// 10/08/2 | Possession of weapons | 8
// 11/08/2 | Violence and sexual offences | 282
// 11/08/2 | Public order | 169
// 11/08/2 | Criminal damage and arson | 123
// 11/08/2 | Vehicle crime | 88
// 11/08/2 | Burglary | 87
// 11/08/2 | Other theft | 61
// 11/08/2 | Shoplifting | 38
// 11/08/2 | Other crime | 23
// 11/08/2 | Robbery | 22
// 11/08/2 | Theft from the person | 13
// 11/08/2 | Drugs | 12
// 11/08/2 | Bicycle theft | 10
// 11/08/2 | Possession of weapons | 2
// 12/08/2 | Violence and sexual offences | 258
// 12/08/2 | Public order | 160
// 12/08/2 | Criminal damage and arson | 120
// 12/08/2 | Burglary | 83
// 12/08/2 | Other theft | 82
// 12/08/2 | Vehicle crime | 74
// 12/08/2 | Shoplifting | 51
// 12/08/2 | Other crime | 21
// 12/08/2 | Robbery | 17
// 12/08/2 | Bicycle theft | 13
// 12/08/2 | Theft from the person | 10
// 12/08/2 | Drugs | 7
// 12/08/2 | Possession of weapons | 3
// 12/08/2 |  | 1
// 13/08/2 | Violence and sexual offences | 286
// 13/08/2 | Public order | 140
// 13/08/2 | Criminal damage and arson | 122
// 13/08/2 | Burglary | 92
// 13/08/2 | Vehicle crime | 87
// 13/08/2 | Other theft | 61
// 13/08/2 | Shoplifting | 36

// ==================================================
// QUERY 53
// ==================================================
// Query 6.6 - Community to hotspot exposure.
MATCH (p:Person)
WHERE p.revisedSocialCommunityId IS NOT NULL
MATCH (p)-[:CURRENT_ADDRESS]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)
MATCH (c:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a)
WITH p.revisedSocialCommunityId AS communityId,
     elementId(a) AS areaId,
     count(DISTINCT p) AS communityResidents,
     count(DISTINCT c) AS areaIncidents,
     count(DISTINCT c.type) AS areaCrimeTypes
WHERE communityResidents >= 2
RETURN communityId,
       areaId,
       communityResidents,
       areaIncidents,
       areaCrimeTypes,
       'Community-area exposure for prioritisation only.' AS reading
ORDER BY areaIncidents DESC, communityResidents DESC
LIMIT 25;

// RESULT 53
// --------------------------------------------------
// communityId | areaId | communityResidents | areaIncidents | areaCrimeTypes | reading
// 226 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 3 | 860 | 13 | Community-area exposure for prioritisation only.
// 162 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 2 | 860 | 13 | Community-area exposure for prioritisation only.
// 197 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 2 | 860 | 13 | Community-area exposure for prioritisation only.
// 249 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 2 | 814 | 12 | Community-area exposure for prioritisation only.
// 251 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 2 | 814 | 12 | Community-area exposure for prioritisation only.
// 331 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 2 | 814 | 12 | Community-area exposure for prioritisation only.
// 251 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17079 | 2 | 699 | 13 | Community-area exposure for prioritisation only.
// 237 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17102 | 3 | 623 | 13 | Community-area exposure for prioritisation only.
// 325 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16983 | 3 | 562 | 13 | Community-area exposure for prioritisation only.
// 328 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17195 | 3 | 562 | 13 | Community-area exposure for prioritisation only.
// 325 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17004 | 2 | 562 | 12 | Community-area exposure for prioritisation only.
// 91 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17004 | 2 | 562 | 12 | Community-area exposure for prioritisation only.
// 237 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16983 | 2 | 562 | 13 | Community-area exposure for prioritisation only.
// 249 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:61511 | 3 | 505 | 13 | Community-area exposure for prioritisation only.
// 351 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:61511 | 2 | 505 | 13 | Community-area exposure for prioritisation only.
// 331 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 3 | 497 | 13 | Community-area exposure for prioritisation only.
// 162 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 2 | 497 | 13 | Community-area exposure for prioritisation only.
// 91 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 2 | 497 | 13 | Community-area exposure for prioritisation only.
// 328 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 2 | 497 | 13 | Community-area exposure for prioritisation only.
// 351 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16996 | 2 | 490 | 13 | Community-area exposure for prioritisation only.
// 239 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16994 | 2 | 466 | 12 | Community-area exposure for prioritisation only.
// 91 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17002 | 2 | 457 | 13 | Community-area exposure for prioritisation only.
// 328 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17002 | 2 | 457 | 13 | Community-area exposure for prioritisation only.
// 329 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17098 | 5 | 430 | 13 | Community-area exposure for prioritisation only.
// 251 | 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17021 | 2 | 426 | 13 | Community-area exposure for prioritisation only.

// ==================================================
// QUERY 54
// ==================================================
// Query 6.7 - Final graph ML feature recommendation.
RETURN 'Use Crime-Location and Area profiles as the main demo evidence. Use social graph centrality and Louvain as the main GDS result. Use Common Neighbours and Adamic Adar as explainable Person-Person link prediction baselines. Keep supervised KNOWS link prediction in graph ML, but gate write-back if probabilities are flat. Keep PARTY_TO only as observed context.' AS m3FeatureRecommendation;

// RESULT 54
// --------------------------------------------------
// m3FeatureRecommendation
// Use Crime-Location and Area profiles as the main demo evidence. Use social graph centrality and Louvain as the main GDS result. Use Common Neighbours and Adamic Adar as explainable Person-Person link prediction baselines. Keep supervised KNOWS link prediction in graph ML, but gate write-back if probabilities are flat. Keep PARTY_TO only as observed context.

// ==================================================
// QUERY 55
// ==================================================
// SECTION 7: FINAL GRAPH STATS SUMMARY

// Query 7.1 - Final evidence-led recommendation.
MATCH (:Person)-[party:PARTY_TO]->(:Crime)
WITH count(party) AS partyToLinks
MATCH (:Crime)-[occurred:OCCURRED_AT]->(:Location)
WITH partyToLinks, count(occurred) AS crimeLocationLinks
MATCH (:Person)-[social:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]->(:Person)
WITH partyToLinks, crimeLocationLinks, count(social) AS socialLinks
MATCH (:Vehicle)-[vehicleCrime:INVOLVED_IN]->(:Crime)
RETURN partyToLinks,
       crimeLocationLinks,
       socialLinks,
       count(vehicleCrime) AS vehicleCrimeLinks,
       'Final graph stats framing: POLE investigative analytics. Lead with crime-location hotspots, area crime profiles, and social communities. Use vehicle and address data as context. Treat Person-Crime links as sparse observed evidence, not the main prediction target.' AS finalRecommendation;

// RESULT 55
// --------------------------------------------------
// partyToLinks | crimeLocationLinks | socialLinks | vehicleCrimeLinks | finalRecommendation
// 55 | 28762 | 1180 | 978 | Final graph stats framing: POLE investigative analytics. Lead with crime-location hotspots, area crime profiles, and social communities. Use vehicle and address data as context. Treat Person-Crime links as sparse observed evidence, not the main prediction target.
