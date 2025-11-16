#!/usr/bin/env python3
"""
Script de génération de tous les datasets pour les projets Fabric
================================================================

Ce script génère des données réalistes pour tous les projets du cours.
Les fichiers sont créés dans le dossier courant.

Usage:
    python generate_all_datasets.py

Datasets générés:
    - retail_sales.csv (Projet 1 & 3)
    - customers.csv (Projet 1 & 3)
    - products.csv (Projet 1 & 3)
    - iot_telemetry.json (Projet 2)
    - customer_churn.csv (Projet 4)
    - web_logs.json (Projet 5)
"""

import csv
import json
import random
from datetime import datetime, timedelta
import os

# Set seed for reproducibility
random.seed(42)

def generate_retail_sales(num_records=100000):
    """Génère des données de ventes retail pour Projet 1 & 3"""
    print(f"Generating {num_records} retail sales records...")

    # Reference data
    categories = {
        "Electronics": ["Laptop", "Smartphone", "Tablet", "Headphones", "Camera", "TV", "Speaker"],
        "Clothing": ["T-Shirt", "Jeans", "Jacket", "Dress", "Shoes", "Hat", "Sweater"],
        "Home & Garden": ["Chair", "Table", "Lamp", "Rug", "Plant", "Curtains", "Pillow"],
        "Sports": ["Basketball", "Tennis Racket", "Yoga Mat", "Dumbbells", "Bike", "Running Shoes"],
        "Books": ["Fiction", "Non-Fiction", "Technical", "Children", "Comics", "Educational"]
    }

    regions = ["North America", "Europe", "Asia Pacific", "Latin America", "Middle East"]
    countries = {
        "North America": ["USA", "Canada", "Mexico"],
        "Europe": ["France", "Germany", "UK", "Spain", "Italy"],
        "Asia Pacific": ["Japan", "China", "Australia", "India", "Singapore"],
        "Latin America": ["Brazil", "Argentina", "Chile"],
        "Middle East": ["UAE", "Saudi Arabia", "Israel"]
    }

    channels = ["Online", "Store", "Mobile App", "Marketplace"]

    # Generate sales
    sales = []
    start_date = datetime(2022, 1, 1)
    end_date = datetime(2024, 12, 31)
    date_range = (end_date - start_date).days

    for i in range(num_records):
        # Random date with seasonal patterns
        day_offset = random.randint(0, date_range)
        sale_date = start_date + timedelta(days=day_offset)

        # Category and product
        category = random.choice(list(categories.keys()))
        product = random.choice(categories[category])

        # Pricing with category-based logic
        base_prices = {
            "Electronics": (50, 2000),
            "Clothing": (10, 200),
            "Home & Garden": (20, 500),
            "Sports": (15, 300),
            "Books": (5, 50)
        }
        min_price, max_price = base_prices[category]
        unit_price = round(random.uniform(min_price, max_price), 2)

        # Quantity (inversely related to price)
        if unit_price > 500:
            quantity = random.randint(1, 2)
        elif unit_price > 100:
            quantity = random.randint(1, 3)
        else:
            quantity = random.randint(1, 10)

        # Discount (seasonal and channel based)
        month = sale_date.month
        if month in [11, 12]:  # Holiday season
            discount = random.choice([0, 0.1, 0.15, 0.2, 0.25, 0.3])
        elif month in [1, 7]:  # Sales periods
            discount = random.choice([0, 0.1, 0.2, 0.3, 0.4])
        else:
            discount = random.choice([0, 0, 0, 0.05, 0.1])

        # Location
        region = random.choice(regions)
        country = random.choice(countries[region])

        # Calculate totals
        gross_amount = unit_price * quantity
        discount_amount = gross_amount * discount
        net_amount = gross_amount - discount_amount
        cost = unit_price * 0.6 * quantity  # 60% cost
        profit = net_amount - cost

        sales.append({
            "transaction_id": f"TXN{i+1:08d}",
            "date": sale_date.strftime("%Y-%m-%d"),
            "time": f"{random.randint(8, 22):02d}:{random.randint(0, 59):02d}:{random.randint(0, 59):02d}",
            "customer_id": f"CUST{random.randint(1, 10000):06d}",
            "product_id": f"PROD{random.randint(1, 500):05d}",
            "product_name": product,
            "category": category,
            "quantity": quantity,
            "unit_price": unit_price,
            "discount_percent": discount,
            "gross_amount": round(gross_amount, 2),
            "discount_amount": round(discount_amount, 2),
            "net_amount": round(net_amount, 2),
            "cost": round(cost, 2),
            "profit": round(profit, 2),
            "region": region,
            "country": country,
            "channel": random.choice(channels),
            "payment_method": random.choice(["Credit Card", "Debit Card", "PayPal", "Bank Transfer", "Cash"])
        })

    # Write to CSV
    with open("retail_sales.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=sales[0].keys())
        writer.writeheader()
        writer.writerows(sales)

    print(f"  ✓ Created retail_sales.csv ({num_records} records)")
    return sales


def generate_customers(num_customers=10000):
    """Génère des données clients pour Projet 1, 3 & 4"""
    print(f"Generating {num_customers} customer records...")

    first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
                   "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
                   "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa"]

    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
                  "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
                  "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White"]

    segments = ["Premium", "Standard", "Basic", "Enterprise"]
    industries = ["Technology", "Finance", "Healthcare", "Retail", "Manufacturing", "Education", "Government"]

    customers = []

    for i in range(num_customers):
        first_name = random.choice(first_names)
        last_name = random.choice(last_names)
        email = f"{first_name.lower()}.{last_name.lower()}{i}@email.com"

        # Registration date
        reg_date = datetime(2020, 1, 1) + timedelta(days=random.randint(0, 1825))

        # Last activity (after registration)
        days_since_reg = (datetime.now() - reg_date).days
        last_activity = reg_date + timedelta(days=random.randint(0, min(days_since_reg, 365)))

        # Churn indicators
        days_since_activity = (datetime.now() - last_activity).days
        is_churned = days_since_activity > 180  # Churned if no activity in 6 months

        customers.append({
            "customer_id": f"CUST{i+1:06d}",
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "phone": f"+1-{random.randint(200, 999)}-{random.randint(100, 999)}-{random.randint(1000, 9999)}",
            "segment": random.choice(segments),
            "industry": random.choice(industries),
            "company_size": random.choice(["1-10", "11-50", "51-200", "201-1000", "1000+"]),
            "registration_date": reg_date.strftime("%Y-%m-%d"),
            "last_activity_date": last_activity.strftime("%Y-%m-%d"),
            "total_purchases": random.randint(1, 200),
            "total_spend": round(random.uniform(100, 50000), 2),
            "avg_order_value": round(random.uniform(50, 500), 2),
            "lifetime_value": round(random.uniform(500, 100000), 2),
            "satisfaction_score": round(random.uniform(1, 5), 1),
            "support_tickets": random.randint(0, 20),
            "is_churned": is_churned,
            "churn_risk_score": round(random.uniform(0, 1), 3)
        })

    with open("customers.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=customers[0].keys())
        writer.writeheader()
        writer.writerows(customers)

    print(f"  ✓ Created customers.csv ({num_customers} records)")
    return customers


def generate_products(num_products=500):
    """Génère un catalogue produits"""
    print(f"Generating {num_products} product records...")

    categories = {
        "Electronics": {
            "subcategories": ["Computers", "Mobile", "Audio", "Video", "Accessories"],
            "brands": ["TechCorp", "ElectroPro", "GadgetMax", "DigiWorld", "SmartTech"]
        },
        "Clothing": {
            "subcategories": ["Men", "Women", "Kids", "Sports", "Accessories"],
            "brands": ["FashionPlus", "StyleHub", "TrendyWear", "ComfortFit", "UrbanStyle"]
        },
        "Home & Garden": {
            "subcategories": ["Furniture", "Decor", "Kitchen", "Garden", "Storage"],
            "brands": ["HomeEssentials", "CozyLiving", "GardenPro", "ModernHome", "NaturalStyle"]
        }
    }

    products = []

    for i in range(num_products):
        category = random.choice(list(categories.keys()))
        cat_data = categories[category]
        subcategory = random.choice(cat_data["subcategories"])
        brand = random.choice(cat_data["brands"])

        base_cost = random.uniform(10, 500)
        margin = random.uniform(0.3, 0.8)
        price = base_cost * (1 + margin)

        products.append({
            "product_id": f"PROD{i+1:05d}",
            "product_name": f"{brand} {subcategory} Product {i+1}",
            "category": category,
            "subcategory": subcategory,
            "brand": brand,
            "unit_cost": round(base_cost, 2),
            "unit_price": round(price, 2),
            "margin_percent": round(margin * 100, 1),
            "weight_kg": round(random.uniform(0.1, 50), 2),
            "stock_quantity": random.randint(0, 1000),
            "reorder_level": random.randint(10, 100),
            "supplier_id": f"SUP{random.randint(1, 50):03d}",
            "is_active": random.choice([True, True, True, False]),  # 75% active
            "launch_date": (datetime(2020, 1, 1) + timedelta(days=random.randint(0, 1825))).strftime("%Y-%m-%d")
        })

    with open("products.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=products[0].keys())
        writer.writeheader()
        writer.writerows(products)

    print(f"  ✓ Created products.csv ({num_products} records)")
    return products


def generate_iot_telemetry(num_records=10000):
    """Génère des données IoT pour Projet 2"""
    print(f"Generating {num_records} IoT telemetry records...")

    devices = []
    # Temperature sensors
    for i in range(50):
        devices.append({
            "id": f"TEMP_{i+1:03d}",
            "type": "temperature",
            "location": f"Machine_{(i//5)+1}",
            "zone": f"Production_{(i//10)+1}",
            "normal": 45,
            "unit": "celsius"
        })

    # Humidity sensors
    for i in range(30):
        devices.append({
            "id": f"HUM_{i+1:03d}",
            "type": "humidity",
            "location": f"Storage_{(i//6)+1}",
            "zone": f"Storage_{(i//10)+1}",
            "normal": 55,
            "unit": "percent"
        })

    # Pressure sensors
    for i in range(20):
        devices.append({
            "id": f"PRESS_{i+1:03d}",
            "type": "pressure",
            "location": f"System_{(i//4)+1}",
            "zone": f"Production_{(i//5)+1}",
            "normal": 100,
            "unit": "bar"
        })

    telemetry = []
    base_time = datetime.utcnow() - timedelta(hours=24)

    for i in range(num_records):
        device = random.choice(devices)
        timestamp = base_time + timedelta(seconds=i * (86400 / num_records))

        # Generate value with noise
        noise = random.gauss(0, 2)
        value = device["normal"] + noise

        # Occasionally add anomalies (5%)
        if random.random() < 0.05:
            value += random.uniform(10, 25)

        telemetry.append({
            "device_id": device["id"],
            "device_type": device["type"],
            "location": device["location"],
            "zone": device["zone"],
            "value": round(value, 2),
            "unit": device["unit"],
            "timestamp": timestamp.isoformat() + "Z",
            "quality": "good" if abs(value - device["normal"]) < 10 else "warning"
        })

    with open("iot_telemetry.json", "w", encoding="utf-8") as f:
        for record in telemetry:
            f.write(json.dumps(record) + "\n")

    print(f"  ✓ Created iot_telemetry.json ({num_records} records)")
    return telemetry


def generate_customer_churn_data(num_customers=5000):
    """Génère des données de churn pour Projet 4 (ML)"""
    print(f"Generating {num_customers} customer churn records...")

    churn_data = []

    for i in range(num_customers):
        # Features
        tenure = random.randint(1, 72)  # months
        monthly_charges = round(random.uniform(20, 200), 2)
        total_charges = round(monthly_charges * tenure * random.uniform(0.8, 1.2), 2)

        contract_type = random.choice(["Month-to-month", "One year", "Two year"])
        payment_method = random.choice(["Electronic check", "Mailed check", "Bank transfer", "Credit card"])
        internet_service = random.choice(["DSL", "Fiber optic", "No"])
        online_security = random.choice(["Yes", "No", "No internet service"])
        tech_support = random.choice(["Yes", "No", "No internet service"])

        # Calculate churn probability based on features
        churn_prob = 0.1  # base probability

        if contract_type == "Month-to-month":
            churn_prob += 0.3
        elif contract_type == "One year":
            churn_prob += 0.1

        if payment_method == "Electronic check":
            churn_prob += 0.15

        if tenure < 12:
            churn_prob += 0.2
        elif tenure > 48:
            churn_prob -= 0.1

        if monthly_charges > 100:
            churn_prob += 0.1

        if online_security == "No" and internet_service != "No":
            churn_prob += 0.1

        if tech_support == "No" and internet_service != "No":
            churn_prob += 0.1

        # Add some randomness
        churn_prob = min(max(churn_prob + random.gauss(0, 0.1), 0), 1)
        is_churned = random.random() < churn_prob

        churn_data.append({
            "customer_id": f"CHURN{i+1:05d}",
            "gender": random.choice(["Male", "Female"]),
            "senior_citizen": random.choice([0, 0, 0, 1]),  # 25% seniors
            "partner": random.choice(["Yes", "No"]),
            "dependents": random.choice(["Yes", "No"]),
            "tenure_months": tenure,
            "phone_service": random.choice(["Yes", "No"]),
            "multiple_lines": random.choice(["Yes", "No", "No phone service"]),
            "internet_service": internet_service,
            "online_security": online_security,
            "online_backup": random.choice(["Yes", "No", "No internet service"]),
            "device_protection": random.choice(["Yes", "No", "No internet service"]),
            "tech_support": tech_support,
            "streaming_tv": random.choice(["Yes", "No", "No internet service"]),
            "streaming_movies": random.choice(["Yes", "No", "No internet service"]),
            "contract": contract_type,
            "paperless_billing": random.choice(["Yes", "No"]),
            "payment_method": payment_method,
            "monthly_charges": monthly_charges,
            "total_charges": total_charges,
            "num_admin_tickets": random.randint(0, 10),
            "num_tech_tickets": random.randint(0, 15),
            "churn": "Yes" if is_churned else "No"
        })

    with open("customer_churn.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=churn_data[0].keys())
        writer.writeheader()
        writer.writerows(churn_data)

    print(f"  ✓ Created customer_churn.csv ({num_customers} records)")

    # Print churn statistics
    churned = sum(1 for c in churn_data if c["churn"] == "Yes")
    print(f"    Churn rate: {churned/num_customers*100:.1f}%")

    return churn_data


def generate_web_logs(num_records=50000):
    """Génère des logs web pour Projet 5 (Security)"""
    print(f"Generating {num_records} web log records...")

    user_agents = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15",
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36"
    ]

    endpoints = [
        "/api/data", "/api/users", "/api/reports", "/api/export",
        "/dashboard", "/settings", "/profile", "/admin", "/login"
    ]

    methods = ["GET", "POST", "PUT", "DELETE"]
    status_codes = [200, 200, 200, 200, 201, 400, 401, 403, 404, 500]

    logs = []
    base_time = datetime.utcnow() - timedelta(days=30)

    for i in range(num_records):
        timestamp = base_time + timedelta(seconds=random.randint(0, 30*86400))

        # Simulate some suspicious patterns
        is_suspicious = random.random() < 0.02  # 2% suspicious

        if is_suspicious:
            # Simulate attack patterns
            user_id = f"attacker_{random.randint(1, 10)}"
            endpoint = random.choice(["/admin", "/api/export", "/api/users"])
            method = random.choice(["POST", "DELETE"])
            status = random.choice([401, 403, 403, 500])
            response_time = random.randint(1000, 5000)
        else:
            user_id = f"user_{random.randint(1, 1000):04d}"
            endpoint = random.choice(endpoints)
            method = random.choice(methods)
            status = random.choice(status_codes)
            response_time = random.randint(50, 500)

        logs.append({
            "timestamp": timestamp.isoformat() + "Z",
            "user_id": user_id,
            "session_id": f"session_{random.randint(1, 10000):06d}",
            "ip_address": f"{random.randint(1, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 255)}",
            "method": method,
            "endpoint": endpoint,
            "status_code": status,
            "response_time_ms": response_time,
            "user_agent": random.choice(user_agents),
            "bytes_sent": random.randint(100, 10000),
            "is_authenticated": random.choice([True, True, True, False])
        })

    with open("web_logs.json", "w", encoding="utf-8") as f:
        for log in logs:
            f.write(json.dumps(log) + "\n")

    print(f"  ✓ Created web_logs.json ({num_records} records)")
    return logs


def main():
    """Génère tous les datasets"""
    print("=" * 60)
    print("GENERATING ALL DATASETS FOR FABRIC PROJECTS")
    print("=" * 60)
    print()

    # Create all datasets
    generate_retail_sales(100000)
    generate_customers(10000)
    generate_products(500)
    generate_iot_telemetry(10000)
    generate_customer_churn_data(5000)
    generate_web_logs(50000)

    print()
    print("=" * 60)
    print("ALL DATASETS GENERATED SUCCESSFULLY!")
    print("=" * 60)
    print()
    print("Files created:")
    for f in ["retail_sales.csv", "customers.csv", "products.csv",
              "iot_telemetry.json", "customer_churn.csv", "web_logs.json"]:
        if os.path.exists(f):
            size = os.path.getsize(f) / (1024 * 1024)  # MB
            print(f"  - {f} ({size:.2f} MB)")

    print()
    print("Upload these files to your Fabric Lakehouse:")
    print("  Lakehouse → Files → Upload")
    print()


if __name__ == "__main__":
    main()
