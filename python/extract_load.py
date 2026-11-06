import pandas as pd
from google.cloud import bigquery
import os

# BigQuery ayarları
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "./credentials.json"
PROJECT_ID = "instacart-analytics-512220"
DATASET_ID = "raw_instacart"
DATA_PATH = "./data/raw"

# BigQuery client
client = bigquery.Client(project=PROJECT_ID)

# Yüklenecek dosyalar
csv_files = [
    "aisles.csv",
    "departments.csv",
    "products.csv",
    "orders.csv",
    "order_products__prior.csv",
    "order_products__train.csv"
]

def upload_csv_to_bigquery(file_name):
    table_name = file_name.replace(".csv", "").replace("__", "_")
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    file_path = os.path.join(DATA_PATH, file_name)

    print(f"Yukleniyor: {file_name} -> {table_id}")

    df = pd.read_csv(file_path)

    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()

    print(f"Tamamlandi: {table_name} ({len(df)} satir)")

# Tüm dosyaları yükle
for csv_file in csv_files:
    upload_csv_to_bigquery(csv_file)

print("Tum dosyalar basariyla yuklendi!")