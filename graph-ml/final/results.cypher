// Neo4j queries + result report
// Group 4: Amn Naqvi and Rayyan Shah

// SECTION 0: SETUP

// Query 0.1 - GDS version.
RETURN gds.version() AS gdsVersion;

// RESULT 1
// --------------------------------------------------
// gdsVersion
// 2026.03.0

// ==================================================
// QUERY 2
// ==================================================
// Query 0.2 - Clear old prediction relationships from previous runs.
MATCH ()-[r:PREDICTED_SOCIAL_REVIEW]->()
DELETE r;

// RESULT 2
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 3
// ==================================================
MATCH ()-[r:PREDICTED_SOCIAL_EXPLAINABLE]->()
DELETE r;

// RESULT 3
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 4
// ==================================================
MATCH ()-[r:OBSERVED_SOCIAL_LINK_TMP]->()
DELETE r;

// RESULT 4
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 5
// ==================================================
// Query 0.3 - Drop old in-memory GDS items from previous runs.
CALL gds.model.drop('social-family-lp-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

// RESULT 5
// --------------------------------------------------
// droppedModel
// social-family-lp-model

// ==================================================
// QUERY 6
// ==================================================
CALL gds.pipeline.drop('social-family-lp-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

// RESULT 6
// --------------------------------------------------
// droppedPipeline
// social-family-lp-pipeline

// ==================================================
// QUERY 7
// ==================================================
CALL gds.graph.drop('socialFamilyContextGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// RESULT 7
// --------------------------------------------------
// droppedGraph
// socialFamilyContextGraph

// ==================================================
// QUERY 8
// ==================================================
CALL gds.graph.drop('revisedSocialGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// RESULT 8
// --------------------------------------------------
// droppedGraph
// revisedSocialGraph

// ==================================================
// QUERY 9
// ==================================================
CALL gds.model.drop('crime-class-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

// RESULT 9
// --------------------------------------------------
// droppedModel
// crime-class-model

// ==================================================
// QUERY 10
// ==================================================
CALL gds.pipeline.drop('crime-class-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

// RESULT 10
// --------------------------------------------------
// droppedPipeline
// crime-class-pipeline

// ==================================================
// QUERY 11
// ==================================================
CALL gds.graph.drop('crimeClassGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// RESULT 11
// --------------------------------------------------
// droppedGraph
// crimeClassGraph

// ==================================================
// QUERY 12
// ==================================================
CALL gds.graph.drop('socialEmbeddingGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// RESULT 12
// --------------------------------------------------
// droppedGraph
// socialEmbeddingGraph

// ==================================================
// QUERY 13
// ==================================================
// SECTION 1: WHY THE TARGET CHANGED

// Query 1.1 - Link-family scorecard from the graph stats audit.
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
           'Do not use as the main automated prediction target.' AS reading

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
           'Strongest descriptive signal for hotspots and place profiles.' AS reading

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
           'Best supervised GDS target: enough labels and safer interpretation.' AS reading

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
           'Strong coverage for context and exposure, but not evidence of guilt.' AS reading

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
           'Useful context, but mostly one vehicle per crime in this dump.' AS reading

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
           'Useful communication context through Person -> Phone coverage.' AS reading
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

// RESULT 13
// --------------------------------------------------
// linkFamily | relationshipTypes | observedLinks | coveredSources | sources | sourceCoveragePercent | coveredTargets | targets | targetCoveragePercent | pairDensityPercent | reading
// Crime -> Location | OCCURRED_AT | 28762 | 28762 | 28762 | 100.0 | 13302 | 14904 | 89.3 | 0.0067 | Strongest descriptive signal for hotspots and place profiles.
// Person -> Person | KNOWS, KNOWS_SN, KNOWS_PHONE, KNOWS_LW, FAMILY_REL | 1180 | 234 | 369 | 63.4 | 314 | 369 | 85.1 | 0.8666 | Best supervised GDS target: enough labels and safer interpretation.
// PhoneCall -> Phone | CALLER, CALLED | 1068 | 534 | 534 | 100.0 | 236 | 328 | 72.0 | 0.6098 | Useful communication context through Person -> Phone coverage.
// Vehicle -> Crime | INVOLVED_IN | 978 | 978 | 1000 | 97.8 | 978 | 28762 | 3.4 | 0.0034 | Useful context, but mostly one vehicle per crime in this dump.
// Person -> Location | CURRENT_ADDRESS | 368 | 368 | 369 | 99.7 | 298 | 14904 | 2.0 | 0.0067 | Strong coverage for context and exposure, but not evidence of guilt.
// Person -> Crime | PARTY_TO | 55 | 29 | 369 | 7.9 | 55 | 28762 | 0.2 | 0.0005 | Do not use as the main automated prediction target.

// ==================================================
// QUERY 14
// ==================================================
// Query 1.2 - Person-Crime sparsity limit.
MATCH (p:Person)
WITH count(p) AS persons
MATCH (c:Crime)
WITH persons, count(c) AS crimes
MATCH (:Person)-[:PARTY_TO]-(:Crime)
WITH persons, crimes, count(*) AS observedPartyTo
RETURN persons,
       crimes,
       observedPartyTo,
       persons * crimes AS possiblePairs,
       round(1000000.0 * observedPartyTo / (persons * crimes)) / 10000.0 AS positiveClassPercent,
       'PARTY_TO is retained as observed context, not as the main write-back target.' AS decision;

// RESULT 14
// --------------------------------------------------
// persons | crimes | observedPartyTo | possiblePairs | positiveClassPercent | decision
// 369 | 28762 | 55 | 10613178 | 0.0005 | PARTY_TO is retained as observed context, not as the main write-back target.

// ==================================================
// QUERY 15
// ==================================================
// Query 1.3 - Supporting context coverage from graph stats.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:CURRENT_ADDRESS]->(home:Location)
WITH count(p) AS people,
     sum(CASE WHEN home IS NOT NULL THEN 1 ELSE 0 END) AS peopleWithCurrentAddress
MATCH (personForPhone:Person)
OPTIONAL MATCH (personForPhone)-[:HAS_PHONE]->(phone:Phone)
WITH people,
     peopleWithCurrentAddress,
     count(personForPhone) AS phonePeople,
     sum(CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END) AS peopleWithPhone
MATCH (v:Vehicle)
OPTIONAL MATCH (v)-[:INVOLVED_IN]->(vehicleCrime:Crime)
WITH people,
     peopleWithCurrentAddress,
     phonePeople,
     peopleWithPhone,
     count(v) AS vehicles,
     sum(CASE WHEN vehicleCrime IS NOT NULL THEN 1 ELSE 0 END) AS vehiclesLinkedToCrime
RETURN people,
       peopleWithCurrentAddress,
       round(1000.0 * peopleWithCurrentAddress / people) / 10.0 AS addressCoveragePercent,
       peopleWithPhone,
       round(1000.0 * peopleWithPhone / phonePeople) / 10.0 AS phoneCoveragePercent,
       vehicles,
       vehiclesLinkedToCrime,
       round(1000.0 * vehiclesLinkedToCrime / vehicles) / 10.0 AS vehicleCrimeCoveragePercent,
       'Address and phone data are strong supporting context. Vehicle links exist but are mostly one-off.' AS contextReading;

// RESULT 15
// --------------------------------------------------
// people | peopleWithCurrentAddress | addressCoveragePercent | peopleWithPhone | phoneCoveragePercent | vehicles | vehiclesLinkedToCrime | vehicleCrimeCoveragePercent | contextReading
// 369 | 368 | 99.7 | 328 | 88.9 | 1000 | 978 | 97.8 | Address and phone data are strong supporting context. Vehicle links exist but are mostly one-off.

// ==================================================
// QUERY 16
// ==================================================
// SECTION 2: HOTSPOT AND AREA ANALYTICS

// Query 2.1 - Crime-location coverage.
MATCH (c:Crime)
OPTIONAL MATCH (c)-[:OCCURRED_AT]->(l:Location)
WITH c, count(l) AS locationLinks
RETURN count(c) AS crimes,
       sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) AS crimesWithLocation,
       sum(CASE WHEN locationLinks = 0 THEN 1 ELSE 0 END) AS crimesWithoutLocation,
       round(1000.0 * sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS locationCoveragePercent;

// RESULT 16
// --------------------------------------------------
// crimes | crimesWithLocation | crimesWithoutLocation | locationCoveragePercent
// 28762 | 28762 | 0 | 100.0

// ==================================================
// QUERY 17
// ==================================================
// Query 2.2 - Top hotspots by repeated incident count.
MATCH (c:Crime)-[:OCCURRED_AT]->(l:Location)
WITH l.address AS location,
     count(c) AS incidents,
     count(DISTINCT c.type) AS distinctCrimeTypes,
     collect(DISTINCT c.type)[0..5] AS exampleCrimeTypes
RETURN location,
       incidents,
       distinctCrimeTypes,
       exampleCrimeTypes,
       CASE
         WHEN incidents >= 100 THEN 'Very high repeat-place priority'
         WHEN incidents >= 30 THEN 'High repeat-place priority'
         ELSE 'Moderate repeat-place priority'
       END AS hotspotReading
ORDER BY incidents DESC, distinctCrimeTypes DESC
LIMIT 20;

// RESULT 17
// --------------------------------------------------
// location | incidents | distinctCrimeTypes | exampleCrimeTypes | hotspotReading
// Parking Area | 811 | 13 | ["Drugs","Public order","Other theft","Theft from the person","Violence and sexual offences"] | Very high repeat-place priority
// Supermarket | 614 | 13 | ["Shoplifting","Violence and sexual offences","Criminal damage and arson","Public order","Other crime"] | Very high repeat-place priority
// Shopping Area | 594 | 13 | ["Shoplifting","Burglary","Other theft","Theft from the person","Public order"] | Very high repeat-place priority
// Nightclub | 336 | 13 | ["Public order","Other theft","Burglary","Vehicle crime","Shoplifting"] | Very high repeat-place priority
// Petrol Station | 331 | 13 | ["Other theft","Public order","Vehicle crime","Burglary","Robbery"] | Very high repeat-place priority
// Sports/Recreation Area | 169 | 12 | ["Criminal damage and arson","Other theft","Burglary","Public order","Violence and sexual offences"] | Very high repeat-place priority
// Piccadilly | 166 | 11 | ["Public order","Violence and sexual offences","Theft from the person","Other crime","Robbery"] | Very high repeat-place priority
// Pedestrian Subway | 115 | 13 | ["Other crime","Other theft","Robbery","Violence and sexual offences","Drugs"] | Very high repeat-place priority
// Hospital | 113 | 11 | ["Criminal damage and arson","Vehicle crime","Violence and sexual offences","Public order","Other crime"] | Very high repeat-place priority
// Bus/Coach Station | 100 | 11 | ["Violence and sexual offences","Public order","Bicycle theft","Theft from the person","Other theft"] | Very high repeat-place priority
// Further/Higher Educational Building | 74 | 11 | ["Robbery","Public order","Violence and sexual offences","Vehicle crime","Shoplifting"] | High repeat-place priority
// Police Station | 73 | 12 | ["Violence and sexual offences","Criminal damage and arson","Vehicle crime","Possession of weapons","Burglary"] | High repeat-place priority
// Prison | 73 | 6 | ["Violence and sexual offences","Other crime","Public order","Drugs","Vehicle crime"] | High repeat-place priority
// Theatre/Concert Hall | 54 | 10 | ["Burglary","Criminal damage and arson","Other theft","Public order","Vehicle crime"] | High repeat-place priority
// Park/Open Space | 49 | 10 | ["Other theft","Public order","Vehicle crime","Violence and sexual offences","Criminal damage and arson"] | High repeat-place priority
// 182 Waterson Avenue | 35 | 4 | ["Violence and sexual offences","Other theft","Drugs","Bicycle theft"] | High repeat-place priority
// 43 Walker's Croft | 35 | 3 | ["Public order","Violence and sexual offences","Other theft"] | High repeat-place priority
// Conference/Exhibition Centre | 31 | 7 | ["Violence and sexual offences","Other theft","Bicycle theft","Shoplifting","Public order"] | High repeat-place priority
// 136 A5185 | 30 | 7 | ["Public order","Other theft","Criminal damage and arson","Robbery","Violence and sexual offences"] | High repeat-place priority
// 185 Albion Street | 29 | 8 | ["Violence and sexual offences","Other theft","Criminal damage and arson","Burglary","Public order"] | Moderate repeat-place priority

// ==================================================
// QUERY 18
// ==================================================
// Query 2.3 - Area-level crime profiles.
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
       'Area profile supports place-based prioritisation better than person accusation.' AS areaReading
ORDER BY totalIncidents DESC
LIMIT 20;

// RESULT 18
// --------------------------------------------------
// areaId | totalIncidents | dominantCrimeTypes | areaReading
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17012 | 975 | ["Violence and sexual offences (249)","Public order (129)","Theft from the person (123)","Other theft (113)","Vehicle crime (79)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16965 | 860 | ["Violence and sexual offences (242)","Public order (182)","Criminal damage and arson (92)","Burglary (84)","Other theft (69)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17026 | 814 | ["Violence and sexual offences (223)","Public order (149)","Criminal damage and arson (117)","Vehicle crime (94)","Burglary (93)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16992 | 766 | ["Violence and sexual offences (234)","Public order (184)","Criminal damage and arson (113)","Vehicle crime (59)","Burglary (55)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17079 | 699 | ["Violence and sexual offences (187)","Public order (174)","Criminal damage and arson (119)","Burglary (51)","Other theft (51)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17102 | 623 | ["Violence and sexual offences (204)","Public order (111)","Criminal damage and arson (80)","Burglary (53)","Shoplifting (49)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17195 | 562 | ["Violence and sexual offences (197)","Public order (124)","Criminal damage and arson (72)","Burglary (50)","Vehicle crime (34)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17004 | 562 | ["Violence and sexual offences (195)","Public order (93)","Criminal damage and arson (86)","Burglary (55)","Vehicle crime (46)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16983 | 562 | ["Violence and sexual offences (144)","Public order (99)","Burglary (87)","Criminal damage and arson (58)","Vehicle crime (54)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17124 | 540 | ["Violence and sexual offences (176)","Public order (100)","Criminal damage and arson (98)","Other theft (40)","Vehicle crime (34)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17091 | 509 | ["Violence and sexual offences (148)","Public order (79)","Criminal damage and arson (78)","Shoplifting (52)","Burglary (49)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16963 | 507 | ["Violence and sexual offences (181)","Public order (86)","Criminal damage and arson (64)","Shoplifting (52)","Other theft (35)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:61511 | 505 | ["Violence and sexual offences (178)","Public order (82)","Criminal damage and arson (56)","Burglary (46)","Other theft (37)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17018 | 497 | ["Violence and sexual offences (107)","Public order (86)","Burglary (83)","Vehicle crime (67)","Criminal damage and arson (54)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17029 | 490 | ["Violence and sexual offences (175)","Criminal damage and arson (74)","Public order (71)","Burglary (38)","Vehicle crime (38)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16996 | 490 | ["Violence and sexual offences (154)","Public order (89)","Burglary (63)","Vehicle crime (49)","Criminal damage and arson (46)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16994 | 466 | ["Violence and sexual offences (159)","Public order (88)","Criminal damage and arson (63)","Vehicle crime (48)","Burglary (31)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17002 | 457 | ["Violence and sexual offences (168)","Public order (88)","Criminal damage and arson (43)","Vehicle crime (41)","Burglary (39)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:16976 | 454 | ["Violence and sexual offences (166)","Public order (68)","Criminal damage and arson (58)","Vehicle crime (37)","Burglary (36)"] | Area profile supports place-based prioritisation better than person accusation.
// 4:f095f8b5-3a0a-4746-a6a6-8b1fc339b4b3:17000 | 436 | ["Violence and sexual offences (163)","Criminal damage and arson (74)","Burglary (43)","Vehicle crime (37)","Other theft (36)"] | Area profile supports place-based prioritisation better than person accusation.

// ==================================================
// QUERY 19
// ==================================================
// Query 2.4 - Repeat pattern: same crime type at same location.
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
       'Historical repeat pattern, not a claim about future incidents.' AS patternReading
ORDER BY sameTypeCrimePairs DESC
LIMIT 20;

// RESULT 19
// --------------------------------------------------
// location | crimeType | sameTypeCrimePairs | patternReading
// Shopping Area | Shoplifting | 1405 | Historical repeat pattern, not a claim about future incidents.
// Piccadilly | Violence and sexual offences | 1081 | Historical repeat pattern, not a claim about future incidents.
// Supermarket | Shoplifting | 511 | Historical repeat pattern, not a claim about future incidents.
// 43 Walker's Croft | Violence and sexual offences | 496 | Historical repeat pattern, not a claim about future incidents.
// 182 Waterson Avenue | Violence and sexual offences | 435 | Historical repeat pattern, not a claim about future incidents.
// Bus/Coach Station | Shoplifting | 367 | Historical repeat pattern, not a claim about future incidents.
// Parking Area | Violence and sexual offences | 359 | Historical repeat pattern, not a claim about future incidents.
// Piccadilly | Public order | 325 | Historical repeat pattern, not a claim about future incidents.
// Prison | Violence and sexual offences | 308 | Historical repeat pattern, not a claim about future incidents.
// Nightclub | Violence and sexual offences | 301 | Historical repeat pattern, not a claim about future incidents.
// Shopping Area | Public order | 286 | Historical repeat pattern, not a claim about future incidents.
// Piccadilly | Drugs | 253 | Historical repeat pattern, not a claim about future incidents.
// Piccadilly | Robbery | 190 | Historical repeat pattern, not a claim about future incidents.
// Prison | Other crime | 148 | Historical repeat pattern, not a claim about future incidents.
// Shopping Area | Violence and sexual offences | 148 | Historical repeat pattern, not a claim about future incidents.
// Shopping Area | Other theft | 144 | Historical repeat pattern, not a claim about future incidents.
// Parking Area | Other theft | 144 | Historical repeat pattern, not a claim about future incidents.
// Hospital | Violence and sexual offences | 142 | Historical repeat pattern, not a claim about future incidents.
// Nightclub | Theft from the person | 129 | Historical repeat pattern, not a claim about future incidents.
// Supermarket | Violence and sexual offences | 120 | Historical repeat pattern, not a claim about future incidents.

// ==================================================
// QUERY 20
// ==================================================
// Query 2.5 - Historical place baseline by crime type.
MATCH (c:Crime)
WHERE c.type IS NOT NULL
WITH DISTINCT c.type AS crimeType
CALL {
  WITH crimeType
  MATCH (c:Crime {type: crimeType})-[:OCCURRED_AT]->(l:Location)
  WITH l.address AS location, count(c) AS incidents
  ORDER BY incidents DESC, location
  RETURN collect(location + ' (' + toString(incidents) + ')')[0..5] AS topLocations
}
RETURN crimeType,
       topLocations,
       'Historical baseline for where this crime type most often appears.' AS baselineReading
ORDER BY crimeType;

// RESULT 20
// --------------------------------------------------
// crimeType | topLocations | baselineReading
// Bicycle theft | ["Parking Area (23)","Shopping Area (15)","Supermarket (10)","Nightclub (6)","Petrol Station (6)"] | Historical baseline for where this crime type most often appears.
// Burglary | ["Parking Area (44)","Supermarket (26)","Sports/Recreation Area (21)","Petrol Station (18)","189 Hall Street (14)"] | Historical baseline for where this crime type most often appears.
// Criminal damage and arson | ["Parking Area (74)","Supermarket (39)","Petrol Station (26)","Shopping Area (26)","Sports/Recreation Area (22)"] | Historical baseline for where this crime type most often appears.
// Drugs | ["Piccadilly (23)","Parking Area (8)","Nightclub (6)","Police Station (6)","Prison (6)"] | Historical baseline for where this crime type most often appears.
// Other crime | ["Prison (24)","135 Barracks Road (12)","Parking Area (11)","Pedestrian Subway (7)","Supermarket (6)"] | Historical baseline for where this crime type most often appears.
// Other theft | ["Parking Area (77)","Petrol Station (73)","Shopping Area (60)","Nightclub (56)","Supermarket (44)"] | Historical baseline for where this crime type most often appears.
// Possession of weapons | ["Parking Area (12)","141 Airport/Airfield (9)","Piccadilly (5)","Nightclub (4)","Sports/Recreation Area (4)"] | Historical baseline for where this crime type most often appears.
// Public order | ["Parking Area (135)","Supermarket (120)","Shopping Area (91)","Nightclub (54)","Petrol Station (52)"] | Historical baseline for where this crime type most often appears.
// Robbery | ["Parking Area (24)","Piccadilly (20)","Shopping Area (14)","Supermarket (13)","Nightclub (11)"] | Historical baseline for where this crime type most often appears.
// Shoplifting | ["Shopping Area (251)","Supermarket (214)","Parking Area (106)","Bus/Coach Station (45)","Petrol Station (37)"] | Historical baseline for where this crime type most often appears.
// Theft from the person | ["Nightclub (48)","Shopping Area (30)","Parking Area (25)","Piccadilly (14)","Supermarket (13)"] | Historical baseline for where this crime type most often appears.
// Vehicle crime | ["Parking Area (58)","Petrol Station (27)","Shopping Area (19)","Supermarket (19)","Park/Open Space (14)"] | Historical baseline for where this crime type most often appears.
// Violence and sexual offences | ["Parking Area (214)","Supermarket (103)","Nightclub (95)","Petrol Station (66)","Shopping Area (64)"] | Historical baseline for where this crime type most often appears.

// ==================================================
// QUERY 21
// ==================================================
// Query 2.6 - Vehicle-crime-location context.
MATCH (v:Vehicle)-[:INVOLVED_IN]->(c:Crime)-[:OCCURRED_AT]->(l:Location)
RETURN c.type AS crimeType,
       l.address AS location,
       count(v) AS involvedVehicles,
       count(DISTINCT c) AS crimes
ORDER BY involvedVehicles DESC, crimes DESC, location
LIMIT 25;

// RESULT 21
// --------------------------------------------------
// crimeType | location | involvedVehicles | crimes
// Vehicle crime | Parking Area | 20 | 20
// Vehicle crime | Petrol Station | 12 | 12
// Vehicle crime | Shopping Area | 10 | 10
// Vehicle crime | Supermarket | 9 | 9
// Vehicle crime | Nightclub | 8 | 8
// Vehicle crime | 31 Lower Chatham Street | 5 | 5
// Vehicle crime | 190 Brooklands | 4 | 4
// Vehicle crime | 10 Central Drive | 3 | 3
// Vehicle crime | 111 Gatley Avenue | 3 | 3
// Vehicle crime | 121 Broomhall Road | 3 | 3
// Vehicle crime | 153 Hector Road | 3 | 3
// Vehicle crime | 154 Cotton Lane | 3 | 3
// Vehicle crime | 179 Parkville Road | 3 | 3
// Vehicle crime | 198 Princess Road | 3 | 3
// Vehicle crime | 3 Albert Road | 3 | 3
// Vehicle crime | 36 Sackville Street | 3 | 3
// Vehicle crime | 38 International Approach | 3 | 3
// Vehicle crime | 40 Old Lansdowne Road | 3 | 3
// Vehicle crime | 46 Viscount Street | 3 | 3
// Vehicle crime | 61 Victoria Street | 3 | 3
// Vehicle crime | 65 Domestic Approach | 3 | 3
// Vehicle crime | 7 Bella Street | 3 | 3
// Vehicle crime | 70 Cateaton Street | 3 | 3
// Vehicle crime | 70 Gwelo Street | 3 | 3
// Vehicle crime | 74 Lanstead Drive | 3 | 3

// ==================================================
// QUERY 22
// ==================================================
// Query 2.7 - Repeated vehicle involvement check.
MATCH (v:Vehicle)
OPTIONAL MATCH (v)-[:INVOLVED_IN]->(c:Crime)
WITH v, count(c) AS linkedCrimes
RETURN linkedCrimes,
       count(v) AS vehicles,
       CASE
         WHEN linkedCrimes <= 1 THEN 'Weak vehicle link-prediction signal'
         ELSE 'Potential repeated vehicle pattern'
       END AS vehicleReading
ORDER BY linkedCrimes DESC;

// RESULT 22
// --------------------------------------------------
// linkedCrimes | vehicles | vehicleReading
// 1 | 978 | Weak vehicle link-prediction signal
// 0 | 22 | Weak vehicle link-prediction signal

// ==================================================
// QUERY 23
// ==================================================
// SECTION 3: SOCIAL GRAPH ANALYTICS

// Query 3.1 - Social relationship mix.
MATCH (:Person)-[r]->(:Person)
WHERE type(r) IN ['KNOWS', 'KNOWS_SN', 'KNOWS_PHONE', 'KNOWS_LW', 'FAMILY_REL']
RETURN type(r) AS relationshipType,
       count(r) AS directedLinks,
       count(DISTINCT startNode(r)) AS distinctSources,
       count(DISTINCT endNode(r)) AS distinctTargets
ORDER BY directedLinks DESC;

// RESULT 23
// --------------------------------------------------
// relationshipType | directedLinks | distinctSources | distinctTargets
// KNOWS | 586 | 233 | 312
// KNOWS_SN | 241 | 38 | 241
// FAMILY_REL | 155 | 104 | 104
// KNOWS_PHONE | 118 | 118 | 118
// KNOWS_LW | 80 | 60 | 62

// ==================================================
// QUERY 24
// ==================================================
// Query 3.2 - Social coverage.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN count(p) AS people,
       sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) AS sociallyConnectedPeople,
       sum(CASE WHEN socialDegree = 0 THEN 1 ELSE 0 END) AS sociallyIsolatedPeople,
       round(1000.0 * sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS sociallyConnectedPercent;

// RESULT 24
// --------------------------------------------------
// people | sociallyConnectedPeople | sociallyIsolatedPeople | sociallyConnectedPercent
// 369 | 346 | 23 | 93.8

// ==================================================
// QUERY 25
// ==================================================
// Query 3.3 - Project the social graph for GDS community and centrality.
CALL gds.graph.project(
  'revisedSocialGraph',
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

// RESULT 25
// --------------------------------------------------
// graphName | nodeCount | relationshipCount | approximateDensity
// revisedSocialGraph | 369 | 2360 | 0.01738

// ==================================================
// QUERY 26
// ==================================================
// Query 3.4 - PageRank: socially central people.
CALL gds.pageRank.stream('revisedSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS pageRankScore
ORDER BY pageRankScore DESC
LIMIT 15;

// RESULT 26
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
// QUERY 27
// ==================================================
// Query 3.5 - Louvain communities with observed crime context.
CALL gds.louvain.write(
  'revisedSocialGraph',
  {writeProperty: 'revisedSocialCommunityId'}
)
YIELD communityCount, modularity
RETURN communityCount,
       modularity,
       CASE
         WHEN modularity >= 0.5 THEN 'Strong community structure.'
         WHEN modularity >= 0.3 THEN 'Moderate community structure.'
         ELSE 'Weak community structure.'
       END AS communityReading;

// RESULT 27
// --------------------------------------------------
// communityCount | modularity | communityReading
// 41 | 0.6709580580293019 | Strong community structure.

// ==================================================
// QUERY 28
// ==================================================
// Query 3.6 - Community crime-context concentration.
MATCH (p:Person)
WHERE p.revisedSocialCommunityId IS NOT NULL
OPTIONAL MATCH (p)-[:PARTY_TO]-(c:Crime)
WITH p.revisedSocialCommunityId AS communityId,
     p,
     count(c) AS observedCrimeLinks
WITH communityId,
     count(p) AS people,
     sum(CASE WHEN observedCrimeLinks > 0 THEN 1 ELSE 0 END) AS crimeLinkedPeople,
     sum(observedCrimeLinks) AS totalObservedPartyToLinks,
     collect(p.name + ' ' + coalesce(p.surname, ''))[0..8] AS exampleMembers
WHERE totalObservedPartyToLinks > 0
RETURN communityId,
       people,
       crimeLinkedPeople,
       totalObservedPartyToLinks,
       round(1000.0 * crimeLinkedPeople / people) / 10.0 AS crimeLinkedPeoplePercent,
       exampleMembers,
       'Community-level context is stronger and safer than individual Person-Crime prediction.' AS reading
ORDER BY totalObservedPartyToLinks DESC, crimeLinkedPeoplePercent DESC
LIMIT 15;

// RESULT 28
// --------------------------------------------------
// communityId | people | crimeLinkedPeople | totalObservedPartyToLinks | crimeLinkedPeoplePercent | exampleMembers | reading
// 239 | 10 | 8 | 29 | 80.0 | ["William Dixon","Raymond Walker","Kathleen Peters","Diana Murray","Kathy Wheeler","Alan Ward","Jack Powell","Phillip Williamson"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 237 | 22 | 6 | 9 | 27.3 | ["Phillip Myers","Mary Young","Stephanie Hughes","Pamela Gibson","Maria Hughes","Lawrence Stephens","Raymond Williamson","Jennifer Rogers"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 331 | 22 | 3 | 5 | 13.6 | ["Sharon White","Anne Nguyen","Carlos Chavez","Melissa Warren","Paul Arnold","Philip Scott","Linda Baker","Rebecca Long"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 226 | 26 | 3 | 3 | 11.5 | ["Nancy Campbell","Todd Garcia","Rachel Turner","Ashley Robertson","Carl Hayes","Rose Parker","Phyllis Murray","Joshua Black"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 351 | 32 | 3 | 3 | 9.4 | ["Todd Hamilton","Benjamin Hamilton","Diane Cox","Ryan Castillo","Dennis Ford","Justin Arnold","Donna Jordan","Norma Payne"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 251 | 16 | 2 | 2 | 12.5 | ["Philip Mason","Dennis Mcdonald","Sandra Ruiz","David Mills","Kelly Peterson","Amanda Robertson","Richard Coleman","Elizabeth Anderson"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 162 | 16 | 1 | 1 | 6.3 | ["Denise Rodriguez","Nicholas Mason","Rebecca Lee","Jeffrey Lewis","Alice Mcdonald","Randy Edwards","Matthew Phillips","Annie George"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 122 | 28 | 1 | 1 | 3.6 | ["Mildred Kelly","Stephen Perez","Lawrence Warren","Paul Nguyen","Stephanie Lynch","Ashley Bennett","Janice Coleman","Patrick Sanders"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 328 | 31 | 1 | 1 | 3.2 | ["Scott Kelly","Rose Crawford","Christine Brown","Heather Howard","Rachel Bradley","Rachel Hunter","Diane Wagner","Judith Moore"] | Community-level context is stronger and safer than individual Person-Crime prediction.
// 249 | 32 | 1 | 1 | 3.1 | ["Mary Peters","Irene Austin","Harry Garrett","Eugene Ferguson","Douglas Cole","Wanda Webb","Kevin Hawkins","Jennifer Gray"] | Community-level context is stronger and safer than individual Person-Crime prediction.

// ==================================================
// QUERY 29
// ==================================================
// SECTION 4: MAIN GML PIPELINE - PERSON-PERSON SOCIAL-FAMILY LINK PREDICTION

// Query 4.1 - Materialize a temporary unified social-family target.
MATCH (p:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(q:Person)
WHERE elementId(p) < elementId(q)
MERGE (p)-[:OBSERVED_SOCIAL_LINK_TMP]->(q);

// RESULT 29
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 30
// ==================================================
// Query 4.2 - Unified social target size and imbalance.
MATCH (p:Person)
WITH count(p) AS people
MATCH (:Person)-[:OBSERVED_SOCIAL_LINK_TMP]->(:Person)
WITH people, count(*) AS socialLinks
RETURN people,
       socialLinks,
       people * (people - 1) AS possibleDirectedPersonPairs,
       round(1000000.0 * socialLinks / (people * (people - 1))) / 10000.0 AS positiveClassPercent,
       'Unified social-family target combines KNOWS, phone, social-network, living-with, and family evidence for review-only association prediction.' AS targetReading;

// RESULT 30
// --------------------------------------------------
// people | socialLinks | possibleDirectedPersonPairs | positiveClassPercent | targetReading
// 369 | 586 | 135792 | 0.4315 | Unified social-family target combines KNOWS, phone, social-network, living-with, and family evidence for review-only association prediction.

// ==================================================
// QUERY 31
// ==================================================
// Query 4.3 - Project a context graph for social-family link prediction.
CALL gds.graph.project(
  'socialFamilyContextGraph',
  ['Person', 'Phone', 'Email', 'Location', 'Crime'],
  {
    OBSERVED_SOCIAL_LINK_TMP: {orientation: 'UNDIRECTED'},
    HAS_PHONE: {orientation: 'UNDIRECTED'},
    HAS_EMAIL: {orientation: 'UNDIRECTED'},
    CURRENT_ADDRESS: {orientation: 'UNDIRECTED'},
    PARTY_TO: {orientation: 'UNDIRECTED'},
    OCCURRED_AT: {orientation: 'UNDIRECTED'}
  }
)
YIELD graphName, nodeCount, relationshipCount, projectMillis
RETURN graphName,
       nodeCount,
       relationshipCount,
       projectMillis;

// RESULT 31
// --------------------------------------------------
// graphName | nodeCount | relationshipCount | projectMillis
// socialFamilyContextGraph | 44691 | 60854 | 72

// ==================================================
// QUERY 32
// ==================================================
// Query 4.4 - Create link-prediction pipeline.
CALL gds.beta.pipeline.linkPrediction.create('social-family-lp-pipeline')
YIELD name
RETURN name AS pipeline;

// RESULT 32
// --------------------------------------------------
// pipeline
// social-family-lp-pipeline

// ==================================================
// QUERY 33
// ==================================================
// Query 4.5 - Add FastRP embeddings.
CALL gds.beta.pipeline.linkPrediction.addNodeProperty(
  'social-family-lp-pipeline',
  'fastRP',
  {
    mutateProperty: 'fastRpEmbedding',
    embeddingDimension: 128,
    iterationWeights: [0.0, 1.0, 1.0, 1.0],
    randomSeed: 42
  }
)
YIELD nodePropertySteps
RETURN nodePropertySteps;

// RESULT 33
// --------------------------------------------------
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0,1.0],"embeddingDimension":128,"contextNodeLabels":[],"mutateProperty":"fastRpEmbedding"}}]

// ==================================================
// QUERY 34
// ==================================================
// Query 4.6 - Add Node2Vec embeddings.
CALL gds.beta.pipeline.linkPrediction.addNodeProperty(
  'social-family-lp-pipeline',
  'node2vec',
  {
    mutateProperty: 'node2vecEmbedding',
    embeddingDimension: 64,
    walkLength: 20,
    walksPerNode: 10,
    randomSeed: 42
  }
)
YIELD nodePropertySteps
RETURN nodePropertySteps;

// RESULT 34
// --------------------------------------------------
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0,1.0],"embeddingDimension":128,"contextNodeLabels":[],"mutateProperty":"fastRpEmbedding"}},{"name":"gds.node2vec.mutate","config":{"randomSeed":42,"walkLength":20,"walksPerNode":10,"contextRelationshipTypes":[],"embeddingDimension":64,"contextNodeLabels":[],"mutateProperty":"node2vecEmbedding"}}]

// ==================================================
// QUERY 35
// ==================================================
// Query 4.7 - Add pairwise FastRP feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'social-family-lp-pipeline',
  'hadamard',
  {nodeProperties: ['fastRpEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// RESULT 35
// --------------------------------------------------
// featureSteps
// [{"name":"HADAMARD","config":{"nodeProperties":["fastRpEmbedding"]}}]

// ==================================================
// QUERY 36
// ==================================================
// Query 4.8 - Add pairwise Node2Vec feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'social-family-lp-pipeline',
  'hadamard',
  {nodeProperties: ['node2vecEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// RESULT 36
// --------------------------------------------------
// featureSteps
// [{"name":"HADAMARD","config":{"nodeProperties":["fastRpEmbedding"]}},{"name":"HADAMARD","config":{"nodeProperties":["node2vecEmbedding"]}}]

// ==================================================
// QUERY 37
// ==================================================
// Query 4.9 - Configure train/test split.
CALL gds.beta.pipeline.linkPrediction.configureSplit(
  'social-family-lp-pipeline',
  {
    testFraction: 0.20,
    trainFraction: 0.60,
    validationFolds: 3,
    negativeSamplingRatio: 1.0
  }
)
YIELD splitConfig
RETURN splitConfig;

// RESULT 37
// --------------------------------------------------
// splitConfig
// {"negativeSamplingRatio":1.0,"testFraction":0.2,"validationFolds":3,"trainFraction":0.6}

// ==================================================
// QUERY 38
// ==================================================
// Query 4.10 - Model-selection note from the experiment sweep.
RETURN 'Logistic Regression was tested during the experiment sweep. It can score higher AUCPR, but its live probabilities are nearly flat. The final deployable review pipeline keeps Random Forest because it gives usable probability separation for human-review ranking.' AS modelSelectionNote;

// RESULT 38
// --------------------------------------------------
// modelSelectionNote
// Logistic Regression was tested during the experiment sweep. It can score higher AUCPR, but its live probabilities are nearly flat. The final deployable review pipeline keeps Random Forest because it gives usable probability separation for human-review ranking.

// ==================================================
// QUERY 39
// ==================================================
// Query 4.11 - Random Forest model candidate.
CALL gds.beta.pipeline.linkPrediction.addRandomForest(
  'social-family-lp-pipeline',
  {
    numberOfSamplesRatio: 1.0,
    numberOfDecisionTrees: 200,
    maxFeaturesRatio: 1.0
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// RESULT 39
// --------------------------------------------------
// parameterSpace
// {"MultilayerPerceptron":[],"RandomForest":[{"maxDepth":2147483647,"minLeafSize":1,"criterion":"GINI","minSplitSize":2,"numberOfDecisionTrees":200,"maxFeaturesRatio":1.0,"methodName":"RandomForest","numberOfSamplesRatio":1.0}],"LogisticRegression":[]}

// ==================================================
// QUERY 40
// ==================================================
// Query 4.12 - Confirm candidate model families before training.
CALL gds.pipeline.list('social-family-lp-pipeline')
YIELD pipelineInfo
RETURN pipelineInfo.trainingParameterSpace AS candidateModelFamilies,
       'GDS will compare candidate model families using validation AUCPR and keep the best trained model.' AS modelSelectionReading;

// RESULT 40
// --------------------------------------------------
// candidateModelFamilies | modelSelectionReading
// {"MultilayerPerceptron":[],"RandomForest":[{"maxDepth":2147483647,"minLeafSize":1,"criterion":"GINI","minSplitSize":2,"numberOfDecisionTrees":200,"maxFeaturesRatio":1.0,"methodName":"RandomForest","numberOfSamplesRatio":1.0}],"LogisticRegression":[]} | GDS will compare candidate model families using validation AUCPR and keep the best trained model.

// ==================================================
// QUERY 41
// ==================================================
// Query 4.13 - Train social-family link-prediction model.
CALL gds.beta.pipeline.linkPrediction.train(
  'socialFamilyContextGraph',
  {
    pipeline: 'social-family-lp-pipeline',
    modelName: 'social-family-lp-model',
    sourceNodeLabel: 'Person',
    targetNodeLabel: 'Person',
    targetRelationshipType: 'OBSERVED_SOCIAL_LINK_TMP',
    metrics: ['AUCPR'],
    randomSeed: 42
  }
)
YIELD modelInfo, trainMillis
RETURN trainMillis,
       modelInfo.metrics.AUCPR.train.avg AS trainAUCPR,
       modelInfo.metrics.AUCPR.validation.avg AS validationAUCPR,
       modelInfo.metrics.AUCPR.test AS testAUCPR,
       modelInfo.bestParameters.methodName AS selectedModel,
       modelInfo.bestParameters AS bestParameters,
       CASE
         WHEN modelInfo.metrics.AUCPR.test >= 0.70 THEN 'Strong enough for social-link review ranking.'
         WHEN modelInfo.metrics.AUCPR.test >= 0.50 THEN 'Weak but usable as a review-priority signal.'
         ELSE 'Not reliable enough even for social-link ranking.'
       END AS modelReading;

// RESULT 41
// --------------------------------------------------
// trainMillis | trainAUCPR | validationAUCPR | testAUCPR | selectedModel | bestParameters | modelReading
// 91532 | 0.9639827272375755 | 0.6270599114000692 | 0.5578128982282821 | RandomForest | {"maxDepth":2147483647,"minLeafSize":1,"criterion":"GINI","minSplitSize":2,"numberOfDecisionTrees":200,"maxFeaturesRatio":1.0,"methodName":"RandomForest","numberOfSamplesRatio":1.0} | Weak but usable as a review-priority signal.

// ==================================================
// QUERY 42
// ==================================================
// Query 4.11 - Explainable link prediction baseline: Common Neighbours.
MATCH (p1:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(shared:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH p1,
     p2,
     count(DISTINCT shared) AS commonNeighbours,
     collect(DISTINCT shared.name + ' ' + coalesce(shared.surname, ''))[0..5] AS explanation
WHERE commonNeighbours >= 3
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       commonNeighbours,
       explanation,
       'High-specificity Common Neighbours candidate for human review.' AS reading
ORDER BY commonNeighbours DESC, personA, personB
LIMIT 25;

// RESULT 42
// --------------------------------------------------
// personA | personB | commonNeighbours | explanation | reading
// Amanda Alexander | Kathryn Allen | 3 | ["Benjamin Hamilton","Denise Brown","Wanda Webb"] | High-specificity Common Neighbours candidate for human review.
// Jessica Kelly | Alan Ward | 3 | ["Brian Morales","Phillip Williamson","Kathy Wheeler"] | High-specificity Common Neighbours candidate for human review.
// Roy Dean | Harry Lopez | 3 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | High-specificity Common Neighbours candidate for human review.
// Roy Dean | Jonathan Hunt | 3 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | High-specificity Common Neighbours candidate for human review.

// ==================================================
// QUERY 43
// ==================================================
// Query 4.12 - Explainable link prediction baseline: Adamic Adar style score.
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
     collect(shared.name + ' ' + coalesce(shared.surname, ''))[0..5] AS explanation
WHERE commonNeighbours >= 2
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       commonNeighbours,
       adamicAdarScore,
       explanation,
       'Higher score means the shared neighbours are more specific.' AS reading
ORDER BY adamicAdarScore DESC, commonNeighbours DESC
LIMIT 25;

// RESULT 43
// --------------------------------------------------
// personA | personB | commonNeighbours | adamicAdarScore | explanation | reading
// Jessica Kelly | Alan Ward | 3 | 1.2710185681883481 | ["Brian Morales","Phillip Williamson","Kathy Wheeler"] | Higher score means the shared neighbours are more specific.
// Amanda Alexander | Kathryn Allen | 3 | 1.2490010295615737 | ["Benjamin Hamilton","Denise Brown","Wanda Webb"] | Higher score means the shared neighbours are more specific.
// Roy Dean | Harry Lopez | 3 | 1.150622159140651 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Higher score means the shared neighbours are more specific.
// Roy Dean | Jonathan Hunt | 3 | 1.150622159140651 | ["Phillip Perry","Peter Bryant","Deborah Ford"] | Higher score means the shared neighbours are more specific.
// Bruce Baker | Jeffrey Campbell | 2 | 1.1162212531024944 | ["Gloria Owens","Mildred Kelly"] | Higher score means the shared neighbours are more specific.
// Justin Arnold | Arthur Willis | 2 | 1.0743036443092429 | ["Donna Jordan","Amy Murphy"] | Higher score means the shared neighbours are more specific.
// Angela Mccoy | Phillip Perry | 2 | 1.039008973514235 | ["Todd Garcia","Roy Dean"] | Higher score means the shared neighbours are more specific.
// Ernest Thompson | Andrea George | 2 | 1.039008973514235 | ["Louis Hughes","Ruby Reynolds"] | Higher score means the shared neighbours are more specific.
// Amy Murphy | Ann Fox | 2 | 0.9605402309330919 | ["Justin Arnold","Jessica Kelly"] | Higher score means the shared neighbours are more specific.
// Dorothy Hall | Arthur Willis | 2 | 0.9481928242730024 | ["Kathy Harper","Kimberly Wood"] | Higher score means the shared neighbours are more specific.
// Doris Nichols | Dorothy Hall | 2 | 0.9151928288662396 | ["Ruth Hansen","Kathy Harper"] | Higher score means the shared neighbours are more specific.
// Jessica Kelly | Kathleen Peters | 2 | 0.9151928288662396 | ["Phillip Williamson","Diana Murray"] | Higher score means the shared neighbours are more specific.
// Diana Murray | Alan Ward | 2 | 0.9151928288662396 | ["Kathleen Peters","Kathy Wheeler"] | Higher score means the shared neighbours are more specific.
// Patricia Butler | Arthur Willis | 2 | 0.9151928288662396 | ["Michael Martin","Kathy Harper"] | Higher score means the shared neighbours are more specific.
// Raymond Walker | Alan Ward | 2 | 0.9151928288662396 | ["Kathleen Peters","Phillip Williamson"] | Higher score means the shared neighbours are more specific.
// Patricia Hanson | Donald Johnston | 2 | 0.9151928288662396 | ["Joshua Mccoy","Peter Turner"] | Higher score means the shared neighbours are more specific.
// Wayne Nguyen | Nancy Hughes | 2 | 0.9040868828124409 | ["John Jacobs","Adam Bradley"] | Higher score means the shared neighbours are more specific.
// Amy Murphy | Donna Jordan | 2 | 0.8919188272465812 | ["Arthur Willis","Justin Arnold"] | Higher score means the shared neighbours are more specific.
// Phillip Williamson | Diana Murray | 2 | 0.8833279513448324 | ["Jessica Kelly","Kathleen Peters"] | Higher score means the shared neighbours are more specific.
// Christopher Oliver | Arthur Willis | 2 | 0.8727686069953721 | ["Jason Hamilton","Annie Duncan"] | Higher score means the shared neighbours are more specific.
// Kathleen Peters | Kathy Wheeler | 2 | 0.8415721071852287 | ["Diana Murray","Alan Ward"] | Higher score means the shared neighbours are more specific.
// Bonnie Gilbert | Pamela Gibson | 2 | 0.833854470827749 | ["Amy Bailey","Stephanie Hughes"] | Higher score means the shared neighbours are more specific.
// Stephanie Hughes | Amy Bailey | 2 | 0.8205216188580964 | ["Pamela Gibson","Bonnie Gilbert"] | Higher score means the shared neighbours are more specific.
// Michael Martin | Kathy Harper | 2 | 0.814706547658322 | ["Patricia Butler","Arthur Willis"] | Higher score means the shared neighbours are more specific.
// Jason Hamilton | Annie Duncan | 2 | 0.814706547658322 | ["Christopher Oliver","Arthur Willis"] | Higher score means the shared neighbours are more specific.

// ==================================================
// QUERY 44
// ==================================================
// Query 4.13 - Write conservative explainable social candidates.
CALL {
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
       collect(shared.name + ' ' + coalesce(shared.surname, ''))[0..5] AS explanation
  WHERE commonNeighbours >= 3
     OR adamicAdarScore >= 1.15
  RETURN p1, p2, commonNeighbours, adamicAdarScore, explanation
  ORDER BY adamicAdarScore DESC, commonNeighbours DESC
  LIMIT 25
}
MERGE (p1)-[r:PREDICTED_SOCIAL_EXPLAINABLE]->(p2)
SET r.commonNeighbours = commonNeighbours,
    r.adamicAdarScore = adamicAdarScore,
    r.explanation = explanation,
    r.note = 'Review-only explainable social link prediction. Not evidence of crime.'
RETURN count(r) AS writtenExplainableReviewLinks,
       'Explainable candidates were written because they have clear shared-neighbour evidence.' AS writeBackReading;

// RESULT 44
// --------------------------------------------------
// writtenExplainableReviewLinks | writeBackReading
// 4 | Explainable candidates were written because they have clear shared-neighbour evidence.

// ==================================================
// QUERY 45
// ==================================================
// Query 4.14 - Calibration check for supervised predicted social links.
CALL gds.model.list('social-family-lp-model')
YIELD modelInfo
WITH modelInfo.metrics.AUCPR.test AS testAUCPR,
     modelInfo.bestParameters.methodName AS selectedModel
CALL gds.beta.pipeline.linkPrediction.predict.stream(
  'socialFamilyContextGraph',
  {modelName: 'social-family-lp-model', topN: 200}
)
YIELD node1, node2, probability
WITH testAUCPR,
     selectedModel,
     gds.util.asNode(node1) AS p1,
     gds.util.asNode(node2) AS p2,
     probability
WHERE p1:Person
  AND p2:Person
  AND elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH count(*) AS candidateLinks,
     testAUCPR,
     selectedModel,
     min(probability) AS lowestProbability,
     max(probability) AS highestProbability,
     avg(probability) AS averageProbability
RETURN candidateLinks,
       selectedModel,
       testAUCPR,
       lowestProbability,
       highestProbability,
       averageProbability,
       highestProbability - lowestProbability AS probabilityBand,
       CASE
         WHEN candidateLinks = 0 THEN 'No unseen Person-Person candidates returned.'
         WHEN testAUCPR < 0.50 THEN 'Do not write back. Held-out test AUCPR is too weak.'
         WHEN highestProbability - lowestProbability < 0.01 THEN 'Do not write back. Scores are too flat.'
         ELSE 'Scores have separation. Candidate social links can be reviewed.'
       END AS deploymentDecision;

// RESULT 45
// --------------------------------------------------
// candidateLinks | selectedModel | testAUCPR | lowestProbability | highestProbability | averageProbability | probabilityBand | deploymentDecision
// 130 | RandomForest | 0.5578128982282821 | 0.705 | 0.885 | 0.7449230769230767 | 0.18000000000000005 | Scores have separation. Candidate social links can be reviewed.

// ==================================================
// QUERY 46
// ==================================================
// Query 4.15 - Top supervised candidate social links for comparison.
CALL gds.beta.pipeline.linkPrediction.predict.stream(
  'socialFamilyContextGraph',
  {modelName: 'social-family-lp-model', topN: 50}
)
YIELD node1, node2, probability
WITH gds.util.asNode(node1) AS p1,
     gds.util.asNode(node2) AS p2,
     probability
WHERE p1:Person
  AND p2:Person
  AND elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
OPTIONAL MATCH (p1)-[:CURRENT_ADDRESS]->(sharedAddress:Location)<-[:CURRENT_ADDRESS]-(p2)
OPTIONAL MATCH (p1)-[:PARTY_TO]-(c1:Crime)
OPTIONAL MATCH (p2)-[:PARTY_TO]-(c2:Crime)
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       probability,
       count(DISTINCT sharedAddress) AS sharedAddressCount,
       count(DISTINCT c1) AS personAObservedCrimeLinks,
       count(DISTINCT c2) AS personBObservedCrimeLinks,
       'Candidate social/context link for review only.' AS reading
ORDER BY probability DESC
LIMIT 25;

// RESULT 46
// --------------------------------------------------
// personA | personB | probability | sharedAddressCount | personAObservedCrimeLinks | personBObservedCrimeLinks | reading
// Raymond Williamson | Dennis Bradley | 0.87 | 0 | 0 | 0 | Candidate social/context link for review only.
// Sandra Payne | Philip Welch | 0.865 | 0 | 0 | 0 | Candidate social/context link for review only.
// Nicholas Mason | Justin Payne | 0.85 | 0 | 0 | 0 | Candidate social/context link for review only.
// Matthew Phillips | Justin Payne | 0.845 | 0 | 0 | 0 | Candidate social/context link for review only.
// Richard Hanson | Norma Jackson | 0.84 | 0 | 0 | 0 | Candidate social/context link for review only.
// Nicholas Mason | Matthew Phillips | 0.84 | 0 | 0 | 0 | Candidate social/context link for review only.
// Craig Gordon | Kelly Franklin | 0.83 | 0 | 0 | 0 | Candidate social/context link for review only.
// Jennifer Jacobs | Maria Rivera | 0.83 | 0 | 0 | 0 | Candidate social/context link for review only.
// Lawrence Warren | Jeffrey Campbell | 0.82 | 0 | 0 | 0 | Candidate social/context link for review only.
// Barbara Torres | Kelly Franklin | 0.815 | 0 | 0 | 0 | Candidate social/context link for review only.
// Heather Howard | Jennifer Jacobs | 0.805 | 0 | 0 | 0 | Candidate social/context link for review only.
// Rebecca Lee | Justin Payne | 0.805 | 0 | 0 | 0 | Candidate social/context link for review only.
// Heather Howard | Maria Rivera | 0.805 | 0 | 0 | 0 | Candidate social/context link for review only.
// Rebecca Lee | Matthew Phillips | 0.805 | 0 | 0 | 0 | Candidate social/context link for review only.
// Timothy Garza | Deborah Ford | 0.8 | 0 | 0 | 0 | Candidate social/context link for review only.
// Carl Hayes | Angela Mccoy | 0.79 | 0 | 0 | 0 | Candidate social/context link for review only.
// Timothy Garza | Phillip Perry | 0.785 | 0 | 0 | 0 | Candidate social/context link for review only.
// Michael Mason | Philip Welch | 0.785 | 0 | 0 | 0 | Candidate social/context link for review only.
// Jeremy Barnes | William Lawrence | 0.785 | 0 | 0 | 0 | Candidate social/context link for review only.
// Denise Rodriguez | Jeffrey Lewis | 0.78 | 0 | 0 | 0 | Candidate social/context link for review only.
// Sharon White | Mildred Spencer | 0.78 | 0 | 0 | 0 | Candidate social/context link for review only.
// Thomas Harrison | Phillip Carr | 0.78 | 0 | 0 | 0 | Candidate social/context link for review only.
// Timothy Garza | Peter Bryant | 0.775 | 0 | 0 | 0 | Candidate social/context link for review only.
// Rose Crawford | Eric Black | 0.775 | 0 | 0 | 0 | Candidate social/context link for review only.
// Lawrence Warren | Gloria Owens | 0.775 | 0 | 0 | 0 | Candidate social/context link for review only.

// ==================================================
// QUERY 47
// ==================================================
// Query 4.16 - Conservative write-back of supervised review-only social candidates.
CALL {
  CALL gds.model.list('social-family-lp-model')
  YIELD modelInfo
  WITH modelInfo.metrics.AUCPR.test AS testAUCPR
  CALL gds.beta.pipeline.linkPrediction.predict.stream(
    'socialFamilyContextGraph',
    {modelName: 'social-family-lp-model', topN: 200}
  )
  YIELD node1, node2, probability
  WITH testAUCPR,
       gds.util.asNode(node1) AS p1,
       gds.util.asNode(node2) AS p2,
       probability
  WHERE p1:Person
    AND p2:Person
    AND elementId(p1) < elementId(p2)
    AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
  RETURN collect({p1: p1, p2: p2, probability: probability}) AS candidates,
         testAUCPR,
         min(probability) AS lowestProbability,
         max(probability) AS highestProbability
}
WITH candidates, lowestProbability, highestProbability,
     highestProbability - lowestProbability AS probabilityBand,
     testAUCPR
WITH [candidate IN candidates
      WHERE testAUCPR >= 0.50
        AND probabilityBand >= 0.01
        AND candidate.probability >= 0.55][0..25] AS writeCandidates
CALL {
  WITH writeCandidates
  UNWIND writeCandidates AS candidate
  WITH candidate.p1 AS p1,
       candidate.p2 AS p2,
       candidate.probability AS probability
  MERGE (p1)-[r:PREDICTED_SOCIAL_REVIEW]->(p2)
  SET r.probability = probability,
      r.model = 'social-family-lp-model',
      r.note = 'Review-only predicted social/context link. Not evidence of crime.'
  RETURN count(r) AS writtenReviewLinks
}
RETURN writtenReviewLinks,
       'Review-only PREDICTED_SOCIAL_REVIEW relationships are written only when held-out AUCPR and probability spread both pass the gate.' AS writeBackReading;

// RESULT 47
// --------------------------------------------------
// writtenReviewLinks | writeBackReading
// 25 | Review-only PREDICTED_SOCIAL_REVIEW relationships are written only when held-out AUCPR and probability spread both pass the gate.

// ==================================================
// QUERY 48
// ==================================================
// Query 4.17 - Remove temporary stored target after the in-memory model is trained.
MATCH ()-[r:OBSERVED_SOCIAL_LINK_TMP]->()
DELETE r;

// RESULT 48
// --------------------------------------------------
// 
// No rows returned

// ==================================================
// QUERY 49
// ==================================================
// Query 4.18 - GML decision table for the final demo.
MATCH ()-[explainable:PREDICTED_SOCIAL_EXPLAINABLE]->()
WITH count(explainable) AS explainableReviewLinks
OPTIONAL MATCH ()-[supervised:PREDICTED_SOCIAL_REVIEW]->()
RETURN explainableReviewLinks,
       count(supervised) AS supervisedReviewLinks,
       CASE
         WHEN explainableReviewLinks > 0 AND count(supervised) = 0
         THEN 'Use explainable Common Neighbours and Adamic Adar candidates in the demo. Supervised write-back remains blocked because held-out quality or calibration is too weak.'
         WHEN count(supervised) > 0
         THEN 'Both explainable and supervised candidates are available for review.'
         ELSE 'No candidate write-back should be shown.'
       END AS gmlDemoDecision;

// RESULT 49
// --------------------------------------------------
// explainableReviewLinks | supervisedReviewLinks | gmlDemoDecision
// 4 | 25 | Both explainable and supervised candidates are available for review.

// ==================================================
// QUERY 50
// ==================================================
// SECTION 5: SECONDARY ML AND UNSUPERVISED EXPERIMENTS

// Query 5.1 - Project social graph for unsupervised embedding similarity.
CALL gds.graph.project(
  'socialEmbeddingGraph',
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
       'Used for unsupervised FastRP + kNN candidate discovery.' AS experimentReading;

// RESULT 50
// --------------------------------------------------
// graphName | nodeCount | relationshipCount | experimentReading
// socialEmbeddingGraph | 369 | 2360 | Used for unsupervised FastRP + kNN candidate discovery.

// ==================================================
// QUERY 51
// ==================================================
// Query 5.2 - Create FastRP embeddings for unsupervised social similarity.
CALL gds.fastRP.mutate(
  'socialEmbeddingGraph',
  {
    mutateProperty: 'embedding',
    embeddingDimension: 32,
    iterationWeights: [0.0, 1.0, 1.0],
    randomSeed: 42
  }
)
YIELD nodePropertiesWritten, mutateMillis
RETURN nodePropertiesWritten,
       mutateMillis;

// RESULT 51
// --------------------------------------------------
// nodePropertiesWritten | mutateMillis
// 369 | 2

// ==================================================
// QUERY 52
// ==================================================
// Query 5.3 - Unsupervised kNN social-similarity candidates.
CALL gds.knn.stream(
  'socialEmbeddingGraph',
  {
    nodeProperties: ['embedding'],
    topK: 5,
    similarityCutoff: 0.7,
    randomSeed: 42,
    concurrency: 1
  }
)
YIELD node1, node2, similarity
WITH gds.util.asNode(node1) AS p1,
     gds.util.asNode(node2) AS p2,
     similarity
WHERE elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       similarity,
       'Unsupervised embedding candidate: structurally similar social context, review only.' AS reading
ORDER BY similarity DESC, personA, personB
LIMIT 25;

// RESULT 52
// --------------------------------------------------
// personA | personB | similarity | reading
// Daniel Moreno | Mary Peters | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Heather Howard | Jennifer Jacobs | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Heather Howard | Maria Rivera | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Jennifer Jacobs | Maria Rivera | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Joseph Rogers | Peter Burns | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Matthew Phillips | Justin Payne | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Nicholas Mason | Justin Payne | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Nicholas Mason | Matthew Phillips | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Raymond Williamson | Dennis Bradley | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Richard Hanson | Norma Jackson | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Sandra Payne | Philip Welch | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Todd Hamilton | Frances Sullivan | 1.0 | Unsupervised embedding candidate: structurally similar social context, review only.
// Anne Clark | Jerry Fernandez | 0.9786435961723328 | Unsupervised embedding candidate: structurally similar social context, review only.
// Nancy Hughes | Larry Turner | 0.9715005159378052 | Unsupervised embedding candidate: structurally similar social context, review only.
// Timothy Garza | Deborah Ford | 0.9669255018234253 | Unsupervised embedding candidate: structurally similar social context, review only.
// Edward Green | Kathleen Rogers | 0.9662777185440063 | Unsupervised embedding candidate: structurally similar social context, review only.
// Randy Edwards | Jennifer Murray | 0.9662728309631348 | Unsupervised embedding candidate: structurally similar social context, review only.
// Timothy Garza | Peter Bryant | 0.964415431022644 | Unsupervised embedding candidate: structurally similar social context, review only.
// Jose Green | Dennis Bradley | 0.9614294767379761 | Unsupervised embedding candidate: structurally similar social context, review only.
// Jose Green | Raymond Williamson | 0.9614294767379761 | Unsupervised embedding candidate: structurally similar social context, review only.
// John Jacobs | Larry Turner | 0.9601535797119141 | Unsupervised embedding candidate: structurally similar social context, review only.
// Michael Mason | Lois Hernandez | 0.9583497643470764 | Unsupervised embedding candidate: structurally similar social context, review only.
// Randy Edwards | Lois Larson | 0.9580379724502563 | Unsupervised embedding candidate: structurally similar social context, review only.
// Louis Hughes | Ruby Reynolds | 0.9560292959213257 | Unsupervised embedding candidate: structurally similar social context, review only.
// Lawrence Warren | Gloria Owens | 0.9510976076126099 | Unsupervised embedding candidate: structurally similar social context, review only.

// ==================================================
// QUERY 53
// ==================================================
// Query 5.4 - Project crime-context graph for node classification.
CALL gds.graph.project(
  'crimeClassGraph',
  {
    Crime: {properties: ['crimeTypeClass']},
    Location: {},
    Officer: {},
    Vehicle: {},
    Object: {}
  },
  {
    OCCURRED_AT: {orientation: 'UNDIRECTED'},
    INVESTIGATED_BY: {orientation: 'UNDIRECTED'},
    INVOLVED_IN: {orientation: 'UNDIRECTED'}
  }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName,
       nodeCount,
       relationshipCount,
       'Secondary supervised task: predict broad crime type class from graph context.' AS experimentReading;

// RESULT 53
// --------------------------------------------------
// graphName | nodeCount | relationshipCount | experimentReading
// crimeClassGraph | 45673 | 117018 | Secondary supervised task: predict broad crime type class from graph context.

// ==================================================
// QUERY 54
// ==================================================
// Query 5.5 - Crime type class distribution.
MATCH (c:Crime)
WHERE c.crimeTypeClass IS NOT NULL
RETURN c.crimeTypeClass AS crimeTypeClass,
       c.type AS exampleCrimeType,
       count(c) AS crimes
ORDER BY crimes DESC;

// RESULT 54
// --------------------------------------------------
// crimeTypeClass | exampleCrimeType | crimes
// 12 | Violence and sexual offences | 8765
// 7 | Public order | 4839
// 2 | Criminal damage and arson | 3587
// 1 | Burglary | 2807
// 11 | Vehicle crime | 2598
// 5 | Other theft | 2140
// 9 | Shoplifting | 1427
// 4 | Other crime | 651
// 8 | Robbery | 541
// 10 | Theft from the person | 423
// 0 | Bicycle theft | 414
// 3 | Drugs | 333
// 6 | Possession of weapons | 236

// ==================================================
// QUERY 55
// ==================================================
// Query 5.6 - Create crime-class node-classification pipeline.
CALL gds.beta.pipeline.nodeClassification.create('crime-class-pipeline')
YIELD name
RETURN name AS pipeline;

// RESULT 55
// --------------------------------------------------
// pipeline
// crime-class-pipeline

// ==================================================
// QUERY 56
// ==================================================
// Query 5.7 - Add FastRP embeddings for crime-class classification.
CALL gds.beta.pipeline.nodeClassification.addNodeProperty(
  'crime-class-pipeline',
  'fastRP',
  {
    mutateProperty: 'embedding',
    embeddingDimension: 32,
    iterationWeights: [0.0, 1.0, 1.0],
    randomSeed: 42
  }
)
YIELD nodePropertySteps
RETURN nodePropertySteps;

// RESULT 56
// --------------------------------------------------
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0],"embeddingDimension":32,"contextNodeLabels":[],"mutateProperty":"embedding"}}]

// ==================================================
// QUERY 57
// ==================================================
// Query 5.8 - Select embedding feature.
CALL gds.beta.pipeline.nodeClassification.selectFeatures(
  'crime-class-pipeline',
  ['embedding']
)
YIELD featureProperties
RETURN featureProperties;

// RESULT 57
// --------------------------------------------------
// featureProperties
// ["embedding"]

// ==================================================
// QUERY 58
// ==================================================
// Query 5.9 - Configure crime-class split.
CALL gds.beta.pipeline.nodeClassification.configureSplit(
  'crime-class-pipeline',
  {
    testFraction: 0.20,
    validationFolds: 2
  }
)
YIELD splitConfig
RETURN splitConfig;

// RESULT 58
// --------------------------------------------------
// splitConfig
// {"testFraction":0.2,"validationFolds":2}

// ==================================================
// QUERY 59
// ==================================================
// Query 5.10 - Add Logistic Regression for crime-class classification.
CALL gds.beta.pipeline.nodeClassification.addLogisticRegression(
  'crime-class-pipeline',
  {
    maxEpochs: 30,
    learningRate: 0.01
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// RESULT 59
// --------------------------------------------------
// parameterSpace
// {"MultilayerPerceptron":[],"RandomForest":[],"LogisticRegression":[{"maxEpochs":30,"minEpochs":1,"classWeights":[],"penalty":0.0,"patience":1,"methodName":"LogisticRegression","focusWeight":0.0,"batchSize":100,"tolerance":0.001,"learningRate":0.01}]}

// ==================================================
// QUERY 60
// ==================================================
// Query 5.11 - Train crime-class classifier.
CALL gds.beta.pipeline.nodeClassification.train(
  'crimeClassGraph',
  {
    pipeline: 'crime-class-pipeline',
    modelName: 'crime-class-model',
    targetNodeLabels: ['Crime'],
    targetProperty: 'crimeTypeClass',
    metrics: ['F1_WEIGHTED', 'ACCURACY'],
    randomSeed: 42
  }
)
YIELD modelInfo, trainMillis
RETURN trainMillis,
       modelInfo.metrics.F1_WEIGHTED.train.avg AS trainWeightedF1,
       modelInfo.metrics.F1_WEIGHTED.validation.avg AS validationWeightedF1,
       modelInfo.metrics.F1_WEIGHTED.test AS testWeightedF1,
       modelInfo.metrics.ACCURACY.test AS testAccuracy,
       modelInfo.bestParameters.methodName AS selectedModel,
       CASE
         WHEN modelInfo.metrics.F1_WEIGHTED.test >= 0.50 THEN 'Useful crime-type classifier.'
         ELSE 'Weak classifier: graph structure alone does not recover crime type reliably.'
       END AS classifierReading;

// RESULT 60
// --------------------------------------------------
// trainMillis | trainWeightedF1 | validationWeightedF1 | testWeightedF1 | testAccuracy | selectedModel | classifierReading
// 2465 | 0.14192116073487668 | 0.14192116073487668 | 0.14407914891941245 | 0.30957762 | LogisticRegression | Weak classifier: graph structure alone does not recover crime type reliably.

// ==================================================
// QUERY 61
// ==================================================
// Query 5.12 - ML strategy comparison table.
MATCH ()-[explainable:PREDICTED_SOCIAL_EXPLAINABLE]->()
WITH count(explainable) AS explainableLinks
OPTIONAL MATCH ()-[supervised:PREDICTED_SOCIAL_REVIEW]->()
WITH explainableLinks, count(supervised) AS supervisedLinks
CALL gds.model.list('social-family-lp-model')
YIELD modelInfo AS lpModelInfo
WITH explainableLinks,
     supervisedLinks,
     lpModelInfo.metrics.AUCPR.test AS linkPredictionTestAUCPR,
     lpModelInfo.bestParameters.methodName AS linkPredictionSelectedModel
CALL gds.model.list('crime-class-model')
YIELD modelInfo AS crimeModelInfo
RETURN linkPredictionSelectedModel,
       linkPredictionTestAUCPR,
       supervisedLinks AS supervisedSocialWriteBackLinks,
       explainableLinks AS explainableSocialWriteBackLinks,
       crimeModelInfo.metrics.F1_WEIGHTED.test AS crimeClassTestWeightedF1,
       crimeModelInfo.metrics.ACCURACY.test AS crimeClassTestAccuracy,
       'Final ML stance: use supervised experiments as evidence, use explainable and unsupervised candidates for review, and do not overclaim weak held-out models.' AS strategyReading;

// RESULT 61
// --------------------------------------------------
// linkPredictionSelectedModel | linkPredictionTestAUCPR | supervisedSocialWriteBackLinks | explainableSocialWriteBackLinks | crimeClassTestWeightedF1 | crimeClassTestAccuracy | strategyReading
// RandomForest | 0.5578128982282821 | 25 | 4 | 0.14407914891941245 | 0.30957762 | Final ML stance: use supervised experiments as evidence, use explainable and unsupervised candidates for review, and do not overclaim weak held-out models.

// ==================================================
// QUERY 62
// ==================================================
// SECTION 6: REVIEW PRIORITY WITHOUT AUTOMATED ACCUSATION

// Query 6.1 - Review-priority people using observed graph context.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:PARTY_TO]-(own:Crime)
WITH p, count(DISTINCT own) AS ownCrimeLinks
OPTIONAL MATCH (p)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(nbr:Person)-[:PARTY_TO]-(nbrCrime:Crime)
WITH p,
     ownCrimeLinks,
     count(DISTINCT nbr) AS crimeLinkedNeighbours,
     count(DISTINCT nbrCrime) AS neighbourCrimeLinks,
     collect(DISTINCT nbr.name + ' ' + coalesce(nbr.surname, ''))[0..5] AS exampleCrimeLinkedNeighbours
OPTIONAL MATCH (p)-[:CURRENT_ADDRESS]->(home:Location)<-[:OCCURRED_AT]-(homeCrime:Crime)
WITH p,
     ownCrimeLinks,
     crimeLinkedNeighbours,
     neighbourCrimeLinks,
     exampleCrimeLinkedNeighbours,
     count(DISTINCT homeCrime) AS crimesAtCurrentAddress
WITH p,
     ownCrimeLinks,
     crimeLinkedNeighbours,
     neighbourCrimeLinks,
     exampleCrimeLinkedNeighbours,
     crimesAtCurrentAddress,
     ownCrimeLinks * 5 + crimeLinkedNeighbours * 2 + neighbourCrimeLinks + CASE WHEN crimesAtCurrentAddress > 0 THEN 1 ELSE 0 END AS reviewScore
WHERE reviewScore > 0
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       ownCrimeLinks,
       crimeLinkedNeighbours,
       neighbourCrimeLinks,
       crimesAtCurrentAddress,
       exampleCrimeLinkedNeighbours,
       reviewScore,
       CASE
         WHEN ownCrimeLinks > 0 THEN 'Observed PARTY_TO context. Human review only.'
         WHEN crimeLinkedNeighbours >= 3 THEN 'Social proximity context. Human review only.'
         ELSE 'Low-volume contextual signal. Human review only.'
       END AS reviewReading
ORDER BY reviewScore DESC, person
LIMIT 25;

// RESULT 62
// --------------------------------------------------
// person | ownCrimeLinks | crimeLinkedNeighbours | neighbourCrimeLinks | crimesAtCurrentAddress | exampleCrimeLinkedNeighbours | reviewScore | reviewReading
// Phillip Williamson | 5 | 5 | 17 | 1 | ["Brian Morales","Jessica Kelly","Raymond Walker","Kathleen Peters","Alan Ward"] | 53 | Observed PARTY_TO context. Human review only.
// Brian Morales | 4 | 4 | 17 | 1 | ["Phillip Williamson","Jessica Kelly","Alan Ward","Jack Powell"] | 46 | Observed PARTY_TO context. Human review only.
// Jessica Kelly | 5 | 3 | 12 | 1 | ["Brian Morales","Phillip Williamson","Diana Murray"] | 44 | Observed PARTY_TO context. Human review only.
// Alan Ward | 3 | 4 | 16 | 1 | ["Jack Powell","Brian Morales","Kathleen Peters","Phillip Williamson"] | 40 | Observed PARTY_TO context. Human review only.
// Kathleen Peters | 3 | 4 | 13 | 2 | ["Raymond Walker","Diana Murray","Phillip Williamson","Alan Ward"] | 37 | Observed PARTY_TO context. Human review only.
// Jack Powell | 4 | 2 | 7 | 0 | ["Alan Ward","Brian Morales"] | 31 | Observed PARTY_TO context. Human review only.
// Diana Murray | 3 | 2 | 8 | 2 | ["Kathleen Peters","Jessica Kelly"] | 28 | Observed PARTY_TO context. Human review only.
// Anne Freeman | 0 | 8 | 10 | 0 | ["Donald Robinson","Craig Marshall","Amanda Robertson","Ernest Clark","Lillian Martinez"] | 26 | Social proximity context. Human review only.
// Bonnie Gilbert | 0 | 7 | 10 | 0 | ["Fred Williamson","Amy Bailey","Billy Moore","Joan Flores","Maria Hughes"] | 24 | Social proximity context. Human review only.
// Raymond Walker | 2 | 2 | 8 | 1 | ["Kathleen Peters","Phillip Williamson"] | 23 | Observed PARTY_TO context. Human review only.
// Kathy Wheeler | 0 | 3 | 11 | 1 | ["Alan Ward","Diana Murray","Jessica Kelly"] | 18 | Social proximity context. Human review only.
// Ashley Robertson | 0 | 5 | 5 | 0 | ["Gary Vasquez","Carlos Black","Annie George","David Mills","Michelle Patterson"] | 15 | Social proximity context. Human review only.
// Billy Moore | 2 | 1 | 1 | 1 | ["Lillian Martinez"] | 14 | Observed PARTY_TO context. Human review only.
// Donald Robinson | 2 | 1 | 1 | 2 | ["Andrea Montgomery"] | 14 | Observed PARTY_TO context. Human review only.
// Amy Bailey | 2 | 0 | 0 | 1 | [] | 11 | Observed PARTY_TO context. Human review only.
// Craig Marshall | 2 | 0 | 0 | 6 | [] | 11 | Observed PARTY_TO context. Human review only.
// Stephanie Hughes | 2 | 0 | 0 | 1 | [] | 11 | Observed PARTY_TO context. Human review only.
// Andrea Montgomery | 1 | 1 | 2 | 2 | ["Donald Robinson"] | 10 | Observed PARTY_TO context. Human review only.
// Lillian Martinez | 1 | 1 | 2 | 1 | ["Billy Moore"] | 10 | Observed PARTY_TO context. Human review only.
// Kelly Peterson | 0 | 2 | 5 | 0 | ["Brian Morales","Amanda Robertson"] | 9 | Low-volume contextual signal. Human review only.
// Pamela Gibson | 0 | 2 | 4 | 1 | ["Stephanie Hughes","Amy Bailey"] | 9 | Low-volume contextual signal. Human review only.
// Amy Murphy | 0 | 1 | 5 | 1 | ["Jessica Kelly"] | 8 | Low-volume contextual signal. Human review only.
// Ann Fox | 0 | 1 | 5 | 1 | ["Jessica Kelly"] | 8 | Low-volume contextual signal. Human review only.
// Mary Young | 0 | 2 | 3 | 1 | ["Stephanie Hughes","Andrea Montgomery"] | 8 | Low-volume contextual signal. Human review only.
// Roger Brooks | 0 | 2 | 3 | 1 | ["Billy Moore","Lillian Martinez"] | 8 | Low-volume contextual signal. Human review only.

// ==================================================
// QUERY 63
// ==================================================
// Query 6.2 - Review-priority social communities.
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
       'Community is a review-priority cluster, not an accusation.' AS communityReviewReading
ORDER BY totalObservedPartyToLinks DESC, crimeLinkedPeoplePercent DESC
LIMIT 15;

// RESULT 63
// --------------------------------------------------
// communityId | people | crimeLinkedPeople | totalObservedPartyToLinks | crimeLinkedPeoplePercent | crimeTypes | exampleMembers | communityReviewReading
// 239 | 10 | 8 | 29 | 80.0 | ["Drugs","Vehicle crime","Robbery"] | ["William Dixon","Raymond Walker","Kathleen Peters","Diana Murray","Kathy Wheeler","Alan Ward","Jack Powell","Phillip Williamson"] | Community is a review-priority cluster, not an accusation.
// 237 | 22 | 6 | 9 | 27.3 | ["Violence and sexual offences","Criminal damage and arson","Burglary","Vehicle crime","Robbery"] | ["Phillip Myers","Mary Young","Stephanie Hughes","Pamela Gibson","Maria Hughes","Lawrence Stephens","Raymond Williamson","Jennifer Rogers"] | Community is a review-priority cluster, not an accusation.
// 331 | 22 | 3 | 5 | 13.6 | ["Robbery","Public order"] | ["Sharon White","Anne Nguyen","Carlos Chavez","Melissa Warren","Paul Arnold","Philip Scott","Linda Baker","Rebecca Long"] | Community is a review-priority cluster, not an accusation.
// 226 | 26 | 3 | 3 | 11.5 | ["Criminal damage and arson","Burglary","Vehicle crime"] | ["Nancy Campbell","Todd Garcia","Rachel Turner","Ashley Robertson","Carl Hayes","Rose Parker","Phyllis Murray","Joshua Black"] | Community is a review-priority cluster, not an accusation.
// 351 | 32 | 3 | 3 | 9.4 | ["Robbery","Theft from the person"] | ["Todd Hamilton","Benjamin Hamilton","Diane Cox","Ryan Castillo","Dennis Ford","Justin Arnold","Donna Jordan","Norma Payne"] | Community is a review-priority cluster, not an accusation.
// 251 | 16 | 2 | 2 | 12.5 | ["Violence and sexual offences","Public order"] | ["Philip Mason","Dennis Mcdonald","Sandra Ruiz","David Mills","Kelly Peterson","Amanda Robertson","Richard Coleman","Elizabeth Anderson"] | Community is a review-priority cluster, not an accusation.
// 162 | 16 | 1 | 1 | 6.3 | ["Violence and sexual offences"] | ["Denise Rodriguez","Nicholas Mason","Rebecca Lee","Jeffrey Lewis","Alice Mcdonald","Randy Edwards","Matthew Phillips","Annie George"] | Community is a review-priority cluster, not an accusation.
// 122 | 28 | 1 | 1 | 3.6 | ["Violence and sexual offences"] | ["Mildred Kelly","Stephen Perez","Lawrence Warren","Paul Nguyen","Stephanie Lynch","Ashley Bennett","Janice Coleman","Patrick Sanders"] | Community is a review-priority cluster, not an accusation.
// 328 | 31 | 1 | 1 | 3.2 | ["Violence and sexual offences"] | ["Scott Kelly","Rose Crawford","Christine Brown","Heather Howard","Rachel Bradley","Rachel Hunter","Diane Wagner","Judith Moore"] | Community is a review-priority cluster, not an accusation.
// 249 | 32 | 1 | 1 | 3.1 | ["Vehicle crime"] | ["Mary Peters","Irene Austin","Harry Garrett","Eugene Ferguson","Douglas Cole","Wanda Webb","Kevin Hawkins","Jennifer Gray"] | Community is a review-priority cluster, not an accusation.

// ==================================================
// QUERY 64
// ==================================================
// Query 6.3 - Final conclusion.
MATCH (:Person)-[party:PARTY_TO]->(:Crime)
WITH count(party) AS partyToLinks
MATCH (:Crime)-[occurred:OCCURRED_AT]->(:Location)
WITH partyToLinks, count(occurred) AS crimeLocationLinks
MATCH (:Person)-[social:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]->(:Person)
WITH partyToLinks, crimeLocationLinks, count(social) AS socialLinks
MATCH (:Vehicle)-[vehicleCrime:INVOLVED_IN]->(:Crime)
WITH partyToLinks, crimeLocationLinks, socialLinks, count(vehicleCrime) AS vehicleCrimeLinks
OPTIONAL MATCH ()-[explainable:PREDICTED_SOCIAL_EXPLAINABLE]->()
WITH partyToLinks, crimeLocationLinks, socialLinks, vehicleCrimeLinks, count(explainable) AS writtenExplainableReviewLinks
OPTIONAL MATCH ()-[pred:PREDICTED_SOCIAL_REVIEW]->()
RETURN partyToLinks,
       crimeLocationLinks,
       socialLinks,
       vehicleCrimeLinks,
       writtenExplainableReviewLinks,
       count(pred) AS writtenPredictedSocialReviewLinks,
       'Final graph ML conclusion: lead with hotspot and community analytics. Use supervised social-family link prediction, explainable Common Neighbours, Adamic Adar, and unsupervised embedding similarity as review candidates. Keep crime-class prediction as a negative model-comparison experiment. Keep vehicle, address, phone, and PARTY_TO data as supporting context rather than automated accusation.' AS finalConclusion;

// RESULT 64
// --------------------------------------------------
// partyToLinks | crimeLocationLinks | socialLinks | vehicleCrimeLinks | writtenExplainableReviewLinks | writtenPredictedSocialReviewLinks | finalConclusion
// 55 | 28762 | 1180 | 978 | 4 | 25 | Final graph ML conclusion: lead with hotspot and community analytics. Use supervised social-family link prediction, explainable Common Neighbours, Adamic Adar, and unsupervised embedding similarity as review candidates. Keep crime-class prediction as a negative model-comparison experiment. Keep vehicle, address, phone, and PARTY_TO data as supporting context rather than automated accusation.
