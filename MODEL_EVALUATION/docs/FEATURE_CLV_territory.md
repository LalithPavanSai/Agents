# Feature Specification: Customer Lifetime Value by Transaction-Time Territory

---

## Document Control

| Field            | Value                                                   |
|------------------|---------------------------------------------------------|
| Feature ID       | FEAT-001                                                |
| Feature Name     | CLV by Transaction-Time Territory Mart                  |
| Target Layer     | Mart (models/marts/)                                    |
| Priority         | High                                                    |
| Status           | Approved — Ready for Implementation                     |
| Author           | Data Engineering Team                                   |
| Last Updated     | 2026-07-17                                              |
| Source Fact      | `fact_internet_sales`                                   |
| Output Models    | `mart_clv_by_customer_territory`, `mart_clv_global_customer` |

---

## 1. Business Context & Problem Statement

### Background
The AdventureWorks data warehouse currently stores Internet Sales at the atomic transaction grain in `fact_internet_sales` (one row per order line). Each transaction carries `sales_territory_key` — the territory that was stamped on the original sales order header at the time of purchase.

### Problem
There is no pre-built analytical model that aggregates customer lifetime value (CLV) metrics. Business consumers (regional managers, marketing, CRM, executive dashboards) must re-aggregate the fact table ad-hoc in every BI report. This leads to:

- Inconsistent CLV segment definitions across reports
- Double-counting errors when multi-territory customers are not handled correctly
- CLV incorrectly attributed to a customer's **current** geography (from `dim_customer`) rather than the **territory where the sale actually occurred**
- No single source of truth for customer segmentation

### Goal
Build a CLV mart that pre-calculates lifetime metrics per customer per transaction-time territory, with a second global rollup per customer. Both models must derive territory attribution exclusively from the original sales transaction record.

---

## 2. Scope

### In Scope
- New mart model: `mart_clv_by_customer_territory` (grain: customer × sales territory)
- New mart model: `mart_clv_global_customer` (grain: customer, global rollup)
- YAML documentation and data tests for both models
- CLV segmentation logic (percentile-based within territory)
- Gross margin calculation using existing `total_product_cost` from fact table

### Out of Scope
- Reseller sales (covered by `fact_reseller_sales` — separate feature)
- Time-series / periodic CLV snapshots (future feature)
- Predictive CLV modelling (future data science feature)
- Modifications to any existing staging, dimension, or fact models
- Currency conversion (foreign currency orders already default to key=0 in fact table — inherited limitation)

---

## 3. Source Data Mapping

| Required Field          | Source Column                                   | Source Model              | Notes |
|-------------------------|-------------------------------------------------|---------------------------|-------|
| Customer identifier     | `customer_key`, `customer_alternate_key`        | `fact_internet_sales`, `dim_customer` | Must use `customer_alternate_key` (stable natural key) to survive SCD2 row changes |
| Transaction territory   | `sales_territory_key`                           | `fact_internet_sales`     | **Must NOT use** `dim_customer.geography_key` or `dim_customer.territory_id` |
| Territory labels        | `sales_territory_region`, `sales_territory_country`, `sales_territory_group` | `dim_sales_territory` | Join on `sales_territory_key` |
| Revenue                 | `sales_amount`                                  | `fact_internet_sales`     | `line_total` from source |
| Cost of goods           | `total_product_cost`                            | `fact_internet_sales`     | `standard_cost × order_qty` |
| Transaction date        | `order_date`                                    | `fact_internet_sales`     | Used for first/last purchase |
| Order identifier        | `sales_order_number`                            | `fact_internet_sales`     | For distinct order count |

### Critical SCD2 Handling Note
`dim_customer` is SCD Type 2. `fact_internet_sales` resolves `customer_key` to the row that was `is_current = true` at load time. If a customer's attributes change, a new `customer_key` is issued. Grouping by `customer_key` alone would split a customer's lifetime across multiple surrogate keys.

**Resolution — two-step approach:**
- **Step 1:** To resolve `customer_alternate_key` for every fact row (including rows pointing to historical SCD2 versions), join `dim_customer` on `customer_key` with **NO** `is_current` filter. This ensures old fact rows referencing non-current surrogate keys are not dropped.
- **Step 2:** After grouping by `customer_alternate_key`, join `dim_customer WHERE is_current = true` on `customer_alternate_key` to retrieve the current surrogate key and name attributes for output.

---

## 4. Functional Requirements

### FR-01: Territory-Time Attribution
Lifetime sales for a customer must be attributed to the territory stored on `fact_internet_sales.sales_territory_key`, which originates from `SalesOrderHeader.TerritoryID` at the time of sale. Under no circumstances may territory be resolved from `dim_customer.geography_key` or the customer's current address.

### FR-02: Multi-Territory Customers
A customer who purchased in multiple territories over their lifetime must appear as **multiple rows** in `mart_clv_by_customer_territory` — one row per unique `customer_alternate_key + sales_territory_key` combination. This is by design and required.

### FR-03: Lifetime Metrics
For each `customer_alternate_key + sales_territory_key` combination, calculate:
- Sum of `sales_amount` → `lifetime_sales_amount`
- Sum of `(sales_amount - total_product_cost)` → `lifetime_gross_margin`
- Gross margin percentage → `lifetime_gross_margin_pct`
- Count of distinct `sales_order_number` → `order_count`
- Count of all rows (line items) → `line_count`
- Average order value → `avg_order_value`
- Minimum `order_date` → `first_purchase_date`
- Maximum `order_date` → `last_purchase_date`
- Days between first and last purchase → `customer_tenure_days`

### FR-04: CLV Segmentation (Territory-Relative)
Assign a `clv_segment` to each row using percentile rank of `lifetime_sales_amount` within each `sales_territory_key`. This ensures segment thresholds are relative to the spending distribution within each territory (Southwest customers are not penalised for lower average spend vs Northeast).

| Segment  | Percentile Rank Within Territory |
|----------|----------------------------------|
| Platinum | ≥ 90th percentile                |
| Gold     | ≥ 70th percentile, < 90th        |
| Silver   | ≥ 40th percentile, < 70th        |
| Bronze   | < 40th percentile                |

### FR-05: Multi-Territory Flag
Add `distinct_territory_count` (count of distinct territories this customer has purchased in, across all their rows) so analysts can instantly identify cross-territory customers.

### FR-06: Global Customer Rollup
A second model `mart_clv_global_customer` must aggregate `mart_clv_by_customer_territory` to a single row per customer showing total lifetime value across all territories. CLV segment in this model is recalculated on the global total (not per-territory).

### FR-07: Reconciliation
`SUM(mart_clv_by_customer_territory.lifetime_sales_amount)` must equal `SUM(fact_internet_sales.sales_amount)` — no rows lost, no rows duplicated.

### FR-08: Materialization
Both mart models must be materialized as `table` (full refresh). CLV is a cumulative metric — any historical order change affects the current totals, making `incremental` unsafe.

### FR-09: Documentation
Both models must have complete YAML documentation including: model description, grain, column descriptions, and data tests.

---

## 5. Detailed Acceptance Criteria

### mart_clv_by_customer_territory

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC-01 | One row per `customer_alternate_key` + `sales_territory_key` | `SELECT customer_alternate_key, sales_territory_key, COUNT(*) FROM mart_clv_by_customer_territory GROUP BY 1,2 HAVING COUNT(*) > 1` → must return 0 rows |
| AC-02 | `sales_territory_key` is sourced from `fact_internet_sales.sales_territory_key` only — no join to `dim_customer.geography_key` or `dim_customer.territory_id` | Code review: no reference to `dim_customer.geography_key` or `dim_customer.territory_id` in mart SQL |
| AC-03 | `SUM(lifetime_sales_amount)` reconciles to `SUM(fact_internet_sales.sales_amount)` | `SELECT ABS(a.total - b.total) < 0.01 FROM (SELECT SUM(lifetime_sales_amount) total FROM mart_clv_by_customer_territory) a, (SELECT SUM(sales_amount) total FROM fact_internet_sales) b` → must be true |
| AC-04 | A customer who bought in multiple territories appears in multiple rows | `SELECT customer_alternate_key FROM mart_clv_by_customer_territory GROUP BY 1 HAVING COUNT(DISTINCT sales_territory_key) > 1` → must return rows if such customers exist in source data |
| AC-05 | `clv_segment` is one of: 'Platinum', 'Gold', 'Silver', 'Bronze' | dbt `accepted_values` test on `clv_segment` |
| AC-06 | `lifetime_sales_amount` > 0 for all rows | dbt `not_null` + custom `greater_than_zero` test or `dbt_utils.expression_is_true` |
| AC-07 | `order_count` ≥ 1 for all rows | dbt `not_null` test; `MIN(order_count)` ≥ 1 |
| AC-08 | `first_purchase_date` ≤ `last_purchase_date` | dbt `dbt_utils.expression_is_true` test |
| AC-09 | No `customer_alternate_key` is NULL | dbt `not_null` test |
| AC-10 | No `sales_territory_key` is NULL or 0 | dbt `not_null` test + custom check |
| AC-11 | `lifetime_gross_margin_pct` is between -1 and 1 | dbt `dbt_utils.expression_is_true` test |

### mart_clv_global_customer

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC-12 | One row per `customer_alternate_key` | dbt `unique` test on `customer_alternate_key` |
| AC-13 | `SUM(total_lifetime_sales)` reconciles to `SUM(fact_internet_sales.sales_amount)` | Same reconciliation query as AC-03 but against global mart |
| AC-14 | `territories_purchased_in` ≥ 1 for all rows | `MIN(territories_purchased_in)` ≥ 1 |
| AC-15 | `global_clv_segment` is one of: 'Platinum', 'Gold', 'Silver', 'Bronze' | dbt `accepted_values` test |

---

## 6. Column Specifications — mart_clv_by_customer_territory

| Column | Type | Description |
|--------|------|-------------|
| `customer_alternate_key` | VARCHAR | Stable natural business key (account_number). SCD2-safe grouping key. |
| `customer_key` | INTEGER | Most recent SCD2 surrogate from dim_customer (for BI tool joins). |
| `first_name` | VARCHAR | Customer first name (current). |
| `last_name` | VARCHAR | Customer last name (current). |
| `sales_territory_key` | INTEGER | FK to dim_sales_territory. Transaction-time territory surrogate. |
| `sales_territory_region` | VARCHAR | Territory region name (e.g. 'Northwest'). |
| `sales_territory_country` | VARCHAR | Country of territory (e.g. 'United States'). |
| `sales_territory_group` | VARCHAR | Territory group (e.g. 'North America'). |
| `lifetime_sales_amount` | DECIMAL(19,4) | SUM of sales_amount across all transactions in this territory. Reconciles to fact. |
| `lifetime_gross_margin` | DECIMAL(19,4) | SUM of (sales_amount - total_product_cost). |
| `lifetime_gross_margin_pct` | DECIMAL(7,4) | lifetime_gross_margin / lifetime_sales_amount. |
| `order_count` | INTEGER | COUNT of distinct sales_order_number values. |
| `line_count` | INTEGER | COUNT of all fact rows (order lines). |
| `avg_order_value` | DECIMAL(19,4) | lifetime_sales_amount / order_count. |
| `first_purchase_date` | TIMESTAMP | Earliest order_date for this customer-territory combination. |
| `last_purchase_date` | TIMESTAMP | Most recent order_date for this customer-territory combination. |
| `customer_tenure_days` | INTEGER | Days between first and last purchase (0 if only one order). |
| `distinct_territory_count` | INTEGER | Count of distinct territories this customer has purchased in (window across all rows). |
| `clv_percentile_rank` | DECIMAL(7,4) | PERCENT_RANK() of lifetime_sales_amount within sales_territory_key. |
| `clv_segment` | VARCHAR | 'Platinum' / 'Gold' / 'Silver' / 'Bronze' derived from clv_percentile_rank. |

---

## 7. Column Specifications — mart_clv_global_customer

| Column | Type | Description |
|--------|------|-------------|
| `customer_alternate_key` | VARCHAR | Stable natural business key. One row per customer. |
| `customer_key` | INTEGER | Most recent SCD2 surrogate from dim_customer. |
| `first_name` | VARCHAR | Customer first name (current). |
| `last_name` | VARCHAR | Customer last name (current). |
| `total_lifetime_sales` | DECIMAL(19,4) | SUM of lifetime_sales_amount across all territories. |
| `total_gross_margin` | DECIMAL(19,4) | SUM of lifetime_gross_margin across all territories. |
| `total_gross_margin_pct` | DECIMAL(7,4) | total_gross_margin / total_lifetime_sales. |
| `total_order_count` | INTEGER | SUM of order_count across territories. |
| `total_line_count` | INTEGER | SUM of line_count across territories. |
| `avg_order_value` | DECIMAL(19,4) | total_lifetime_sales / total_order_count. |
| `first_purchase_date` | TIMESTAMP | Earliest purchase date across all territories. |
| `last_purchase_date` | TIMESTAMP | Most recent purchase date across all territories. |
| `customer_tenure_days` | INTEGER | Days between first and last purchase globally. |
| `territories_purchased_in` | INTEGER | Count of distinct territories this customer has purchased in. |
| `global_clv_percentile_rank` | DECIMAL(7,4) | PERCENT_RANK() of total_lifetime_sales across all customers. |
| `global_clv_segment` | VARCHAR | 'Platinum' / 'Gold' / 'Silver' / 'Bronze' based on global total. |

---

## 8. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-01 | Both models materialized as `table` (full refresh, not incremental) |
| NFR-02 | Models must run in < 60 seconds on the DuckDB dev environment |
| NFR-03 | All columns must have descriptions in companion YAML file |
| NFR-04 | All key columns must have `not_null` dbt data tests |
| NFR-05 | `clv_segment` and `global_clv_segment` must have `accepted_values` tests |
