# Feature Specification: Promotion Effectiveness Mart

---

## Document Control

| Field            | Value                                                   |
|------------------|---------------------------------------------------------|
| Feature ID       | FEAT-002                                                |
| Feature Name     | Promotion Effectiveness Mart                            |
| Target Layer     | Mart (models/marts/)                                    |
| Priority         | High                                                    |
| Status           | Approved — Ready for Implementation                     |
| Author           | Data Engineering Team                                   |
| Last Updated     | 2026-07-20                                              |
| Source Fact      | `fact_internet_sales`                                   |
| Output Models    | `mart_promotion_effectiveness`                          |

---

## 1. Business Context & Problem Statement

### Background
The AdventureWorks data warehouse records promotional activity on every Internet Sales transaction via `fact_internet_sales.promotion_key` (FK to `dim_promotion`). Each order line carries a promotion (including the baseline 'No Discount' promotion for non-discounted lines). The discount amount and extended amount are stored at the line level.

### Problem
There is no pre-built analytical model that measures how effective each promotion is. Marketing and commercial teams must re-aggregate the fact table ad-hoc to answer basic questions such as:
- Which promotions drive the most revenue?
- How much revenue was given away as discount per promotion?
- How many distinct orders used each promotion?
- Is a promotion a low, medium, or high discount depth?

Without a single mart, these calculations are inconsistent across reports and expensive to recompute.

### Goal
Build a promotion effectiveness mart that aggregates `fact_internet_sales` to one row per promotion, providing revenue, discount, volume, and classification metrics. Include the 'No Discount' baseline so that discounted vs. non-discounted revenue is directly comparable.

---

## 2. Scope

### In Scope
- New mart model: `mart_promotion_effectiveness` (grain: one row per promotion_key)
- YAML documentation and data tests
- Discount depth tier classification derived from average discount percentage
- All promotions represented in `fact_internet_sales`, including the 'No Discount' baseline (promotion_key resolving to SpecialOfferID = 1)

### Out of Scope
- Reseller sales (separate pipeline)
- Time-series promotion performance (future feature — this mart is a lifetime rollup)
- Promotion ROI including marketing spend (marketing cost data not in source)
- Modifications to any existing staging, dimension, or fact models

---

## 3. Source Data Mapping

| Required Field          | Source Column                               | Source Model          | Notes |
|-------------------------|---------------------------------------------|-----------------------|-------|
| Promotion identifier    | `promotion_key`                             | `fact_internet_sales` | FK to dim_promotion surrogate |
| Promotion attributes    | `english_promotion_name`, `english_promotion_type`, `english_promotion_category`, `discount_pct` | `dim_promotion` | Join on `promotion_key`, `is_current = true` |
| Net revenue             | `sales_amount`                              | `fact_internet_sales` | Line total after discount |
| Discount amount         | `discount_amount`                           | `fact_internet_sales` | Total monetary discount on line |
| Pre-discount revenue    | `extended_amount`                           | `fact_internet_sales` | unit_price × order_quantity |
| Discount fraction       | `unit_price_discount_pct`                   | `fact_internet_sales` | Per-line discount fraction |
| Order identifier        | `sales_order_number`                        | `fact_internet_sales` | For distinct order count |
| Units                   | `order_quantity`                            | `fact_internet_sales` | Units sold |
| Transaction date        | `order_date`                                | `fact_internet_sales` | For first/last used dates |

---

## 4. Functional Requirements

### FR-01: Promotion Grain
One row per `promotion_key`. Every promotion present in `fact_internet_sales` must appear in the mart, including promotion_key = 0 (unresolved) if present.

### FR-02: Revenue Metrics
For each promotion calculate:
- `total_revenue` = SUM(`sales_amount`) — net revenue after discount
- `total_discount_given` = SUM(`discount_amount`) — total monetary value of discounts applied
- `total_gross_before_discount` = SUM(`extended_amount`) — revenue before any discount

### FR-03: Volume Metrics
For each promotion calculate:
- `total_orders` = COUNT(DISTINCT `sales_order_number`)
- `total_line_items` = COUNT(*) — all fact rows
- `total_units_sold` = SUM(`order_quantity`)
- `avg_order_value` = `total_revenue` / `total_orders`

### FR-04: Discount Depth Metrics
- `avg_discount_pct` = AVG(`unit_price_discount_pct`) — average discount fraction across all lines
- `catalogue_discount_pct` = `dim_promotion.discount_pct` — the advertised/catalogue discount rate

### FR-05: Temporal Range
- `first_used_date` = MIN(`order_date`) — earliest date this promotion appeared on a transaction
- `last_used_date` = MAX(`order_date`) — most recent date

### FR-06: Discount Depth Tier
Classify each promotion row into a discount depth tier based on `avg_discount_pct`:

| Tier | Condition |
|------|-----------|
| `No Discount` | `avg_discount_pct` = 0 |
| `Low` | `avg_discount_pct` > 0 and < 0.05 |
| `Medium` | `avg_discount_pct` ≥ 0.05 and < 0.20 |
| `High` | `avg_discount_pct` ≥ 0.20 |

### FR-07: Reconciliation
`SUM(mart_promotion_effectiveness.total_revenue)` must equal `SUM(fact_internet_sales.sales_amount)` — no promotion rows dropped, no double counting.

### FR-08: Materialization
Materialized as `table` (full refresh). Promotion effectiveness is a cumulative rollup — any new transaction changes promotion totals.

### FR-09: Documentation
Complete YAML documentation including model description, grain, column descriptions, and data tests.

---

## 5. Detailed Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC-01 | One row per `promotion_key` | dbt `unique` test on `promotion_key` |
| AC-02 | No NULL `promotion_key` | dbt `not_null` test |
| AC-03 | `SUM(total_revenue)` reconciles to `SUM(fact_internet_sales.sales_amount)` | `SELECT ABS(a.t - b.t) < 0.01 FROM (SELECT SUM(total_revenue) t FROM mart_promotion_effectiveness) a, (SELECT SUM(sales_amount) t FROM fact_internet_sales) b` → true |
| AC-04 | `discount_depth_tier` is one of: 'No Discount', 'Low', 'Medium', 'High' | dbt `accepted_values` test |
| AC-05 | No NULL `total_revenue` | dbt `not_null` test |
| AC-06 | No NULL `total_orders` | dbt `not_null` test |
| AC-07 | `first_used_date` ≤ `last_used_date` for all rows | Query check |
| AC-08 | No NULL `english_promotion_name` | dbt `not_null` test |
| AC-09 | No NULL `total_discount_given` | dbt `not_null` test |
| AC-10 | No NULL `discount_depth_tier` | dbt `not_null` test |

---

## 6. Column Specifications — mart_promotion_effectiveness

| Column | Type | Description |
|--------|------|-------------|
| `promotion_key` | INTEGER | PK. FK to dim_promotion.promotion_key (surrogate). |
| `english_promotion_name` | VARCHAR | Promotion display name (e.g. 'No Discount', 'Mountain-100 Clearance Sale'). |
| `english_promotion_type` | VARCHAR | Type classification (e.g. 'No Discount', 'Seasonal Discount', 'Volume Discount'). |
| `english_promotion_category` | VARCHAR | Category (e.g. 'No Discount', 'Reseller', 'Customer'). |
| `catalogue_discount_pct` | DECIMAL(7,4) | Advertised discount fraction from dim_promotion.discount_pct. |
| `total_revenue` | DECIMAL(19,4) | SUM(sales_amount). Net revenue after discount. Reconciles to fact total. |
| `total_discount_given` | DECIMAL(19,4) | SUM(discount_amount). Total monetary discount applied across all lines. |
| `total_gross_before_discount` | DECIMAL(19,4) | SUM(extended_amount). Revenue before any discount. |
| `avg_discount_pct` | DECIMAL(7,4) | AVG(unit_price_discount_pct) across all fact lines for this promotion. |
| `total_orders` | INTEGER | COUNT DISTINCT sales_order_number. Distinct orders using this promotion. |
| `total_line_items` | INTEGER | COUNT of all fact rows for this promotion. |
| `total_units_sold` | INTEGER | SUM(order_quantity). Total units sold under this promotion. |
| `avg_order_value` | DECIMAL(19,4) | total_revenue / total_orders. Average revenue per order. |
| `first_used_date` | TIMESTAMP | MIN(order_date). Earliest date this promotion appeared on a transaction. |
| `last_used_date` | TIMESTAMP | MAX(order_date). Most recent date this promotion appeared on a transaction. |
| `discount_depth_tier` | VARCHAR | 'No Discount' / 'Low' / 'Medium' / 'High' derived from avg_discount_pct. |

---

## 7. Non-Functional Requirements

| NFR | Requirement |
|-----|-------------|
| NFR-01 | Materialized as `table` (full refresh) |
| NFR-02 | Must run in < 30 seconds on DuckDB dev environment |
| NFR-03 | All columns documented in companion YAML |
| NFR-04 | `not_null` tests on all key and measure columns |
| NFR-05 | `accepted_values` test on `discount_depth_tier` |
| NFR-06 | `unique` test on `promotion_key` |
