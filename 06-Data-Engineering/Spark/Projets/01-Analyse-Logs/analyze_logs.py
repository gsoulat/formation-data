"""
Projet : Analyse de Logs Web Apache/Nginx

Pipeline complet d'analyse de logs :
1. Extract : Lire et parser les logs
2. Transform : Nettoyer, enrichir, analyser
3. Load : Sauvegarder les résultats
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import re

# Créer SparkSession
spark = SparkSession.builder \
    .appName("Web Logs Analysis") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

print("=" * 80)
print("ANALYSE DE LOGS WEB")
print("=" * 80)

# ========================================
# 1. EXTRACT - LECTURE ET PARSING
# ========================================
print("\n1. Extract - Lecture des logs")
print("-" * 50)

# Lire les logs bruts
logs_raw = spark.read.text("data/access.log")
print(f"Logs bruts: {logs_raw.count()} lignes")

# Pattern regex pour Apache Common Log Format
# IP - - [timestamp] "method path protocol" status size
log_pattern = r'^(\S+) \S+ \S+ \[([^\]]+)\] "(\S+) (\S+) (\S+)" (\d{3}) (\d+|-)'

# Parser les logs avec regex
logs_parsed = logs_raw.select(
    regexp_extract('value', log_pattern, 1).alias('ip'),
    regexp_extract('value', log_pattern, 2).alias('timestamp_str'),
    regexp_extract('value', log_pattern, 3).alias('method'),
    regexp_extract('value', log_pattern, 4).alias('path'),
    regexp_extract('value', log_pattern, 5).alias('protocol'),
    regexp_extract('value', log_pattern, 6).alias('status'),
    regexp_extract('value', log_pattern, 7).alias('size')
)

# Filtrer les lignes valides (IP non vide)
logs_valid = logs_parsed.filter(col('ip') != '')

print(f"Logs parsés: {logs_valid.count()} lignes")
print(f"Logs rejetés: {logs_raw.count() - logs_valid.count()}")

logs_valid.show(5, truncate=False)

# ========================================
# 2. TRANSFORM - NETTOYAGE ET ENRICHISSEMENT
# ========================================
print("\n2. Transform - Nettoyage et enrichissement")
print("-" * 50)

# Convertir les types
logs_clean = logs_valid \
    .withColumn('status', col('status').cast('int')) \
    .withColumn('size', when(col('size') == '-', 0).otherwise(col('size').cast('int')))

# Parser le timestamp
# Format: 10/Jan/2024:13:55:36 +0000
logs_clean = logs_clean \
    .withColumn('timestamp',
        to_timestamp(col('timestamp_str'), 'dd/MMM/yyyy:HH:mm:ss Z'))

# Extraire date et heure
logs_clean = logs_clean \
    .withColumn('date', to_date(col('timestamp'))) \
    .withColumn('hour', hour(col('timestamp'))) \
    .withColumn('day_of_week', dayofweek(col('timestamp')))

# Catégoriser les codes HTTP
logs_clean = logs_clean \
    .withColumn('status_category',
        when(col('status') < 300, '2xx-Success')
        .when(col('status') < 400, '3xx-Redirect')
        .when(col('status') < 500, '4xx-ClientError')
        .otherwise('5xx-ServerError')
    )

# Identifier le type de ressource
logs_clean = logs_clean \
    .withColumn('resource_type',
        when(col('path').rlike(r'\.html?$'), 'HTML')
        .when(col('path').rlike(r'\.(css|js)$'), 'Static')
        .when(col('path').rlike(r'\.(jpg|png|gif|ico)$'), 'Image')
        .when(col('path').rlike(r'^/api/'), 'API')
        .otherwise('Other')
    )

# Cache pour réutilisation
logs_clean.cache()

print("\n✅ Logs après nettoyage et enrichissement:")
logs_clean.select('ip', 'timestamp', 'method', 'path', 'status', 'status_category', 'resource_type').show(10, truncate=False)

# ========================================
# 3. ANALYSE - AGRÉGATIONS
# ========================================
print("\n3. Analyse - Statistiques")
print("-" * 50)

# 3.1 Statistiques générales
print("\n📊 Statistiques générales:")
total_requests = logs_clean.count()
unique_ips = logs_clean.select('ip').distinct().count()
total_bandwidth = logs_clean.select(sum('size')).collect()[0][0]

print(f"  Total requêtes: {total_requests}")
print(f"  IPs uniques: {unique_ips}")
print(f"  Bande passante totale: {total_bandwidth / (1024*1024):.2f} MB")

# 3.2 Distribution des codes HTTP
print("\n📊 Distribution des codes HTTP:")
status_dist = logs_clean.groupBy('status_category', 'status') \
    .count() \
    .orderBy('status_category', 'count', ascending=False)
status_dist.show()

# 3.3 Requêtes par heure
print("\n📊 Requêtes par heure:")
hourly_stats = logs_clean.groupBy('date', 'hour') \
    .agg(
        count('*').alias('num_requests'),
        countDistinct('ip').alias('unique_users'),
        sum('size').alias('total_bytes')
    ) \
    .orderBy('date', 'hour')
hourly_stats.show(24)

# 3.4 Top 10 pages
print("\n📊 Top 10 pages les plus visitées:")
top_pages = logs_clean.groupBy('path') \
    .agg(
        count('*').alias('visits'),
        countDistinct('ip').alias('unique_visitors')
    ) \
    .orderBy(col('visits').desc()) \
    .limit(10)
top_pages.show(truncate=False)

# 3.5 Top 10 IPs (utilisateurs actifs)
print("\n📊 Top 10 IPs les plus actives:")
top_ips = logs_clean.groupBy('ip') \
    .agg(
        count('*').alias('num_requests'),
        countDistinct('path').alias('unique_pages'),
        sum('size').alias('total_bytes')
    ) \
    .orderBy(col('num_requests').desc()) \
    .limit(10)
top_ips.show()

# 3.6 Erreurs 404
print("\n📊 Pages 404 (Not Found):")
errors_404 = logs_clean.filter(col('status') == 404) \
    .groupBy('path') \
    .count() \
    .orderBy(col('count').desc()) \
    .limit(10)
print(f"  Total erreurs 404: {logs_clean.filter(col('status') == 404).count()}")
errors_404.show(truncate=False)

# 3.7 Analyse par type de ressource
print("\n📊 Requêtes par type de ressource:")
resource_stats = logs_clean.groupBy('resource_type') \
    .agg(
        count('*').alias('num_requests'),
        avg('size').alias('avg_size'),
        sum('size').alias('total_size')
    ) \
    .orderBy(col('num_requests').desc())
resource_stats.show()

# 3.8 Trafic par jour de la semaine
print("\n📊 Trafic par jour de la semaine:")
# 1=Sunday, 2=Monday, ..., 7=Saturday
day_names = {1: 'Sunday', 2: 'Monday', 3: 'Tuesday', 4: 'Wednesday',
             5: 'Thursday', 6: 'Friday', 7: 'Saturday'}

daily_traffic = logs_clean.groupBy('day_of_week') \
    .count() \
    .orderBy('day_of_week')
daily_traffic.show()

# ========================================
# 4. LOAD - SAUVEGARDE DES RÉSULTATS
# ========================================
print("\n4. Load - Sauvegarde des résultats")
print("-" * 50)

# 4.1 Logs nettoyés (partitionné par date)
print("\n💾 Sauvegarde logs nettoyés...")
logs_clean.write \
    .mode('overwrite') \
    .partitionBy('date') \
    .parquet('output/logs_cleaned')
print("✅ output/logs_cleaned/")

# 4.2 Agrégations
print("\n💾 Sauvegarde agrégations...")

hourly_stats.write.mode('overwrite').parquet('output/hourly_stats')
print("✅ output/hourly_stats/")

top_pages.write.mode('overwrite').parquet('output/top_pages')
print("✅ output/top_pages/")

top_ips.write.mode('overwrite').parquet('output/top_ips')
print("✅ output/top_ips/")

errors_404.write.mode('overwrite').parquet('output/errors_404')
print("✅ output/errors_404/")

resource_stats.write.mode('overwrite').parquet('output/resource_stats')
print("✅ output/resource_stats/")

# 4.3 Export CSV pour BI
print("\n💾 Export CSV...")
hourly_stats.coalesce(1).write \
    .mode('overwrite') \
    .option('header', 'true') \
    .csv('output/hourly_stats_csv')
print("✅ output/hourly_stats_csv/")

# ========================================
# 5. RAPPORT FINAL
# ========================================
print("\n" + "=" * 80)
print("RAPPORT D'ANALYSE")
print("=" * 80)

report = f"""
📊 STATISTIQUES GLOBALES
------------------------
Total requêtes      : {total_requests:,}
IPs uniques         : {unique_ips:,}
Bande passante      : {total_bandwidth / (1024*1024):.2f} MB
Taille moyenne      : {total_bandwidth / total_requests:.2f} bytes

📈 CODES HTTP
-------------
"""

for row in status_dist.collect()[:10]:
    report += f"{row.status_category:20} {row.status:3} : {row['count']:,}\n"

report += f"""
🏆 TOP 3 PAGES
--------------
"""
for i, row in enumerate(top_pages.collect()[:3], 1):
    report += f"{i}. {row.path} - {row.visits:,} visites\n"

report += f"""
⚠️  ERREURS 404
--------------
Total 404: {logs_clean.filter(col('status') == 404).count():,}
"""
for row in errors_404.collect()[:3]:
    report += f"  {row.path}: {row['count']:,}\n"

print(report)

# Sauvegarder le rapport
with open('results/analysis_report.txt', 'w') as f:
    f.write(report)
print("\n✅ Rapport sauvegardé: results/analysis_report.txt")

# ========================================
# DÉTECTION D'ANOMALIES (BONUS)
# ========================================
print("\n" + "=" * 80)
print("DÉTECTION D'ANOMALIES")
print("=" * 80)

# IPs avec trop de 404 (scan potentiel)
print("\n🚨 IPs avec > 10 erreurs 404 (scan potentiel):")
suspicious_ips = logs_clean.filter(col('status') == 404) \
    .groupBy('ip') \
    .count() \
    .filter(col('count') > 10) \
    .orderBy(col('count').desc())
suspicious_ips.show()

# Requêtes trop rapides (bot potentiel)
from pyspark.sql.window import Window

window_spec = Window.partitionBy('ip').orderBy('timestamp')
logs_with_lag = logs_clean \
    .withColumn('prev_timestamp', lag('timestamp').over(window_spec)) \
    .withColumn('time_diff',
        (col('timestamp').cast('long') - col('prev_timestamp').cast('long')))

# Requêtes < 1 seconde entre deux requêtes
fast_requests = logs_with_lag.filter(col('time_diff') < 1) \
    .groupBy('ip') \
    .count() \
    .filter(col('count') > 50) \
    .orderBy(col('count').desc())

print("\n🚨 IPs avec > 50 requêtes < 1s d'intervalle (bot potentiel):")
fast_requests.show()

print("\n" + "=" * 80)
print("✅ ANALYSE TERMINÉE")
print("=" * 80)

# Libérer le cache
logs_clean.unpersist()

# Arrêter Spark
spark.stop()
