# Instacart Grocery Order Analytics

An end-to-end ELT pipeline built with Python, BigQuery and dbt, analysing 3.4 million grocery orders from the [Instacart Market Basket Analysis](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis) dataset.

## Architecture

```text
Raw CSV Files (Kaggle)
        │
        ▼
Python (extract_load.py)
        │
        ▼
BigQuery — raw_instacart dataset
        │
        ▼
dbt Staging Layer (views)
        │
        ▼
dbt Intermediate Layer (views)
        │
        ▼
dbt Marts Layer (tables)
        │
        ▼
dbt Semantic Layer (MetricFlow)
```
<img width="2670" height="1240" alt="image" src="https://github.com/user-attachments/assets/4888c213-42c3-4d12-82e5-9361661ffa46" />

## Dataset

| Table | Rows |
|---|---|
| orders | 3,421,083 |
| order_products_prior | 32,434,489 |
| order_products_train | 1,384,617 |
| products | 49,688 |
| aisles | 134 |
| departments | 21 |

## Project Structure

```text
instacart-analytics/
├── python/
│   └── extract_load.py
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── .github/
│   └── workflows/
│       └── dbt_ci.yml
└── dbt_project.yml
```

## Models

### Staging
| Model | Description |
|---|---|
| stg_orders | Cleaned orders with renamed columns |
| stg_products | Cleaned product catalogue |
| stg_aisles | Aisle reference data |
| stg_departments | Department reference data |
| stg_order_products | Combined prior and train order items |

### Intermediate
| Model | Description |
|---|---|
| int_orders_enriched | Orders with basket size, reorder counts and first-order flag |
| int_order_products_enriched | Order items joined with product, aisle and department |

### Marts
| Model | Description |
|---|---|
| mart_orders | Final orders table with reorder rate per order |
| mart_products | Product performance — total orders, reorder rate, avg cart position |
| mart_customers | Customer segmentation — one_time, occasional, regular, loyal |

## Tests

- **39 tests** across 14 models (staging, marts, Kimball layer), plus 3 semantic layer metrics
- Test types: `unique`, `not_null`, `accepted_values` (with `quote: false` for integer columns in BigQuery)
- 37 pass, 2 warn. The warnings document NULL `basket_size` for orders that exist in `orders` but not in the `order_products` tables, a known characteristic of the Instacart dataset

## Semantic Layer

Three metrics defined using dbt MetricFlow:

| Metric | Value |
|---|---|
| order_count | 3,421,083 |
| avg_basket_size | 10.1 items |
| avg_reorder_rate | 59.9% |

Query metrics without writing SQL:
```bash
dbt sl query --metrics order_count
dbt sl query --metrics avg_basket_size
dbt sl query --metrics avg_reorder_rate
```
> Note: the dataset has no real order date. `mart_orders.order_date` is a synthetic placeholder (2023-01-01 + `order_number` days) that MetricFlow requires as a time dimension, so metrics should not be interpreted over time.
> 
## CI/CD

GitHub Actions runs `dbt build` on every pull request to main, ensuring all models and tests pass before merging.

## Business Questions & Findings

### Which departments have the highest reorder rates?
Average of product-level reorder rates per department (simple average, not weighted by order volume).

| Department | Products | Avg. Reorder Rate |
|---|---|---|
| dairy eggs | 3,449 | 50.7% |
| pets | 972 | 49.5% |
| bakery | 1,516 | 47.4% |
| beverages | 4,364 | 47.3% |
| breakfast | 1,114 | 46.9% |

### How are customers segmented by order frequency?

| Segment | Customers | Share |
|---|---|---|
| loyal (11+ orders) | 101,696 | 49.3% |
| regular (6–10 orders) | 60,937 | 29.6% |
| occasional (2–5 orders) | 43,576 | 21.1% |

No customer falls into the one_time segment. The dataset likely only includes customers with several prior orders, so the loyal share should not be read as overall platform retention.

### Which days have the most orders?
The dataset gives day-of-week as an index (0–6) without naming the days. Day 0 (600,905) and day 1 (587,478) together account for 34.7% of all orders; day 4 is the lowest (426,339).

## Design Decisions

### Why staging as views, marts as tables?
Staging models are materialised as **views** because they are lightweight transformations 
(renaming columns, casting types) with no aggregation. Views add no storage cost and always 
reflect the latest source data.

Mart models are materialised as **tables** because they involve heavy joins and aggregations 
across 33M+ rows. Materialising as tables means downstream queries (BI tools, semantic layer) 
hit pre-computed results rather than re-running expensive transformations on every query.

### Why combine prior and train order sets in staging?
The Instacart dataset splits order history into `order_products__prior` and 
`order_products__train` for ML purposes. For analytical use cases, this split is irrelevant — 
we need the full order history. Combining them in `stg_order_products` with an `order_set` 
column preserves the origin while enabling unified analysis downstream.

### Why document NULL basket_size as a warning rather than filtering?
75,000 orders (~2.2%) have NULL basket_size because they appear in the `orders` table but 
not in the `order_products` tables — a known characteristic of the Instacart dataset split. 
Filtering them out would silently remove valid order records. Instead, we document the issue 
as a dbt test warning so downstream consumers are aware of the limitation.

### Why use customer segments instead of raw order counts?
Raw order counts are hard to act on. Segments (one_time, occasional, regular, loyal) map 
directly to business decisions — retention campaigns target occasional customers, loyalty 
programmes reward loyal ones. Segmentation logic lives in the mart layer so definitions 
are consistent across all consumers.

## Tech Stack

- **Python** — data extraction and loading (Kaggle API, pandas, google-cloud-bigquery)
- **BigQuery** — cloud data warehouse
- **dbt Cloud** — data transformation, testing and documentation
- **MetricFlow** — semantic layer and metric definitions
- **GitHub Actions** — CI/CD pipeline

## Setup

### Prerequisites
- Python 3.9+
- Google Cloud account with BigQuery enabled
- dbt Cloud account (free Developer plan)
- Kaggle account

### 1. Clone the repository
```bash
git clone https://github.com/serdarsahbudak/instacart-analytics.git
cd instacart-analytics
```

### 2. Set up Python environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install kaggle google-cloud-bigquery pandas pyarrow
```

### 3. Configure Kaggle API
```bash
mkdir -p ~/.kaggle
echo '{"username":"YOUR_KAGGLE_USERNAME","key":"YOUR_KAGGLE_KEY"}' > ~/.kaggle/kaggle.json
chmod 600 ~/.kaggle/kaggle.json
```

### 4. Configure Google Cloud credentials
Create a service account in Google Cloud Console with BigQuery Admin role,
download the JSON key and set the environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/credentials.json"
```

### 5. Download and load data
```bash
kaggle datasets download -d psparks/instacart-market-basket-analysis --unzip -p ./data/raw
python3 python/extract_load.py
```

### 6. Run dbt
Connect dbt Cloud to your BigQuery project and GitHub repository, then:
```bash
dbt build          # run all models and tests
dbt sl list metrics  # verify semantic layer
dbt sl query --metrics order_count  # query a metric
```

### CI/CD
GitHub Actions automatically runs `dbt build` on every pull request to main.
Add your BigQuery service account JSON as a repository secret named `BIGQUERY_CREDENTIALS`.
