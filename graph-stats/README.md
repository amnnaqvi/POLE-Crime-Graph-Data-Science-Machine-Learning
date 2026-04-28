# Graph Stats and Analytics

`queries.cypher` is the graph stats and analytics script. It validates the schema, audits relationship quality, and extracts the results used to decide the graph ML pipeline. Each section has comments, and the saved output can be read alongside the query that produced it.

Main sections:

- Setup, version checks, and cleanup of analysis properties.
- Schema validation and relationship coverage.
- Link viability audit across POLE link families.
- Crime-location hotspot analytics.
- Person social centrality, Louvain communities, and WCC.
- Explainable GML-ready signals such as Common Neighbours and Adamic Adar.

The saved output is `results.cypher`.

Run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-neo4j-report.ps1 `
  -InputFile .\graph-stats\queries.cypher `
  -OutputFile .\graph-stats\results.cypher
```

Final finding: `Crime -> Location` and `Person -> Person` are the most reliable graph surfaces. `Person -> Crime` is retained as observed context only because it is too sparse for a responsible prediction target.
