// POLE Crime Investigation - Graph Machine Learning
// Group 4: Amn Naqvi and Rayyan Shah

// SECTION 0: SETUP

// Query 0.1 - GDS version.
RETURN gds.version() AS gdsVersion;

// Query 0.2 - Clear old prediction relationships from previous runs.
MATCH ()-[r:PREDICTED_KNOWS_REVIEW]->()
DELETE r;

MATCH ()-[r:PREDICTED_KNOWS_EXPLAINABLE]->()
DELETE r;

// Query 0.3 - Drop old in-memory GDS items from previous runs.
CALL gds.model.drop('revised-knows-lp-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

CALL gds.pipeline.drop('revised-knows-lp-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

CALL gds.graph.drop('revisedKnowsContextGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

CALL gds.graph.drop('revisedSocialGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

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

// SECTION 2: HOTSPOT AND AREA ANALYTICS

// Query 2.1 - Crime-location coverage.
MATCH (c:Crime)
OPTIONAL MATCH (c)-[:OCCURRED_AT]->(l:Location)
WITH c, count(l) AS locationLinks
RETURN count(c) AS crimes,
       sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) AS crimesWithLocation,
       sum(CASE WHEN locationLinks = 0 THEN 1 ELSE 0 END) AS crimesWithoutLocation,
       round(1000.0 * sum(CASE WHEN locationLinks > 0 THEN 1 ELSE 0 END) / count(c)) / 10.0 AS locationCoveragePercent;

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

// Query 2.6 - Vehicle-crime-location context.
MATCH (v:Vehicle)-[:INVOLVED_IN]->(c:Crime)-[:OCCURRED_AT]->(l:Location)
RETURN c.type AS crimeType,
       l.address AS location,
       count(v) AS involvedVehicles,
       count(DISTINCT c) AS crimes
ORDER BY involvedVehicles DESC, crimes DESC, location
LIMIT 25;

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

// SECTION 3: SOCIAL GRAPH ANALYTICS

// Query 3.1 - Social relationship mix.
MATCH (:Person)-[r]->(:Person)
RETURN type(r) AS relationshipType,
       count(r) AS directedLinks,
       count(DISTINCT startNode(r)) AS distinctSources,
       count(DISTINCT endNode(r)) AS distinctTargets
ORDER BY directedLinks DESC;

// Query 3.2 - Social coverage.
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(:Person)
WITH p, count(r) AS socialDegree
RETURN count(p) AS people,
       sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) AS sociallyConnectedPeople,
       sum(CASE WHEN socialDegree = 0 THEN 1 ELSE 0 END) AS sociallyIsolatedPeople,
       round(1000.0 * sum(CASE WHEN socialDegree > 0 THEN 1 ELSE 0 END) / count(p)) / 10.0 AS sociallyConnectedPercent;

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

// Query 3.4 - PageRank: socially central people.
CALL gds.pageRank.stream('revisedSocialGraph')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS p, score
RETURN p.name + ' ' + coalesce(p.surname, '') AS person,
       score AS pageRankScore
ORDER BY pageRankScore DESC
LIMIT 15;

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

// SECTION 4: MAIN GML PIPELINE - PERSON-PERSON KNOWS

// Query 4.1 - KNOWS target size and imbalance.
MATCH (p:Person)
WITH count(p) AS people
MATCH (:Person)-[:KNOWS]->(:Person)
WITH people, count(*) AS knowsLinks
RETURN people,
       knowsLinks,
       people * (people - 1) AS possibleDirectedPersonPairs,
       round(1000000.0 * knowsLinks / (people * (people - 1))) / 10000.0 AS positiveClassPercent,
       'KNOWS is still sparse, but it has far more labels than PARTY_TO and is safer to interpret.' AS targetReading;

// Query 4.2 - Project a context graph for KNOWS link prediction.
CALL gds.graph.project(
  'revisedKnowsContextGraph',
  ['Person', 'Phone', 'Email', 'Location', 'Crime'],
  {
    KNOWS: {orientation: 'UNDIRECTED'},
    KNOWS_SN: {orientation: 'UNDIRECTED'},
    KNOWS_PHONE: {orientation: 'UNDIRECTED'},
    KNOWS_LW: {orientation: 'UNDIRECTED'},
    FAMILY_REL: {orientation: 'UNDIRECTED'},
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

// Query 4.3 - Create link-prediction pipeline.
CALL gds.beta.pipeline.linkPrediction.create('revised-knows-lp-pipeline')
YIELD name
RETURN name AS pipeline;

// Query 4.4 - Add FastRP embeddings.
CALL gds.beta.pipeline.linkPrediction.addNodeProperty(
  'revised-knows-lp-pipeline',
  'fastRP',
  {
    mutateProperty: 'embedding',
    embeddingDimension: 64,
    iterationWeights: [0.0, 1.0, 1.0, 1.0],
    randomSeed: 42
  }
)
YIELD nodePropertySteps
RETURN nodePropertySteps;

// Query 4.5 - Add pairwise embedding feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'revised-knows-lp-pipeline',
  'hadamard',
  {nodeProperties: ['embedding']}
)
YIELD featureSteps
RETURN featureSteps;

// Query 4.6 - Configure train/test split.
CALL gds.beta.pipeline.linkPrediction.configureSplit(
  'revised-knows-lp-pipeline',
  {
    testFraction: 0.20,
    trainFraction: 0.60,
    validationFolds: 3,
    negativeSamplingRatio: 1.0
  }
)
YIELD splitConfig
RETURN splitConfig;

// Query 4.7 - Logistic regression model candidate.
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression(
  'revised-knows-lp-pipeline',
  {
    penalty: 0.0,
    maxEpochs: 100,
    learningRate: 0.001
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// Query 4.8 - Train KNOWS link-prediction model.
CALL gds.beta.pipeline.linkPrediction.train(
  'revisedKnowsContextGraph',
  {
    pipeline: 'revised-knows-lp-pipeline',
    modelName: 'revised-knows-lp-model',
    sourceNodeLabel: 'Person',
    targetNodeLabel: 'Person',
    targetRelationshipType: 'KNOWS',
    metrics: ['AUCPR'],
    randomSeed: 42
  }
)
YIELD modelInfo, trainMillis
RETURN trainMillis,
       modelInfo.metrics.AUCPR.train.avg AS trainAUCPR,
       modelInfo.metrics.AUCPR.validation.avg AS validationAUCPR,
       modelInfo.metrics.AUCPR.test AS testAUCPR,
       modelInfo.bestParameters AS bestParameters,
       CASE
         WHEN modelInfo.metrics.AUCPR.test >= 0.70 THEN 'Strong enough for social-link review ranking.'
         WHEN modelInfo.metrics.AUCPR.test >= 0.50 THEN 'Weak but usable as a review-priority signal.'
         ELSE 'Not reliable enough even for social-link ranking.'
       END AS modelReading;

// Query 4.9 - Explainable link prediction baseline: Common Neighbours.
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

// Query 4.10 - Explainable link prediction baseline: Adamic Adar style score.
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

// Query 4.11 - Write conservative explainable social candidates.
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
MERGE (p1)-[r:PREDICTED_KNOWS_EXPLAINABLE]->(p2)
SET r.commonNeighbours = commonNeighbours,
    r.adamicAdarScore = adamicAdarScore,
    r.explanation = explanation,
    r.note = 'Review-only explainable social link prediction. Not evidence of crime.'
RETURN count(r) AS writtenExplainableReviewLinks,
       'Explainable candidates were written because they have clear shared-neighbour evidence.' AS writeBackReading;

// Query 4.12 - Calibration check for supervised predicted social links.
CALL gds.beta.pipeline.linkPrediction.predict.stream(
  'revisedKnowsContextGraph',
  {modelName: 'revised-knows-lp-model', topN: 200}
)
YIELD node1, node2, probability
WITH gds.util.asNode(node1) AS p1,
     gds.util.asNode(node2) AS p2,
     probability
WHERE p1:Person
  AND p2:Person
  AND elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
WITH count(*) AS candidateLinks,
     min(probability) AS lowestProbability,
     max(probability) AS highestProbability,
     avg(probability) AS averageProbability
RETURN candidateLinks,
       lowestProbability,
       highestProbability,
       averageProbability,
       highestProbability - lowestProbability AS probabilityBand,
       CASE
         WHEN candidateLinks = 0 THEN 'No unseen Person-Person candidates returned.'
         WHEN highestProbability - lowestProbability < 0.01 THEN 'Do not write back. Scores are too flat.'
         ELSE 'Scores have separation. Candidate social links can be reviewed.'
       END AS deploymentDecision;

// Query 4.13 - Top supervised candidate social links for comparison.
CALL gds.beta.pipeline.linkPrediction.predict.stream(
  'revisedKnowsContextGraph',
  {modelName: 'revised-knows-lp-model', topN: 50}
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

// Query 4.14 - Conservative write-back of supervised review-only social candidates.
CALL {
  CALL gds.beta.pipeline.linkPrediction.predict.stream(
    'revisedKnowsContextGraph',
    {modelName: 'revised-knows-lp-model', topN: 200}
  )
  YIELD node1, node2, probability
  WITH gds.util.asNode(node1) AS p1,
       gds.util.asNode(node2) AS p2,
       probability
  WHERE p1:Person
    AND p2:Person
    AND elementId(p1) < elementId(p2)
    AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
  RETURN collect({p1: p1, p2: p2, probability: probability}) AS candidates,
         min(probability) AS lowestProbability,
         max(probability) AS highestProbability
}
WITH candidates, lowestProbability, highestProbability,
     highestProbability - lowestProbability AS probabilityBand
WITH [candidate IN candidates
      WHERE probabilityBand >= 0.01
        AND candidate.probability >= 0.55][0..25] AS writeCandidates
CALL {
  WITH writeCandidates
  UNWIND writeCandidates AS candidate
  WITH candidate.p1 AS p1,
       candidate.p2 AS p2,
       candidate.probability AS probability
  MERGE (p1)-[r:PREDICTED_KNOWS_REVIEW]->(p2)
  SET r.probability = probability,
      r.model = 'revised-knows-lp-model',
      r.note = 'Review-only predicted social/context link. Not evidence of crime.'
  RETURN count(r) AS writtenReviewLinks
}
RETURN writtenReviewLinks,
       'Review-only PREDICTED_KNOWS_REVIEW relationships written only when scores were not flat.' AS writeBackReading;

// Query 4.15 - GML decision table for the final demo.
MATCH ()-[explainable:PREDICTED_KNOWS_EXPLAINABLE]->()
WITH count(explainable) AS explainableReviewLinks
OPTIONAL MATCH ()-[supervised:PREDICTED_KNOWS_REVIEW]->()
RETURN explainableReviewLinks,
       count(supervised) AS supervisedReviewLinks,
       CASE
         WHEN explainableReviewLinks > 0 AND count(supervised) = 0
         THEN 'Use explainable Common Neighbours and Adamic Adar candidates in the demo. Supervised write-back remains blocked because calibration is flat.'
         WHEN count(supervised) > 0
         THEN 'Both explainable and supervised candidates are available for review.'
         ELSE 'No candidate write-back should be shown.'
       END AS gmlDemoDecision;

// SECTION 5: REVIEW PRIORITY WITHOUT AUTOMATED ACCUSATION

// Query 5.1 - Review-priority people using observed graph context.
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

// Query 5.2 - Review-priority social communities.
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

// Query 5.3 - Final conclusion.
MATCH (:Person)-[party:PARTY_TO]->(:Crime)
WITH count(party) AS partyToLinks
MATCH (:Crime)-[occurred:OCCURRED_AT]->(:Location)
WITH partyToLinks, count(occurred) AS crimeLocationLinks
MATCH (:Person)-[social:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]->(:Person)
WITH partyToLinks, crimeLocationLinks, count(social) AS socialLinks
MATCH (:Vehicle)-[vehicleCrime:INVOLVED_IN]->(:Crime)
WITH partyToLinks, crimeLocationLinks, socialLinks, count(vehicleCrime) AS vehicleCrimeLinks
OPTIONAL MATCH ()-[explainable:PREDICTED_KNOWS_EXPLAINABLE]->()
WITH partyToLinks, crimeLocationLinks, socialLinks, vehicleCrimeLinks, count(explainable) AS writtenExplainableReviewLinks
OPTIONAL MATCH ()-[pred:PREDICTED_KNOWS_REVIEW]->()
RETURN partyToLinks,
       crimeLocationLinks,
       socialLinks,
       vehicleCrimeLinks,
       writtenExplainableReviewLinks,
       count(pred) AS writtenPredictedSocialReviewLinks,
       'Final graph ML conclusion: lead with hotspot and community analytics. Use explainable Common Neighbours and Adamic Adar candidates as the strongest GML demo output. Keep supervised KNOWS link prediction as a calibrated experiment and block write-back when scores are flat. Keep vehicle, address, phone, and PARTY_TO data as supporting context rather than automated accusation.' AS finalConclusion;

