import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "./credentials.json"
import anthropic
import json
from google.cloud import bigquery

client = anthropic.Anthropic()
bq_client = bigquery.Client(project="instacart-analytics-512220")

METRICS_INFO = """
Available metrics and their SQL:
- order_count: SELECT COUNT(*) as order_count FROM `instacart-analytics-512220.dbt_ssahbudak.mart_orders`
- avg_basket_size: SELECT ROUND(AVG(basket_size), 2) as avg_basket_size FROM `instacart-analytics-512220.dbt_ssahbudak.mart_orders`
- avg_reorder_rate: SELECT ROUND(AVG(reorder_rate_pct), 2) as avg_reorder_rate FROM `instacart-analytics-512220.dbt_ssahbudak.mart_orders`
- reorder_rate_by_department: SELECT department, ROUND(AVG(reorder_rate_pct), 1) as avg_reorder_rate FROM `instacart-analytics-512220.dbt_ssahbudak.mart_products` GROUP BY department ORDER BY avg_reorder_rate DESC LIMIT 5
- customer_segments: SELECT customer_segment, COUNT(*) as customer_count FROM `instacart-analytics-512220.dbt_ssahbudak.mart_customers` GROUP BY customer_segment ORDER BY customer_count DESC
- orders_by_day: SELECT order_day_of_week, COUNT(*) as order_count FROM `instacart-analytics-512220.dbt_ssahbudak.mart_orders` GROUP BY order_day_of_week ORDER BY order_count DESC
"""

def run_bigquery(sql: str) -> str:
    query_job = bq_client.query(sql)
    rows = query_job.result()
    result = []
    for row in rows:
        result.append(dict(row))
    return json.dumps(result, indent=2)

def answer_question(user_question: str) -> str:
    # Step 1: Ask Claude which SQL to run
    planning_response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=500,
        messages=[{
            "role": "user",
            "content": f"""You are a data analyst assistant. Given a business question,
choose the most appropriate SQL query from the list below.

{METRICS_INFO}

Business question: {user_question}

Respond in JSON format only, no markdown backticks:
{{"sql": "the_sql_query", "explanation": "brief explanation"}}

Only use SQL queries from the list above exactly as written."""
        }]
    )

    raw_text = planning_response.content[0].text
    clean_text = raw_text.replace("```json", "").replace("```", "").strip()
    plan = json.loads(clean_text)

    print(f"\nRunning query for: {plan['explanation']}")

    # Step 2: Run BigQuery
    raw_result = run_bigquery(plan['sql'])

    # Step 3: Ask Claude to interpret
    final_response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=300,
        messages=[{
            "role": "user",
            "content": f"""Business question: {user_question}

Data result:
{raw_result}

Note: order_day_of_week is a numeric index (0-6). The dataset does not say which weekday is 0, so refer to days only by number (e.g. "day 0") and never name weekdays.

Answer the business question in 2-3 clear sentences using the data. Be specific with numbers."""
        }]
    )

    return final_response.content[0].text

# Demo questions
questions = [
    "How many total orders are in the dataset?",
    "Which departments have the highest reorder rates?",
    "What is the distribution of customer segments?",
    "Which days of the week have the most orders?",
    "What is the average basket size?"
]

print("=== Instacart Analytics LLM Demo ===\n")

for question in questions:
    print(f"Q: {question}")
    answer = answer_question(question)
    print(f"A: {answer}")
    print("-" * 50)