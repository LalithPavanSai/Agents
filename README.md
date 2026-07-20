# AdventureWorks dbt Model Evaluation

This repository contains a dbt star-schema data warehouse built on AdventureWorks source data, used to evaluate AI model capabilities for implementing new analytical features on an existing dbt project.

---

## Project Structure

```
Agents/
├── README.md
└── MODEL_EVALUATION/
    ├── pyproject.toml
    ├── data/                          # Raw CSV source files (22 tables)
    │   ├── Address.csv
    │   ├── SalesOrderHeader.csv
    │   ├── SalesOrderDetail.csv
    │   └── ... (19 more)
    ├── docs/                          # Feature requirement specifications
    │   ├── FEATURE_CLV_territory.md
    │   └── FEATURE_promotion_effectiveness.md
    ├── prompts/                       # AI implementation prompt templates
    │   └── PROMPT_implement_new_feature.md
    └── adventureworks/                # dbt project
        ├── dbt_project.yml
        └── models/
            ├── raw/                   # Baseline: CSV ingestion models (22 tables)
            ├── staging/               # Typed & cleaned views (person / production / sales)
            │   ├── person/
            │   ├── production/
            │   └── sales/
            ├── dimensions/            # SCD Type-2 conformed dimensions
            │   ├── dim_customer.sql
            │   ├── dim_product.sql
            │   ├── dim_sales_territory.sql
            │   ├── dim_promotion.sql
            │   ├── dim_geography.sql
            │   ├── dim_date.sql
            │   ├── dim_currency.sql
            │   └── dim_sales_reason.sql
            └── facts/                 # Atomic fact tables
                ├── fact_internet_sales.sql
                └── fact_internet_sales_reason.sql
```

---

## Baseline Code — `models/raw/`

The `raw/` layer is the entry point of the pipeline. It contains 22 SQL models that read directly from the CSV source files using DuckDB's `read_csv()` function and add audit columns (`record_source`, `load_dts`). **This layer is the baseline — do not modify these files when implementing new features.**

| Raw Model | Source Table |
|---|---|
| `Address.sql` | Person.Address |
| `BusinessEntityAddress.sql` | Person.BusinessEntityAddress |
| `CountryRegion.sql` | Person.CountryRegion |
| `Currency.sql` | Sales.Currency |
| `Customer.sql` | Sales.Customer |
| `EmailAddress.sql` | Person.EmailAddress |
| `Person.sql` | Person.Person |
| `PersonPhone.sql` | Person.PersonPhone |
| `Product.sql` | Production.Product |
| `ProductCategory.sql` | Production.ProductCategory |
| `ProductCostHistory.sql` | Production.ProductCostHistory |
| `ProductListPriceHistory.sql` | Production.ProductListPriceHistory |
| `ProductModel.sql` | Production.ProductModel |
| `ProductSubcategory.sql` | Production.ProductSubcategory |
| `SalesOrderDetail.sql` | Sales.SalesOrderDetail |
| `SalesOrderHeader.sql` | Sales.SalesOrderHeader |
| `SalesOrderHeaderSalesReason.sql` | Sales.SalesOrderHeaderSalesReason |
| `SalesReason.sql` | Sales.SalesReason |
| `SalesTerritory.sql` | Sales.SalesTerritory |
| `SpecialOffer.sql` | Sales.SpecialOffer |
| `SpecialOfferProduct.sql` | Sales.SpecialOfferProduct |
| `StateProvince.sql` | Person.StateProvince |

---

## Feature Requirements — `docs/`

The `docs/` folder contains structured feature specification documents. Each document defines a new analytical capability to be built on top of the existing star schema — without modifying any existing models.

### FEAT-001 — Customer Lifetime Value by Transaction-Time Territory
**File:** `docs/FEATURE_CLV_territory.md`

Builds two new mart models:
- `mart_clv_by_customer_territory` — one row per customer × sales territory. Aggregates lifetime sales, gross margin, order count, first/last purchase date, tenure, and CLV segment. Territory attribution uses the territory recorded on the original sales transaction (not the customer's current geography).
- `mart_clv_global_customer` — one row per customer. Global rollup across all territories with recalculated CLV segment.

Key constraints: SCD2-safe grouping by `customer_alternate_key`; percentile-based segmentation within territory.

### FEAT-002 — Promotion Effectiveness
**File:** `docs/FEATURE_promotion_effectiveness.md`

Builds one new mart model:
- `mart_promotion_effectiveness` — one row per promotion. Aggregates total revenue, discount given, pre-discount revenue, order count, units sold, and average order value per promotion. Includes a discount depth tier classification (No Discount / Low / Medium / High).

---

## Implementation Prompt — `prompts/`

**File:** `prompts/PROMPT_implement_new_feature.md`

A reusable AI prompt template for implementing any new dbt feature on this project. To use:

1. Open `PROMPT_implement_new_feature.md`
2.  paste/attach the relevant `docs/FEATURE_*.md` content
3. Paste the entire prompt into your AI coding assistant
4. The AI follows a 6-phase protocol: Read project → Decide architecture → Implement → Run & fix → Regression test → Deliver summary

The prompt enforces key guardrails: never modify existing models, always create companion YAML with tests, scope dbt runs to new models only.

---

## Running the Project

### 1. Install dependencies

All Python dependencies (dbt-core, dbt-duckdb, etc.) are managed via `pyproject.toml`. Install using `uv`:

```bash
cd MODEL_EVALUATION
uv sync --native-tls
```

### 2. Run dbt

```bash
cd MODEL_EVALUATION/adventureworks

# Full build
dbt run

# Build specific layer
dbt run --select staging.*
dbt run --select dimensions.*
dbt run --select facts.*

# Run tests
dbt test

# Build and test a specific new mart
dbt run --select mart_clv_by_customer_territory
dbt test --select mart_clv_by_customer_territory
```
