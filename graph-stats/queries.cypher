// POLE Crime Investigation - Graph Stats and Analytics
// Group 4: Amn Naqvi and Rayyan Shah

// SECTION 0: SETUP, VERSION CHECK, AND CLEANUP

// Query 0.1 - Neo4j version for reproducibility.
CALL dbms.components()
YIELD name, versions, edition
RETURN name, versions, edition;

// Query 0.2 - GDS version for reproducibility.
RETURN gds.version() AS gdsVersion;

// Query 0.3 - Remove only properties written by our analysis scripts.
MATCH (n)
REMOVE n.communityId,
       n.componentId,
       n.socialCommunityId,
       n.socialComponentId,
       n.revisedSocialCommunityId,
       n.revisedSocialComponentId;

// Query 0.4 - Drop old in-memory GDS projections.
CALL gds.graph.drop('graphStatsSocialGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// Query 0.5 - Create lookup indexes used by common queries.
CREATE INDEX person_name_idx IF NOT EXISTS
FOR (p:Person) ON (p.name);

CREATE INDEX crime_date_idx IF NOT EXISTS
FOR (c:Crime) ON (c.date);

CREATE INDEX location_address_idx IF NOT EXISTS
FOR (l:Location) ON (l.address);

// SECTION 1: SCHEMA VALIDATION

// Query 1.1 - Node labels and counts.
MATCH (n)
RETURN labels(n)[0] AS label,
       count(n) AS count
ORDER BY count DESC;

// Query 1.2 - Relationship types and counts.
MATCH ()-[r]->()
WHERE NOT type(r) STARTS WITH 'PREDICTED_'
RETURN type(r) AS relationshipType,
       count(r) AS count
ORDER BY count DESC;

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

// Query 1.4 - Person properties.
MATCH (p:Person)
RETURN keys(p) AS personProperties
LIMIT 1;

// Query 1.5 - Crime properties.
MATCH (c:Crime)
RETURN keys(c) AS crimeProperties
LIMIT 1;

// Query 1.6 - Location properties.
MATCH (l:Location)
RETURN keys(l) AS locationProperties
LIMIT 1;

// Query 1.7 - Vehicle properties.
MATCH (v:Vehicle)
RETURN keys(v) AS vehicleProperties
LIMIT 1;

// Query 1.8 - Crime date range.
MATCH (c:Crime)
WHERE c.date IS NOT NULL
RETURN min(c.date) AS earliestCrimeDate,
       max(c.date) AS latestCrimeDate;

// Query 1.9 - Crime types.
MATCH (c:Crime)
WHERE c.type IS NOT NULL
RETURN c.type AS crimeType,
       count(c) AS incidents
ORDER BY incidents DESC, crimeType;

// Query 1.10 - Total graph size.
MATCH (n)
WITH count(n) AS totalNodes
MATCH ()-[r]->()
WHERE NOT type(r) STARTS WITH 'PREDICTED_'
RETURN totalNodes,
       count(r) AS totalRelationships;

// Query 1.11 - Degree summary across baseline graph relationships.
MATCH (n)
OPTIONAL MATCH (n)-[r]-()
WHERE r IS NULL OR NOT type(r) STARTS WITH 'PREDICTED_'
WITH n, count(r) AS degree
RETURN avg(degree) AS averageDegree,
       min(degree) AS minimumDegree,
       max(degree) AS maximumDegree;

// Query 1.12 - Isolated Person nodes.
MATCH (p:Person)
WHERE NOT (p)--()
RETURN count(p) AS isolatedPersons;

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

// Query 2.3 - Crimes with no observed Person link.
MATCH (c:Crime)
OPTIONAL MATCH (p:Person)-[:PARTY_TO]-(c)
WITH c, count(p) AS linkedPeople
RETURN count(c) AS crimes,
       sum(CASE WHEN linkedPeople > 0 THEN 1 ELSE 0 END) AS crimesWithObservedPersonLink,
       sum(CASE WHEN linkedPeople = 0 THEN 1 ELSE 0 END) AS crimesWithoutObservedPersonLink,
       round(1000.0 * sum(CASE WHEN linkedPeople > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS crimePersonCoveragePercent;

// SECTION 3: CRIME-LOCATION HOTSPOTS AND AREA PROFILES

// Query 3.1 - Crime-location coverage.
MATCH (c:Crime)
OPTIONAL MATCH (c)-[:OCCURRED_AT]->(l:Location)
WITH c, count(l) AS locationLinks
RETURN count(c) AS crimes,
       sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) AS crimesWithLocation,
       sum(CASE WHEN locationLinks = 0 THEN 1 ELSE 0 END) AS crimesWithoutLocation,
       round(1000.0 * sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS locationCoveragePercent;

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

// Query 3.3 - Top areas by crime volume and crime-type diversity.
MATCH (c:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)
RETURN elementId(a) AS areaId,
       count(c) AS incidents,
       count(DISTINCT c.type) AS distinctCrimeTypes
ORDER BY incidents DESC, distinctCrimeTypes DESC
LIMIT 20;

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

// Query 3.7 - Outcome distribution for all crimes.
MATCH (c:Crime)
RETURN coalesce(c.last_outcome, 'Missing') AS outcome,
       count(c) AS crimes,
       round(1000.0 * count(c) / 28762) / 10.0 AS sharePercent
ORDER BY crimes DESC
LIMIT 20;

// Query 3.8 - Crime type by unresolved / no-suspect outcome.
MATCH (c:Crime)
WITH c.type AS crimeType,
     count(c) AS crimes,
     sum(CASE
           WHEN c.last_outcome STARTS WITH 'Investigation complete' OR c.last_outcome = 'Under investigation'
           THEN 1 ELSE 0
         END) AS unresolvedOrNoSuspect
RETURN crimeType,
       crimes,
       unresolvedOrNoSuspect,
       round(1000.0 * unresolvedOrNoSuspect / crimes) / 10.0 AS unresolvedOrNoSuspectPercent
ORDER BY unresolvedOrNoSuspect DESC, unresolvedOrNoSuspectPercent DESC
LIMIT 20;

// Query 3.9 - Officer workload concentration.
MATCH (c:Crime)-[:INVESTIGATED_BY]->(o:Officer)
WITH o, count(c) AS caseload, count(DISTINCT c.type) AS crimeTypeBreadth
RETURN avg(caseload) AS averageCaseload,
       min(caseload) AS minimumCaseload,
       max(caseload) AS maximumCaseload,
       percentileCont(caseload, 0.5) AS medianCaseload,
       percentileCont(caseload, 0.9) AS p90Caseload,
       count(o) AS officers,
       'Officer load is a second operational lens beyond hotspot places.' AS reading;

// Query 3.10 - Highest caseload officers and their crime-type breadth.
MATCH (c:Crime)-[:INVESTIGATED_BY]->(o:Officer)
WITH o, count(c) AS caseload, count(DISTINCT c.type) AS crimeTypeBreadth, collect(DISTINCT c.type)[0..5] AS exampleTypes
RETURN elementId(o) AS officerId,
       caseload,
       crimeTypeBreadth,
       exampleTypes
ORDER BY caseload DESC, crimeTypeBreadth DESC
LIMIT 15;

// SECTION 4: PERSON SOCIAL GRAPH GDS ANALYTICS

// Query 4.1 - Person-Person relationship mix.
MATCH (:Person)-[r]->(:Person)
WHERE type(r) IN ['KNOWS', 'KNOWS_SN', 'KNOWS_PHONE', 'KNOWS_LW', 'FAMILY_REL']
RETURN type(r) AS relationshipType,
       count(r) AS directedLinks,
       count(DISTINCT startNode(r)) AS distinctSources,
       count(DISTINCT endNode(r)) AS distinctTargets
ORDER BY directedLinks DESC;

// Query 4.2 - Social coverage among Person nodes.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN count(p) AS people,
       sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) AS sociallyConnectedPeople,
       sum(CASE WHEN socialDegree = 0 THEN 1 ELSE 0 END) AS sociallyIsolatedPeople,
       round(1000.0 * sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS sociallyConnectedPercent;

// Query 4.3 - Person social degree distribution.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN socialDegree,
       count(p) AS people
ORDER BY socialDegree DESC
LIMIT 25;

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

// Query 4.5 - Degree centrality: most directly connected people.
CALL gds.degree.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS degreeConnections
ORDER BY degreeConnections DESC, person
LIMIT 15;

// Query 4.6 - PageRank: socially influential people.
CALL gds.pageRank.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS pageRankScore
ORDER BY pageRankScore DESC, person
LIMIT 15;

// Query 4.7 - Betweenness centrality: social bridges.
CALL gds.betweenness.stream('graphStatsSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS betweennessScore
ORDER BY betweennessScore DESC, person
LIMIT 15;

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

// Query 4.9 - Local clustering coefficient: how triadic the social graph is.
CALL gds.localClusteringCoefficient.stats('graphStatsSocialGraph')
YIELD averageClusteringCoefficient, nodeCount
RETURN nodeCount,
       averageClusteringCoefficient,
       CASE
         WHEN averageClusteringCoefficient >= 0.2 THEN 'Triadic closure is meaningful.'
         ELSE 'Social links are relatively tree-like, so shared-neighbour evidence should be treated conservatively.'
       END AS clusteringReading;

// Query 4.10 - K-core: structurally embedded people.
CALL gds.kcore.stream('graphStatsSocialGraph')
YIELD nodeId, coreValue
WITH gds.util.asNode(nodeId) AS p, coreValue
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       coreValue
ORDER BY coreValue DESC, person
LIMIT 20;

// Query 4.11 - Articulation points: people whose removal disconnects social paths.
CALL gds.articulationPoints.stream('graphStatsSocialGraph')
YIELD nodeId
WITH gds.util.asNode(nodeId) AS p
RETURN p.name + ' ' + coalesce(p.surname, '') AS articulationPerson
ORDER BY articulationPerson
LIMIT 25;

// Query 4.12 - Largest social communities.
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

// Query 4.13 - Social communities with observed crime context.
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

// Query 4.14 - Weakly connected components on the social graph.
CALL gds.wcc.write(
    'graphStatsSocialGraph',
    {writeProperty: 'revisedSocialComponentId'}
)
YIELD componentCount, componentDistribution
RETURN componentCount,
       componentDistribution;

// Query 4.15 - Social component size distribution.
MATCH (p:Person)
WHERE p.revisedSocialComponentId IS NOT NULL
RETURN p.revisedSocialComponentId AS componentId,
       count(p) AS people
ORDER BY people DESC
LIMIT 15;

// Query 4.16 - Example shortest path between two people.
MATCH (a:Person {name: 'Todd'})
WITH a LIMIT 1
MATCH (b:Person {name: 'Rachel'})
WITH a, b LIMIT 1
MATCH path = shortestPath((a)-[*..10]-(b))
RETURN path;

// SECTION 5: PERSON-LOCATION, VEHICLE, AND PHONE CONTEXT

// Query 5.1 - Person current-address coverage.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:CURRENT_ADDRESS]->(l:Location)
WITH p, count(l) AS addressLinks
RETURN count(p) AS people,
       sum(CASE WHEN addressLinks > 0 THEN 1 ELSE 0 END) AS peopleWithCurrentAddress,
       sum(CASE WHEN addressLinks = 0 THEN 1 ELSE 0 END) AS peopleWithoutCurrentAddress,
       round(1000.0 * sum(CASE WHEN addressLinks > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS addressCoveragePercent;

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

// Query 5.3 - What INVOLVED_IN actually connects.
MATCH (x)-[r:INVOLVED_IN]->(c:Crime)
RETURN labels(x)[0] AS involvedLabel,
       count(r) AS relationships,
       count(DISTINCT x) AS distinctEntities,
       count(DISTINCT c) AS distinctCrimes
ORDER BY relationships DESC;

// Query 5.4 - Vehicle involvement by crime type.
MATCH (v:Vehicle)-[:INVOLVED_IN]->(c:Crime)
RETURN c.type AS crimeType,
       count(*) AS vehicleCrimeLinks,
       count(DISTINCT v) AS vehicles,
       count(DISTINCT c) AS crimes
ORDER BY vehicleCrimeLinks DESC;

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

// Query 5.6 - Phone coverage for Person nodes.
MATCH (p:Person)
OPTIONAL MATCH (p)-[:HAS_PHONE]->(phone:Phone)
WITH p, count(phone) AS phones
RETURN count(p) AS people,
       sum(CASE WHEN phones > 0 THEN 1 ELSE 0 END) AS peopleWithPhone,
       sum(CASE WHEN phones = 0 THEN 1 ELSE 0 END) AS peopleWithoutPhone,
       round(1000.0 * sum(CASE WHEN phones > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS phoneCoveragePercent;

// Query 5.7 - People with the most linked phone calls.
MATCH (p:Person)-[:HAS_PHONE]->(phone:Phone)
OPTIONAL MATCH (call:PhoneCall)-[:CALLER|CALLED]->(phone)
WITH p, count(DISTINCT call) AS callCount
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       callCount
ORDER BY callCount DESC, person
LIMIT 20;

// Query 5.8 - Phone-call derived Person-Person communication pairs.
MATCH (p1:Person)-[:HAS_PHONE]->(phone1:Phone)<-[:CALLER|CALLED]-(call:PhoneCall)-[:CALLER|CALLED]->(phone2:Phone)<-[:HAS_PHONE]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
WITH p1, p2, count(DISTINCT call) AS calls
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       calls,
       CASE
         WHEN (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
         THEN 'Already represented in social graph'
         ELSE 'Communication-derived candidate edge'
       END AS communicationReading
ORDER BY calls DESC, personA, personB
LIMIT 25;

// Query 5.9 - How much phone communication is already covered by social edges?
MATCH (p1:Person)-[:HAS_PHONE]->(phone1:Phone)<-[:CALLER|CALLED]-(call:PhoneCall)-[:CALLER|CALLED]->(phone2:Phone)<-[:HAS_PHONE]-(p2:Person)
WHERE elementId(p1) < elementId(p2)
WITH DISTINCT p1, p2
RETURN count(*) AS communicationPairs,
       sum(CASE WHEN (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2) THEN 1 ELSE 0 END) AS alreadySocialPairs,
       sum(CASE WHEN NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2) THEN 1 ELSE 0 END) AS newCommunicationCandidatePairs,
       round(1000.0 * sum(CASE WHEN (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2) THEN 1 ELSE 0 END) / count(*)) / 10.0 AS socialCoveragePercent,
       'Phone calls provide an independent communication layer for candidate social links.' AS reading;

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

// Query 6.7 - Final graph ML feature recommendation.
RETURN 'Use Crime-Location and Area profiles as the main demo evidence. Use social graph centrality and Louvain as the main GDS result. Use supervised social-family link prediction plus Common Neighbours, Adamic Adar, and embedding similarity as review-only Person-Person prediction outputs. Keep PARTY_TO only as observed context.' AS m3FeatureRecommendation;

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

