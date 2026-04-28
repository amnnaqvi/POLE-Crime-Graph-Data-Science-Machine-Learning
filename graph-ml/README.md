# Graph Machine Learning

`pipeline.cypher` is the graph ML pipeline. It uses the graph stats link audit to avoid forcing person-crime prediction as the main target.

Main sections:

- Link-family scorecard carried forward from graph stats.
- Hotspot and community analytics used in the demo.
- Social graph projection and Louvain analysis.
- Supervised `KNOWS` link prediction with FastRP embeddings and logistic regression.
- Calibration gate that blocks flat supervised write-back.
- Explainable Common Neighbours and Adamic Adar social-link candidates.
- Review-only `PREDICTED_KNOWS_EXPLAINABLE` write-back.

The saved output is `results.cypher`.

Run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-neo4j-report.ps1 `
  -InputFile .\graph-ml\pipeline.cypher `
  -OutputFile .\graph-ml\results.cypher
```

The final course demo deck is kept local and ignored by Git, along with the generated PDF.

Final finding: supervised `KNOWS` link prediction had test AUCPR 0.5942, but live probabilities were almost flat, so the pipeline correctly wrote back zero supervised predictions. The clearest GML output is the small set of explainable review-only social links.
