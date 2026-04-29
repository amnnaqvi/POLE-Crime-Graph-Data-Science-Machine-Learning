# Graph Data Science and Graph Machine Learning on the POLE Crime Network

This project uses the Neo4j POLE Crime Investigation dataset to explore graph statistics, graph analytics, and graph machine learning on a connected crime investigation network.

The original dataset is from the Neo4j graph examples repository:

https://github.com/neo4j-graph-examples/pole

## Selected Dataset

We use the Crime Investigation (POLE) dataset from Neo4j's graph examples. POLE stands for Persons, Objects, Locations, and Events. The dataset models crime and investigation data as a graph where people, places, objects, crimes, phones, vehicles, officers, and areas are connected through relationships.

The dataset is provided as a Neo4j dump, so it can be loaded directly into Neo4j Desktop. This project works with the full graph rather than a small manually selected subset.

## Motivation

Crime and investigation data fits naturally into a graph structure. A graph makes it easier to study how people, places, objects, and incidents are connected, compared with treating the same information as separate tables.

The POLE model lets us explore questions such as:

- Which locations appear most often in crime records?
- Which areas or places show repeated crime patterns?
- Which people are central in the social graph?
- Which communities form in the person-person network?
- Which links are strong enough for graph machine learning?
- Where does the data become too sparse for responsible prediction?

The main lesson from the project is that the graph has useful signals for hotspots, social communities, and review-priority context. Direct `Person -> Crime` prediction was considered, but the `PARTY_TO` target is too sparse and sensitive to use as the main automated prediction target.

## Repository Layout

```text
.
|-- graph-stats/
|   |-- queries.cypher          # Graph stats and analytics queries
|   |-- results.cypher          # Saved graph stats results
|   `-- README.md
|-- graph-ml/
|   |-- pipeline.cypher         # Graph ML pipeline
|   |-- results.cypher          # Saved graph ML results
|   `-- README.md
|-- assets/
|   |-- POLE.jpeg
|   `-- neo4j_graph.png
|-- data/
|   `-- pole-50.dump
|-- scripts/
|   `-- run-neo4j-report.ps1
|-- .neo4j.local.example.ps1
`-- README.md
```

## Neo4j Setup

1. Open Neo4j Desktop.
2. Create or open a local DBMS for the project.
3. Restore or upload `data/pole-50.dump`.
4. Install or enable the Neo4j Graph Data Science plugin.
5. Start the DBMS and confirm that Neo4j Browser works.

The PowerShell runner uses Neo4j's HTTP endpoint. By default it expects:

- HTTP URL: `http://localhost:7474`
- Database: `neo4j`
- Username: `neo4j`

Do not commit your real Neo4j password. For local runs, copy:

```powershell
.neo4j.local.example.ps1
```

to:

```powershell
.neo4j.local.ps1
```

Then set your local connection values in `.neo4j.local.ps1`. That file is ignored by Git.

You can also use environment variables instead:

```powershell
$env:NEO4J_HTTP_URL = "http://localhost:7474"
$env:NEO4J_DATABASE = "neo4j"
$env:NEO4J_USERNAME = "neo4j"
$env:NEO4J_PASSWORD = "your-password"
```

The Neo4j Desktop DBMS name can be whatever you called it locally. The runner only needs the HTTP URL, database name, username, and password.

## Running the Scripts

Run the graph stats and analytics script first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-neo4j-report.ps1 `
  -InputFile .\graph-stats\queries.cypher `
  -OutputFile .\graph-stats\results.cypher
```

Then run the graph ML pipeline:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-neo4j-report.ps1 `
  -InputFile .\graph-ml\pipeline.cypher `
  -OutputFile .\graph-ml\results.cypher
```

The runner executes each Cypher statement and writes the result below the query. This keeps the scripts and outputs easy to inspect and reproduce.

## Main Results

- Full graph: 61,521 nodes and 105,840 relationships.
- Strongest link family: `Crime -> Location` with 28,762 `OCCURRED_AT` links.
- Top 10 repeat locations cover 3,349 incidents, or 11.6% of all crimes.
- Investigation outcome analysis: 17,087 crimes, or 59.4%, have no suspect identified.
- Officer workload: 1,000 officers, average caseload 28.76, maximum caseload 50.
- Social graph: 1,180 person-person links.
- Louvain community detection: 41 communities, modularity 0.6710.
- Social structure diagnostics: average local clustering coefficient 0.1611 and maximum k-core 8.
- Phone-call layer: 118 person-person communication pairs, all already covered by social edges.
- `Person -> Crime` / `PARTY_TO`: only 55 links, 0.0005% positive class.
- Supervised social-family link prediction: GDS compared Logistic Regression and Random Forest with FastRP + Node2Vec features; Random Forest reached 0.5578 test AUCPR in the final pipeline.
- Unsupervised social similarity: FastRP + kNN produces review-only structurally similar person pairs.
- Crime-type node classification: FastRP + Logistic Regression gives weak test weighted F1 0.1441, showing graph structure alone does not recover crime type reliably.
- Supervised model write-back: 25 review-only candidate social links, because held-out AUCPR and probability spread passed the review gate.
- Explainable GML write-back: 4 review-only `PREDICTED_SOCIAL_EXPLAINABLE` links.

These results are meant to support investigative review and graph-analysis discussion, not automated decisions about individuals.

## Interpretation

The final interpretation focuses on POLE investigative analytics:

1. Graph model and database scale.
2. Link viability audit showing why `PARTY_TO` is not the main target.
3. Hotspot and place crime-type profiles.
4. Outcomes, officer workload, communication coverage, and structural social diagnostics.
5. Louvain social communities and crime-context concentration.
6. Review-priority people, framed as human-review context.
7. Supervised social-family link prediction with model comparison and a held-out-quality/calibration gate.
8. Unsupervised FastRP + kNN similarity and explainable Common Neighbours / Adamic Adar social-link candidates.
9. Secondary crime-type node classification, reported honestly as weak evidence.

The project does not claim that the model can identify who committed a crime. The stronger result is a graph workflow for connected investigation context, with clear limits on what should and should not be predicted.
