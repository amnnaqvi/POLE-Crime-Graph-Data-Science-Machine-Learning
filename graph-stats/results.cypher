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
// graphStatsSocialGraph

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
WHERE NOT type(r) STARTS WITH 'PREDICTED_'
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

// ==================================================
// QUERY 10
// ==================================================
// Query 1.3 - Full schema map: which labels each relationship connects.
MATCH (a)-[r]->(b)
WHERE NOT type(r) STARTS WITH 'PREDICTED_'
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
WHERE NOT type(r) STARTS WITH 'PREDICTED_'
RETURN totalNodes,
       count(r) AS totalRelationships;

// RESULT 17
// --------------------------------------------------
// totalNodes | totalRelationships
// 61521 | 105840

// ==================================================
// QUERY 18
// ==================================================
// Query 1.11 - Degree summary across baseline graph relationships.
MATCH (n)
OPTIONAL MATCH (n)-[r]-()
WHERE r IS NULL OR NOT type(r) STARTS WITH 'PREDICTED_'
WITH n, count(r) AS degree
RETURN avg(degree) AS averageDegree,
       min(degree) AS minimumDegree,
       max(degree) AS maximumDegree;

// RESULT 18
// --------------------------------------------------
// averageDegree | minimumDegree | maximumDegree
// 3.440776320280921 | 0 | 1321

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
// Query 3.6 - Crime concentration across repeat locations.
MATCH (c:Crime)-[:OCCURRED_AT]->(l:Location)
WITH l.address AS location, count(c) AS incidents
ORDER BY incidents DESC
WITH collect({location: location, incidents: incidents}) AS rankedLocations,
     sum(incidents) AS totalIncidents,
     count(*) AS locationCount
RETURN locationCount,
       totalIncidents,
       reduce(s = 0, x IN rankedLocations[0..10] | s + x.incidents) AS top10Incidents,
       round(1000.0 * reduce(s = 0, x IN rankedLocations[0..10] | s + x.incidents) / totalIncidents) / 10.0 AS top10SharePercent,
       reduce(s = 0, x IN rankedLocations[0..20] | s + x.incidents) AS top20Incidents,
       round(1000.0 * reduce(s = 0, x IN rankedLocations[0..20] | s + x.incidents) / totalIncidents) / 10.0 AS top20SharePercent,
       rankedLocations[0..5] AS topFiveLocations,
       'Concentration shows whether place-based intervention can cover meaningful incident volume.' AS reading;

// RESULT 28
// --------------------------------------------------
// locationCount | totalIncidents | top10Incidents | top10SharePercent | top20Incidents | top20SharePercent | topFiveLocations | reading
// 12401 | 28762 | 3349 | 11.6 | 3832 | 13.3 | [{"incidents":811,"location":"Parking Area"},{"incidents":614,"location":"Supermarket"},{"incidents":594,"location":"Shopping Area"},{"incidents":336,"location":"Nightclub"},{"incidents":331,"location":"Petrol Station"}] | Concentration shows whether place-based intervention can cover meaningful incident volume.

// ==================================================
// QUERY 29
// ==================================================
// Query 3.7 - Outcome distribution for all crimes.
MATCH (c:Crime)
RETURN coalesce(c.last_outcome, 'Missing') AS outcome,
       count(c) AS crimes,
       round(1000.0 * count(c) / 28762) / 10.0 AS sharePercent
ORDER BY crimes DESC
LIMIT 20;

// RESULT 29
// --------------------------------------------------
