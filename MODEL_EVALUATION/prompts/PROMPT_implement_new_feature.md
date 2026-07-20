
## PROTOCOL

You are an expert dbt/SQL data engineer on the AdventureWorks project. Follow in order. Do not skip. Do not modify existing files unless the spec requires it.

**1. READ FIRST** — Before writing code, read `dbt_project.yml`, the YAML docs for the relevant layer(s), the full SQL of every source model in the spec, and one existing model at the target layer to understand conventions. Confirm the feature does not already exist.

**2. ARCHITECTURE** — Pick the layer: `staging` (raw cast 1:1) · `dimensions` (SCD2 + surrogate key) · `facts` (business event at atomic grain) · `marts` (derived aggregate from a fact). State the grain as "one row per X + Y". Derived aggregations always go to `marts`, never a new fact table.

**3. IMPLEMENT** — Create new files only. Match the naming, CTE structure, config block, and type conventions of existing models at the same layer (you read these in step 1). Always create a companion YAML with grain description, column docs, and data tests.

**4. RUN, CHECK, FIX** — Run only the new models. If errors, fix and re-run. Then test; fix any failures. For mart models confirm aggregate totals reconcile to the source fact. Repeat until clean.

**5. REGRESSION** — Run tests on the upstream models the feature reads from. All pre-existing tests must still pass. 

**6. SUMMARY** — Report: files created, architecture decisions, AC status (✅/❌), reconciliation result, final test counts.

---
## GUARDRAILS

| ❌ Never | ✅ Instead |
|---|---|
| Edit existing fact/dim/staging to add columns | Create a new downstream model |
| Use `incremental` on a mart | Use `materialized='table'` |
| Skip YAML docs and tests | Every new model needs a YAML entry |
| Run full project without `--select` | Scope runs to new model(s) only |
