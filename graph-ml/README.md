# Graph Machine Learning

`pipeline.cypher` is the final consolidated graph ML pipeline. It uses the graph stats link audit to avoid forcing person-crime prediction as the main target.

Main sections:

- Link-family scorecard carried forward from graph stats.
- Hotspot and community analytics used for interpretation.
- Social graph projection and Louvain analysis.
- Supervised social-family link prediction with FastRP + Node2Vec embeddings; Logistic Regression was tested in the experiment sweep, and the final demo pipeline keeps Random Forest because it gives usable probability separation.
- Deployment gate that blocks supervised write-back unless held-out AUCPR and probability spread both pass.
- Unsupervised FastRP + kNN social similarity for review-only candidate discovery.
- Secondary crime-type node classification using graph-context embeddings.
- Explainable Common Neighbours and Adamic Adar social-link candidates.
- Review-only `PREDICTED_SOCIAL_EXPLAINABLE` write-back.

The saved output is `results.cypher`. The final demo-facing files in this folder are `README.md`, `pipeline.cypher`, `results.cypher`, and `presentation.tex`; experiment sweeps and audit scratch files are ignored by git.

Run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-neo4j-report.ps1 `
  -InputFile .\graph-ml\pipeline.cypher `
  -OutputFile .\graph-ml\results.cypher
```

Final finding: supervised social-family link prediction selected Random Forest by validation AUCPR and reached 0.5578 held-out test AUCPR in the final pipeline, so the pipeline wrote 25 review-only supervised social candidates. Crime-type node classification was weak, with test weighted F1 0.1441. The clearest GML outputs are supervised, explainable, and unsupervised social-link candidates for human review.

