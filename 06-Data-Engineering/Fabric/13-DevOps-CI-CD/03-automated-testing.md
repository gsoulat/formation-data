# Automated Testing in Microsoft Fabric

## Introduction

Les tests automatisés sont essentiels pour garantir la qualité et la fiabilité des solutions Fabric. L'automatisation des tests permet de détecter les régressions tôt, de valider les transformations de données et d'assurer que les rapports et modèles sémantiques fonctionnent correctement après chaque modification.

## Types de Tests

### 1. Tests Unitaires (Data Transformation)

```python
# tests/test_transformations.py
import pytest
import pandas as pd
from pyspark.sql import SparkSession
from transformations.sales_etl import transform_sales_data

class TestSalesTransformations:

    @pytest.fixture(scope="class")
    def spark(self):
        return SparkSession.builder.appName("TestSales").getOrCreate()

    @pytest.fixture
    def sample_sales_data(self, spark):
        """Données de test"""
        data = [
            ("2024-01-15", "P001", 100.0, 2, "USD"),
            ("2024-01-15", "P002", 50.0, 5, "EUR"),
            ("2024-01-16", "P001", 100.0, 3, "USD"),
            (None, "P003", 75.0, 1, "USD"),  # Date manquante
            ("2024-01-17", "P004", -10.0, 1, "USD"),  # Montant négatif
        ]
        columns = ["sale_date", "product_id", "unit_price", "quantity", "currency"]
        return spark.createDataFrame(data, columns)

    def test_transform_calculates_total_correctly(self, spark, sample_sales_data):
        """Test: Le total est calculé correctement"""
        result = transform_sales_data(sample_sales_data)
        total_amounts = result.select("total_amount").collect()

        assert total_amounts[0][0] == 200.0  # 100 * 2
        assert total_amounts[1][0] == 250.0  # 50 * 5
        assert total_amounts[2][0] == 300.0  # 100 * 3

    def test_transform_handles_null_dates(self, spark, sample_sales_data):
        """Test: Les dates nulles sont gérées"""
        result = transform_sales_data(sample_sales_data)
        null_dates = result.filter(result.sale_date.isNull()).count()

        # Doit soit filtrer soit remplacer par défaut
        assert null_dates == 0

    def test_transform_rejects_negative_amounts(self, spark, sample_sales_data):
        """Test: Les montants négatifs sont rejetés"""
        result = transform_sales_data(sample_sales_data)
        negative_amounts = result.filter(result.total_amount < 0).count()

        assert negative_amounts == 0

    def test_currency_conversion(self, spark, sample_sales_data):
        """Test: Conversion des devises"""
        result = transform_sales_data(sample_sales_data)

        # Vérifier que toutes les devises sont converties en USD
        currencies = result.select("currency").distinct().collect()
        assert len(currencies) == 1
        assert currencies[0][0] == "USD"
```

### 2. Tests d'Intégration (Data Quality)

```python
# tests/test_data_quality.py
import pytest
from datetime import datetime, timedelta

class TestDataQuality:

    def test_no_duplicates_in_fact_table(self, warehouse_connection):
        """Test: Pas de doublons dans la table de faits"""
        query = """
        SELECT sale_id, COUNT(*) as cnt
        FROM gold.fact_sales
        GROUP BY sale_id
        HAVING COUNT(*) > 1
        """
        duplicates = warehouse_connection.execute(query).fetchall()

        assert len(duplicates) == 0, f"Found {len(duplicates)} duplicate sales"

    def test_referential_integrity(self, warehouse_connection):
        """Test: Intégrité référentielle"""
        query = """
        SELECT COUNT(*) as orphan_count
        FROM gold.fact_sales f
        LEFT JOIN gold.dim_product p ON f.product_key = p.product_key
        WHERE p.product_key IS NULL
        """
        result = warehouse_connection.execute(query).fetchone()

        assert result[0] == 0, f"Found {result[0]} orphan records"

    def test_date_range_validity(self, warehouse_connection):
        """Test: Dates dans une plage valide"""
        min_date = datetime(2020, 1, 1)
        max_date = datetime.now() + timedelta(days=1)

        query = f"""
        SELECT COUNT(*) as invalid_dates
        FROM gold.fact_sales
        WHERE sale_date < '{min_date.strftime('%Y-%m-%d')}'
           OR sale_date > '{max_date.strftime('%Y-%m-%d')}'
        """
        result = warehouse_connection.execute(query).fetchone()

        assert result[0] == 0, f"Found {result[0]} records with invalid dates"

    def test_non_negative_amounts(self, warehouse_connection):
        """Test: Montants non négatifs"""
        query = """
        SELECT COUNT(*) as negative_amounts
        FROM gold.fact_sales
        WHERE total_amount < 0
        """
        result = warehouse_connection.execute(query).fetchone()

        assert result[0] == 0, f"Found {result[0]} negative amounts"

    def test_completeness(self, warehouse_connection):
        """Test: Complétude des données obligatoires"""
        required_columns = ["sale_id", "product_key", "customer_key", "sale_date", "total_amount"]

        for column in required_columns:
            query = f"""
            SELECT COUNT(*) as null_count
            FROM gold.fact_sales
            WHERE {column} IS NULL
            """
            result = warehouse_connection.execute(query).fetchone()
            assert result[0] == 0, f"Found {result[0]} NULL values in {column}"
```

### 3. Tests de Régression (DAX/Reports)

```python
# tests/test_semantic_model.py
import requests

class TestSemanticModel:

    def __init__(self, workspace_id, dataset_id, access_token):
        self.workspace_id = workspace_id
        self.dataset_id = dataset_id
        self.headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }

    def execute_dax_query(self, dax_query):
        """Exécute une requête DAX"""
        url = f"https://api.powerbi.com/v1.0/myorg/groups/{self.workspace_id}/datasets/{self.dataset_id}/executeQueries"

        payload = {
            "queries": [{"query": dax_query}],
            "serializerSettings": {"includeNulls": True}
        }

        response = requests.post(url, headers=self.headers, json=payload)
        return response.json()['results'][0]['tables'][0]['rows']

    def test_total_revenue_measure(self):
        """Test: Mesure Total Revenue"""
        query = """
        EVALUATE
        ROW(
            "Total Revenue", [Total Revenue],
            "Expected", 1000000
        )
        """
        result = self.execute_dax_query(query)

        # Vérifier que la mesure retourne une valeur positive
        assert result[0]['[Total Revenue]'] > 0

    def test_year_over_year_growth(self):
        """Test: Calcul YoY correct"""
        query = """
        EVALUATE
        SUMMARIZECOLUMNS(
            'Date'[Year],
            "YoY Growth", [YoY Growth %]
        )
        """
        result = self.execute_dax_query(query)

        # Vérifier que le YoY est calculé pour chaque année
        for row in result:
            if row["Date[Year]"] > 2020:
                assert row["[YoY Growth %]"] is not None

    def test_measure_performance(self):
        """Test: Performance des mesures complexes"""
        import time

        complex_query = """
        EVALUATE
        TOPN(
            100,
            SUMMARIZECOLUMNS(
                'Product'[Category],
                'Geography'[Region],
                'Date'[Year],
                "Revenue", [Total Revenue],
                "Profit", [Total Profit],
                "Margin %", [Profit Margin %]
            )
        )
        """

        start_time = time.time()
        self.execute_dax_query(complex_query)
        execution_time = time.time() - start_time

        # La requête doit s'exécuter en moins de 5 secondes
        assert execution_time < 5, f"Query took {execution_time:.2f}s (max 5s)"
```

## Framework de Test CI/CD

### Structure du Projet

```
fabric-project/
├── src/
│   ├── notebooks/
│   ├── pipelines/
│   └── transformations/
├── tests/
│   ├── unit/
│   │   └── test_transformations.py
│   ├── integration/
│   │   └── test_data_quality.py
│   ├── regression/
│   │   └── test_semantic_model.py
│   └── conftest.py
├── .github/
│   └── workflows/
│       └── test.yml
├── pytest.ini
└── requirements-test.txt
```

### Configuration Pytest

```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short --junitxml=test-results.xml
markers =
    unit: Unit tests (fast)
    integration: Integration tests (require connection)
    regression: Regression tests (full system)
    slow: Slow tests
```

### Pipeline de Tests

```yaml
# .github/workflows/test.yml
name: Fabric Tests

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install -r requirements-test.txt

      - name: Run unit tests
        run: |
          pytest tests/unit -m unit --junitxml=unit-results.xml

      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: unit-test-results
          path: unit-results.xml

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    environment: test
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install -r requirements-test.txt

      - name: Run integration tests
        env:
          FABRIC_CONNECTION_STRING: ${{ secrets.TEST_CONNECTION_STRING }}
        run: |
          pytest tests/integration -m integration --junitxml=integration-results.xml

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: integration-test-results
          path: integration-results.xml

  regression-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    environment: test
    steps:
      - uses: actions/checkout@v3

      - name: Run regression tests
        run: |
          pytest tests/regression -m regression --junitxml=regression-results.xml

      - name: Publish Test Report
        uses: mikepenz/action-junit-report@v3
        if: always()
        with:
          report_paths: '*-results.xml'
```

## Validation des Pipelines

```python
# tests/test_pipeline_validation.py
class TestPipelineExecution:

    def test_pipeline_runs_successfully(self, fabric_client, pipeline_id):
        """Test: Le pipeline s'exécute sans erreur"""
        # Déclencher le pipeline
        run_id = fabric_client.trigger_pipeline(pipeline_id)

        # Attendre la fin
        status = fabric_client.wait_for_pipeline(run_id, timeout=3600)

        assert status == "Succeeded", f"Pipeline failed with status: {status}"

    def test_pipeline_output_schema(self, fabric_client, pipeline_id):
        """Test: Le schéma de sortie est correct"""
        expected_columns = [
            "sale_id", "product_key", "customer_key",
            "sale_date", "quantity", "unit_price", "total_amount"
        ]

        actual_schema = fabric_client.get_table_schema("gold.fact_sales")
        actual_columns = [col['name'] for col in actual_schema]

        for expected_col in expected_columns:
            assert expected_col in actual_columns, f"Missing column: {expected_col}"

    def test_pipeline_idempotency(self, fabric_client, pipeline_id):
        """Test: Le pipeline est idempotent"""
        # Exécuter deux fois
        fabric_client.trigger_pipeline(pipeline_id)
        count_after_first = fabric_client.get_row_count("gold.fact_sales")

        fabric_client.trigger_pipeline(pipeline_id)
        count_after_second = fabric_client.get_row_count("gold.fact_sales")

        # Le nombre de lignes ne doit pas doubler
        assert count_after_second == count_after_first, "Pipeline is not idempotent"
```

## Points Clés

- Implémenter des tests à plusieurs niveaux : unitaire, intégration, régression
- Automatiser l'exécution des tests dans les pipelines CI/CD
- Tester les transformations de données avec des jeux de données contrôlés
- Valider la qualité des données (doublons, nulls, intégrité référentielle)
- Tester les mesures DAX pour éviter les régressions
- Monitorer les performances des requêtes
- Utiliser des environnements de test dédiés
- Documenter les cas de test et maintenir la couverture

---

**Navigation** : [Précédent : Deployment Pipelines](./02-deployment-pipelines.md) | [Index](../README.md) | [Suivant : Infrastructure as Code](./04-infrastructure-as-code.md)
