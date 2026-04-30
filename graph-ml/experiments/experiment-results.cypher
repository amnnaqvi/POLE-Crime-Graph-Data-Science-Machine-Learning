// POLE Crime Investigation - Experiment Results
// Rayyan Shah (rs08770) and Amn Naqvi (sn08776)
// This file records the extra ML experiments we ran before choosing the final pipeline.
// It includes the queries and the results we got from Neo4j/GDS, so the model choices
// in the final submission can be checked instead of taken on trust.
// The main pipeline file is pipeline.cypher; this file is supporting evidence.

// SECTION 0: CLEANUP

// Query 1
MATCH ()-[r:EXPERIMENT_SOCIAL_LINK]->()
DELETE r;

// Result 1
// 
// No rows returned

// Query 2
CALL gds.model.drop('sweep-social-lp-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

// Result 2
// droppedModel
// sweep-social-lp-model

// Query 3
CALL gds.pipeline.drop('sweep-social-lp-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

// Result 3
// droppedPipeline
// sweep-social-lp-pipeline

// Query 4
CALL gds.graph.drop('sweepSocialContextGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// Result 4
// droppedGraph
// sweepSocialContextGraph

// Query 5
CALL gds.model.drop('sweep-crime-class-model', false)
YIELD modelName
RETURN modelName AS droppedModel;

// Result 5
// droppedModel
// No rows returned

// Query 6
CALL gds.pipeline.drop('sweep-crime-class-pipeline', false)
YIELD pipelineName
RETURN pipelineName AS droppedPipeline;

// Result 6
// droppedPipeline
// No rows returned

// Query 7
CALL gds.graph.drop('sweepCrimeClassGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// Result 7
// droppedGraph
// No rows returned

// Query 8
CALL gds.graph.drop('sweepCrimeLocationSimilarityGraph', false)
YIELD graphName
RETURN graphName AS droppedGraph;

// Result 8
// droppedGraph
// No rows returned

// Query 9
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

// Result 9
// target | observedLinks | coveredSources | sources | sourceCoveragePercent | coveredTargets | targets | targetCoveragePercent | pairDensityPercent | reading
// Crime-Location OCCURRED_AT | 28762 | 28762 | 28762 | 100.0 | 13302 | 14904 | 89.3 | 0.0067 | Strongest descriptive surface, better for hotspot ranking than supervised LP.
// Person-Person social family | 1180 | 269 | 369 | 72.9 | 260 | 369 | 70.5 | 0.8666 | Best link prediction target because it is social/contextual rather than accusatory.
// Vehicle-Crime INVOLVED_IN | 978 | 978 | 1000 | 97.8 | 978 | 28762 | 3.4 | 0.0034 | Good context coverage, weak prediction because vehicles are mostly one-off.
// Person-Crime PARTY_TO | 55 | 29 | 369 | 7.9 | 55 | 28762 | 0.2 | 0.0005 | Too sparse and too sensitive for main prediction.

// Query 10
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

// Result 10
// evaluatedCrimes | correctPredictions | accuracyPercent | averageHistoricalSupport | baselineReading
// 21431 | 6915 | 32.3 | 3.237366431804385 | Conventional graph-feature baseline: predict crime type from prior crimes at the same location.

// Query 11
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

// Result 11
// evaluatedCrimes | correctPredictions | accuracyPercent | averageHistoricalSupport | baselineReading
// 28760 | 8834 | 30.7 | 129.9741307371357 | Broader graph-feature baseline: predict crime type from dominant historical crime type in the area.

// Query 12
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

// Result 12
// evaluatedCrimes | correctPredictions | accuracyPercent | averageHistoricalSupport | baselineReading
// 28761 | 17678 | 61.5 | 2445.5774138590523 | Outcome baseline: predicts outcome from the dominant historical outcome for the crime type.

// Query 13
// SECTION 2: SUPERVISED SOCIAL-FAMILY LINK PREDICTION

// Query 2.1 - Materialize a temporary unified social-family target.
MATCH (p:Person)-[:KNOWS|KNOWS_SN|KNOWS_PHONE|KNOWS_LW|FAMILY_REL]-(q:Person)
WHERE elementId(p) < elementId(q)
MERGE (p)-[:EXPERIMENT_SOCIAL_LINK]->(q);

// Result 13
// 
// No rows returned

// Query 14
// Query 2.2 - Count unified social target.
MATCH (:Person)-[r:EXPERIMENT_SOCIAL_LINK]->(:Person)
RETURN count(r) AS experimentSocialLinks;

// Result 14
// experimentSocialLinks
// 586

// Query 15
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

// Result 15
// graphName | nodeCount | relationshipCount | projectMillis
// sweepSocialContextGraph | 44691 | 60854 | 425

// Query 16
// Query 2.4 - Create social-family LP pipeline.
CALL gds.beta.pipeline.linkPrediction.create('sweep-social-lp-pipeline')
YIELD name
RETURN name AS pipeline;

// Result 16
// pipeline
// sweep-social-lp-pipeline

// Query 17
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

// Result 17
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0,1.0],"embeddingDimension":128,"contextNodeLabels":[],"mutateProperty":"fastRpEmbedding"}}]

// Query 18
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

// Result 18
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0,1.0],"embeddingDimension":128,"contextNodeLabels":[],"mutateProperty":"fastRpEmbedding"}},{"name":"gds.node2vec.mutate","config":{"randomSeed":42,"walkLength":20,"walksPerNode":10,"contextRelationshipTypes":[],"embeddingDimension":64,"contextNodeLabels":[],"mutateProperty":"node2vecEmbedding"}}]

// Query 19
// Query 2.7 - Add pairwise FastRP feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'sweep-social-lp-pipeline',
  'hadamard',
  {nodeProperties: ['fastRpEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// Result 19
// featureSteps
// [{"name":"HADAMARD","config":{"nodeProperties":["fastRpEmbedding"]}}]

// Query 20
// Query 2.8 - Add pairwise Node2Vec feature.
CALL gds.beta.pipeline.linkPrediction.addFeature(
  'sweep-social-lp-pipeline',
  'hadamard',
  {nodeProperties: ['node2vecEmbedding']}
)
YIELD featureSteps
RETURN featureSteps;

// Result 20
// featureSteps
// [{"name":"HADAMARD","config":{"nodeProperties":["fastRpEmbedding"]}},{"name":"HADAMARD","config":{"nodeProperties":["node2vecEmbedding"]}}]

// Query 21
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

// Result 21
// splitConfig
// {"negativeSamplingRatio":1.0,"testFraction":0.2,"validationFolds":3,"trainFraction":0.6}

// Query 22
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

// Result 22
// parameterSpace
// {"MultilayerPerceptron":[],"RandomForest":[],"LogisticRegression":[{"maxEpochs":200,"minEpochs":1,"classWeights":[],"penalty":0.0,"patience":1,"methodName":"LogisticRegression","focusWeight":0.0,"batchSize":100,"tolerance":0.001,"learningRate":0.001}]}

// Query 23
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

// Result 23
// parameterSpace
// {"MultilayerPerceptron":[],"RandomForest":[{"maxDepth":2147483647,"minLeafSize":1,"criterion":"GINI","minSplitSize":2,"numberOfDecisionTrees":200,"maxFeaturesRatio":1.0,"methodName":"RandomForest","numberOfSamplesRatio":1.0}],"LogisticRegression":[{"maxEpochs":200,"minEpochs":1,"classWeights":[],"penalty":0.0,"patience":1,"methodName":"LogisticRegression","focusWeight":0.0,"batchSize":100,"tolerance":0.001,"learningRate":0.001}]}

// Query 24
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

// Result 24
// trainMillis | trainAUCPR | validationAUCPR | testAUCPR | selectedModel | bestParameters | experimentReading
// 94067 | 0.9657513326117838 | 0.6056146367732689 | 0.5693421183224903 | RandomForest | {"maxDepth":2147483647,"minLeafSize":1,"criterion":"GINI","minSplitSize":2,"numberOfDecisionTrees":200,"maxFeaturesRatio":1.0,"methodName":"RandomForest","numberOfSamplesRatio":1.0} | Unified social-family LP tests whether combining all observed social evidence improves over KNOWS-only prediction.

// Query 25
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

// Result 25
// personA | personB | probability | reading
// Todd Hamilton | Frances Sullivan | 0.875 | Unified social-family supervised LP candidate for review only.
// Sandra Payne | Philip Welch | 0.87 | Unified social-family supervised LP candidate for review only.
// Richard Hanson | Norma Jackson | 0.84 | Unified social-family supervised LP candidate for review only.
// Michael Mason | Lois Hernandez | 0.83 | Unified social-family supervised LP candidate for review only.
// Matthew Phillips | Justin Payne | 0.815 | Unified social-family supervised LP candidate for review only.
// Nicholas Mason | Justin Payne | 0.815 | Unified social-family supervised LP candidate for review only.
// Heather Howard | Jennifer Jacobs | 0.815 | Unified social-family supervised LP candidate for review only.
// Linda Baker | Evelyn Wood | 0.81 | Unified social-family supervised LP candidate for review only.
// Lawrence Warren | Gloria Owens | 0.81 | Unified social-family supervised LP candidate for review only.
// Nicholas Mason | Matthew Phillips | 0.805 | Unified social-family supervised LP candidate for review only.
// Michael Mason | Philip Welch | 0.805 | Unified social-family supervised LP candidate for review only.
// Rachel Fuller | Alan Hicks | 0.8 | Unified social-family supervised LP candidate for review only.
// William Dixon | Raymond Walker | 0.8 | Unified social-family supervised LP candidate for review only.
// Raymond Walker | Alan Ward | 0.8 | Unified social-family supervised LP candidate for review only.
// Larry Hunter | Victor Armstrong | 0.8 | Unified social-family supervised LP candidate for review only.
// Carl Hayes | Angela Mccoy | 0.795 | Unified social-family supervised LP candidate for review only.
// Jennifer Gray | Louis Tucker | 0.795 | Unified social-family supervised LP candidate for review only.
// William Dixon | Alan Ward | 0.79 | Unified social-family supervised LP candidate for review only.
// Raymond Williamson | Dennis Bradley | 0.785 | Unified social-family supervised LP candidate for review only.
// Michael Mason | Sandra Payne | 0.785 | Unified social-family supervised LP candidate for review only.
// Irene Austin | Eugene Ferguson | 0.785 | Unified social-family supervised LP candidate for review only.
// Julie Moreno | Norma Hansen | 0.785 | Unified social-family supervised LP candidate for review only.
// Lawrence Warren | Jeffrey Campbell | 0.78 | Unified social-family supervised LP candidate for review only.
// Lawrence Stephens | Joseph Rogers | 0.78 | Unified social-family supervised LP candidate for review only.
// Carlos Chavez | Juan King | 0.78 | Unified social-family supervised LP candidate for review only.

// Query 26
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

// Result 26
// graphName | nodeCount | relationshipCount | projectMillis
// sweepCrimeClassGraph | 45673 | 117018 | 465

// Query 27
// Query 3.2 - Create crime classification pipeline.
CALL gds.beta.pipeline.nodeClassification.create('sweep-crime-class-pipeline')
YIELD name
RETURN name AS pipeline;

// Result 27
// pipeline
// sweep-crime-class-pipeline

// Query 28
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

// Result 28
// nodePropertySteps
// [{"name":"gds.fastRP.mutate","config":{"randomSeed":42,"contextRelationshipTypes":[],"iterationWeights":[0.0,1.0,1.0,1.0],"embeddingDimension":64,"contextNodeLabels":[],"mutateProperty":"embedding"}}]

// Query 29
// Query 3.4 - Select embedding features.
CALL gds.beta.pipeline.nodeClassification.selectFeatures(
  'sweep-crime-class-pipeline',
  ['embedding']
)
YIELD featureProperties
RETURN featureProperties;

// Result 29
// featureProperties
// ["embedding"]

// Query 30
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

// Result 30
// splitConfig
// {"testFraction":0.2,"validationFolds":3}

// Query 31
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

// Result 31
// parameterSpace
// {"MultilayerPerceptron":[],"RandomForest":[],"LogisticRegression":[{"maxEpochs":100,"minEpochs":1,"classWeights":[],"penalty":0.0,"patience":1,"methodName":"LogisticRegression","focusWeight":0.0,"batchSize":100,"tolerance":0.001,"learningRate":0.01}]}

// Query 32
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

// Result 32
// trainMillis | trainWeightedF1 | validationWeightedF1 | testWeightedF1 | testAccuracy | selectedModel | bestParameters | experimentReading
// 13310 | 0.14192116065604077 | 0.14192116089255638 | 0.14407914891941245 | 0.30957762 | LogisticRegression | {"maxEpochs":100,"minEpochs":1,"classWeights":[],"penalty":0.0,"patience":1,"methodName":"LogisticRegression","focusWeight":0.0,"batchSize":100,"tolerance":0.001,"learningRate":0.01} | Crime-type classifier tests whether graph-context embeddings recover crime type better than simple baselines.

// Query 33
// SECTION 4: CLEANUP AND SUMMARY

// Query 4.1 - Delete temporary relationship from stored database after projection/model runs.
MATCH ()-[r:EXPERIMENT_SOCIAL_LINK]->()
DELETE r;

// Result 33
// 
// No rows returned

// Query 34
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

// Result 34
// socialFamilySelectedModel | socialFamilyTestAUCPR | crimeClassSelectedModel | crimeClassTestWeightedF1 | crimeClassTestAccuracy | sweepRecommendation
// RandomForest | 0.5693421183224903 | LogisticRegression | 0.14407914891941245 | 0.30957762 | Use this table to decide which experiments deserve promotion into the final paper and deck.
