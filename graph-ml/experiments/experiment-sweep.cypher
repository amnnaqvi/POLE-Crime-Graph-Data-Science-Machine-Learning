// POLE Crime Investigation - Extended Experiment Sweep
// Rayyan Shah (rs08770) and Amn Naqvi (sn08776)
// This file runs the extra GDS/ML experiments we used to compare options
// before choosing the final demo pipeline.

// SECTION 0: CLEANUP

MATCH ()-[r:EXPERIMENT_SOCIAL_LINK]->()
DELETE r;

CALL gds.model.drop('sweep-social-lp-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

CALL gds.pipeline.drop('sweep-social-lp-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

CALL gds.graph.drop('sweepSocialContextGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

CALL gds.model.drop('sweep-crime-class-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

CALL gds.pipeline.drop('sweep-crime-class-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

CALL gds.graph.drop('sweepCrimeClassGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

CALL gds.graph.drop('sweepCrimeLocationSimilarityGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// SECTION 1: TARGET AND BASELINE AUDITS

// Query 1.1 - Full link prediction target scorecard.
CALL {
  MATCH (p:Person)
  WITH count(p) AS sources
  MATCH (q:Person)
  WITH sources, count(q) AS targets
  MATCH (p:Person)-[r:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(q:Person)
  WHERE elementId(p) < elementId(q)
  RETURN 'Person-Person social family' AS target,
         sources,
         targets,
         count(r) AS observedLinks,
         count(DISTINCT p) AS coveredSources,
         count(DISTINCT q) AS coveredTargets,
         'Best link prediction target because it is social/contextual rather than accusatory.' AS reading

  UNION ALL

  MATCH (p:Person)
  WITH count(p) AS sources
  MATCH (c:Crime)
  WITH sources, count(c) AS targets
  MATCH (p:Person)-[r:PARTY_TO]->(c:Crime)
  RETURN 'Person-Crime PARTY_TO' AS target,
         sources,
         targets,
         count(r) AS observedLinks,
         count(DISTINCT p) AS coveredSources,
         count(DISTINCT c) AS coveredTargets,
         'Too sparse and too sensitive for main prediction.' AS reading

  UNION ALL

  MATCH (c:Crime)
  WITH count(c) AS sources
  MATCH (l:Location)
  WITH sources, count(l) AS targets
  MATCH (c:Crime)-[r:OCCURRED_AT]->(l:Location)
  RETURN 'Crime-Location OCCURRED_AT' AS target,
         sources,
         targets,
         count(r) AS observedLinks,
         count(DISTINCT c) AS coveredSources,
         count(DISTINCT l) AS coveredTargets,
         'Strongest descriptive surface, better for hotspot ranking than supervised LP.' AS reading

  UNION ALL

  MATCH (v:Vehicle)
  WITH count(v) AS sources
  MATCH (c:Crime)
  WITH sources, count(c) AS targets
  MATCH (v:Vehicle)-[r:INVOLVED_IN]->(c:Crime)
  RETURN 'Vehicle-Crime INVOLVED_IN' AS target,
         sources,
         targets,
         count(r) AS observedLinks,
         count(DISTINCT v) AS coveredSources,
         count(DISTINCT c) AS coveredTargets,
         'Good context coverage, weak prediction because vehicles are mostly one-off.' AS reading
}
RETURN target,
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

// Query 1.2 - Leave-one-out location majority baseline for crime type.
MATCH (target:Crime)-[:OCCURRED_AT]->(l:Location)
WITH target, l
CALL {
  WITH target, l
  MATCH (other:Crime)-[:OCCURRED_AT]->(l)
  WHERE elementId(other) <> elementId(target)
    AND other.type IS NOT NULL
  WITH other.type AS predictedType, count(*) AS support
  ORDER BY support DESC, predictedType
  RETURN predictedType, support
  LIMIT 1
}
WITH target, predictedType, support
WHERE predictedType IS NOT NULL
RETURN count(*) AS evaluatedCrimes,
       sum(CASE WHEN target.type = predictedType THEN 1 ELSE 0 END) AS correctPredictions,
       round(1000.0 * sum(CASE WHEN target.type = predictedType THEN 1 ELSE 0 END) / count(*)) / 10.0 AS accuracyPercent,
       avg(support) AS averageHistoricalSupport,
       'Conventional graph-feature baseline: predict crime type from prior crimes at the same location.' AS baselineReading;

// Query 1.3 - Leave-one-out area majority baseline for crime type.
MATCH (target:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a:Area)
WITH target, a
CALL {
  WITH target, a
  MATCH (other:Crime)-[:OCCURRED_AT]->(:Location)-[:LOCATION_IN_AREA]->(a)
  WHERE elementId(other) <> elementId(target)
    AND other.type IS NOT NULL
  WITH other.type AS predictedType, count(*) AS support
  ORDER BY support DESC, predictedType
  RETURN predictedType, support
  LIMIT 1
}
WITH target, predictedType, support
WHERE predictedType IS NOT NULL
RETURN count(*) AS evaluatedCrimes,
       sum(CASE WHEN target.type = predictedType THEN 1 ELSE 0 END) AS correctPredictions,
       round(1000.0 * sum(CASE WHEN target.type = predictedType THEN 1 ELSE 0 END) / count(*)) / 10.0 AS accuracyPercent,
       avg(support) AS averageHistoricalSupport,
       'Broader graph-feature baseline: predict crime type from dominant historical crime type in the area.' AS baselineReading;

// Query 1.4 - Crime outcome baseline from crime type.
MATCH (target:Crime)
WHERE target.last_outcome IS NOT NULL
WITH target
CALL {
  WITH target
  MATCH (other:Crime)
  WHERE elementId(other) <> elementId(target)
    AND other.type = target.type
    AND other.last_outcome IS NOT NULL
  WITH other.last_outcome AS predictedOutcome, count(*) AS support
  ORDER BY support DESC, predictedOutcome
  RETURN predictedOutcome, support
  LIMIT 1
}
WITH target, predictedOutcome, support
WHERE predictedOutcome IS NOT NULL
RETURN count(*) AS evaluatedCrimes,
       sum(CASE WHEN target.last_outcome = predictedOutcome THEN 1 ELSE 0 END) AS correctPredictions,
       round(1000.0 * sum(CASE WHEN target.last_outcome = predictedOutcome THEN 1 ELSE 0 END) / count(*)) / 10.0 AS accuracyPercent,
       avg(support) AS averageHistoricalSupport,
       'Outcome baseline: predicts outcome from the dominant historical outcome for the crime type.' AS baselineReading;

// SECTION 2: SUPERVISED SOCIAL-FAMILY LINK PREDICTION

// Query 2.1 - Materialize a temporary unified social-family target.
MATCH (p:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(q:Person)
WHERE elementId(p) < elementId(q)
MERGE (p)-[:EXPERIMENT_SOCIAL_LINK]->(q);

// Query 2.2 - Count unified social target.
MATCH (:Person)-[r:EXPERIMENT_SOCIAL_LINK]->(:Person)
RETURN count(r) AS experimentSocialLinks;

// Query 2.3 - Project broad context graph for unified social link prediction.
CALL gds.graph.project(
  'sweepSocialContextGraph',
  ['Person', 'Phone', 'Email', 'Location', 'Crime'],
  {
    EXPERIMENT_SOCIAL_LINK: {orientation: 'UNDIRECTED'},
    HAS_PHONE: {orientation: 'UNDIRECTED'},
    HAS_EMAIL: {orientation: 'UNDIRECTED'},
    CURRENT_ADDRESS: {orientation: 'UNDIRECTED'},
    PARTY_TO: {orientation: 'UNDIRECTED'},
    OCCURRED_AT: {orientation: 'UNDIRECTED'}
  }
)
YIELD graphName, nodeCount, relationshipCount, projectMillis
RETURN graphName, nodeCount, relationshipCount, projectMillis;

// Query 2.4 - Create social-family LP pipeline.
CALL gds.beta.pipeline.linkPrediction.create('sweep-social-lp-pipeline')
YIELD name
RETURN name AS pipeline;

// Query 2.5 - Add FastRP embeddings.
CALL gds.beta.pipeline.linkPrediction.addNodeProperty(
  'sweep-social-lp-pipeline',
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

// Query 2.6 - Add Node2Vec embeddings.
CALL gds.beta.pipeline.linkPrediction.addNodeProperty(
  'sweep-social-lp-pipeline',
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

// Query 2.7 - Add pairwise FastRP feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'sweep-social-lp-pipeline',
  'hadamard',
  {nodeProperties: ['fastRpEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// Query 2.8 - Add pairwise Node2Vec feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'sweep-social-lp-pipeline',
  'hadamard',
  {nodeProperties: ['node2vecEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// Query 2.9 - Configure social-family split.
CALL gds.beta.pipeline.linkPrediction.configureSplit(
  'sweep-social-lp-pipeline',
  {
    testFraction: 0.20,
    trainFraction: 0.60,
    validationFolds: 3,
    negativeSamplingRatio: 1.0
  }
)
YIELD splitConfig
RETURN splitConfig;

// Query 2.10 - Logistic Regression candidate.
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression(
  'sweep-social-lp-pipeline',
  {
    penalty: 0.0,
    maxEpochs: 200,
    learningRate: 0.001
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// Query 2.11 - Random Forest candidate.
CALL gds.beta.pipeline.linkPrediction.addRandomForest(
  'sweep-social-lp-pipeline',
  {
    numberOfSamplesRatio: 1.0,
    numberOfDecisionTrees: 200,
    maxFeaturesRatio: 1.0
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// Query 2.12 - Train unified social-family link prediction.
CALL gds.beta.pipeline.linkPrediction.train(
  'sweepSocialContextGraph',
  {
    pipeline: 'sweep-social-lp-pipeline',
    modelName: 'sweep-social-lp-model',
    sourceNodeLabel: 'Person',
    targetNodeLabel: 'Person',
    targetRelationshipType: 'EXPERIMENT_SOCIAL_LINK',
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
       'Unified social-family LP tests whether combining all observed social evidence improves over KNOWS-only prediction.' AS experimentReading;

// Query 2.13 - Top unified social-family predictions for review.
CALL gds.beta.pipeline.linkPrediction.predict.stream(
  'sweepSocialContextGraph',
  {modelName: 'sweep-social-lp-model', topN: 50}
)
YIELD node1, node2, probability
WITH gds.util.asNode(node1) AS p1,
     gds.util.asNode(node2) AS p2,
     probability
WHERE p1:Person
  AND p2:Person
  AND elementId(p1) < elementId(p2)
  AND NOT (p1)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(p2)
RETURN p1.name + ' ' + coalesce(p1.surname, '') AS personA,
       p2.name + ' ' + coalesce(p2.surname, '') AS personB,
       probability,
       'Unified social-family supervised LP candidate for review only.' AS reading
ORDER BY probability DESC
LIMIT 25;

// SECTION 3: HEAVIER CRIME-TYPE CLASSIFICATION

// Query 3.1 - Project crime-context graph with target property.
CALL gds.graph.project(
  'sweepCrimeClassGraph',
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
YIELD graphName, nodeCount, relationshipCount, projectMillis
RETURN graphName, nodeCount, relationshipCount, projectMillis;

// Query 3.2 - Create crime classification pipeline.
CALL gds.beta.pipeline.nodeClassification.create('sweep-crime-class-pipeline')
YIELD name
RETURN name AS pipeline;

// Query 3.3 - Add FastRP embeddings.
CALL gds.beta.pipeline.nodeClassification.addNodeProperty(
  'sweep-crime-class-pipeline',
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

// Query 3.4 - Select embedding features.
CALL gds.beta.pipeline.nodeClassification.selectFeatures(
  'sweep-crime-class-pipeline',
  ['embedding']
)
YIELD featureProperties
RETURN featureProperties;

// Query 3.5 - Configure split.
CALL gds.beta.pipeline.nodeClassification.configureSplit(
  'sweep-crime-class-pipeline',
  {
    testFraction: 0.20,
    validationFolds: 3
  }
)
YIELD splitConfig
RETURN splitConfig;

// Query 3.6 - Logistic Regression candidate.
CALL gds.beta.pipeline.nodeClassification.addLogisticRegression(
  'sweep-crime-class-pipeline',
  {
    maxEpochs: 100,
    learningRate: 0.01
  }
)
YIELD parameterSpace
RETURN parameterSpace;

// Query 3.7 - Train crime-class classifier.
CALL gds.beta.pipeline.nodeClassification.train(
  'sweepCrimeClassGraph',
  {
    pipeline: 'sweep-crime-class-pipeline',
    modelName: 'sweep-crime-class-model',
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
       modelInfo.bestParameters AS bestParameters,
       'Crime-type classifier tests whether graph-context embeddings recover crime type better than simple baselines.' AS experimentReading;

// SECTION 4: CLEANUP AND SUMMARY

// Query 4.1 - Delete temporary relationship from stored database after projection/model runs.
MATCH ()-[r:EXPERIMENT_SOCIAL_LINK]->()
DELETE r;

// Query 4.2 - Final experiment comparison summary.
CALL gds.model.list('sweep-social-lp-model')
YIELD modelInfo AS socialModel
WITH socialModel.metrics.AUCPR.test AS socialFamilyTestAUCPR,
     socialModel.bestParameters.methodName AS socialFamilySelectedModel
CALL gds.model.list('sweep-crime-class-model')
YIELD modelInfo AS crimeModel
RETURN socialFamilySelectedModel,
       socialFamilyTestAUCPR,
       crimeModel.bestParameters.methodName AS crimeClassSelectedModel,
       crimeModel.metrics.F1_WEIGHTED.test AS crimeClassTestWeightedF1,
       crimeModel.metrics.ACCURACY.test AS crimeClassTestAccuracy,
       'Use this table to decide which experiments deserve promotion into the final paper and deck.' AS sweepRecommendation;
