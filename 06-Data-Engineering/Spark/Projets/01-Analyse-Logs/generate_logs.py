"""
Générer des logs de test au format Apache Common Log
"""

import random
from datetime import datetime, timedelta
import os

# Configuration
NUM_LOGS = 10000
OUTPUT_FILE = "data/access.log"

# IPs fictives
IPS = [
    "192.168.1.1", "192.168.1.2", "192.168.1.3",
    "10.0.0.1", "10.0.0.2", "10.0.0.3",
    "172.16.0.1", "172.16.0.2",
    "203.0.113.1", "203.0.113.2"  # IPs de test
]

# Paths
PATHS = [
    "/", "/index.html", "/about.html", "/contact.html",
    "/products.html", "/product/123", "/product/456",
    "/api/users", "/api/products", "/api/login", "/api/logout",
    "/images/logo.png", "/images/banner.jpg", "/css/style.css",
    "/js/main.js", "/favicon.ico",
    "/admin/dashboard",  # Devrait être 403
    "/non-existent-page.html"  # 404
]

# Méthodes HTTP
METHODS = ["GET"] * 85 + ["POST"] * 10 + ["PUT"] * 3 + ["DELETE"] * 2

# Codes de statut
def get_status_code(path):
    """Retourne un code de statut basé sur le path"""
    if "non-existent" in path:
        return 404
    elif "/admin/" in path:
        return random.choice([403, 200])  # Parfois interdit
    elif "/api/" in path:
        return random.choice([200] * 8 + [401, 500])  # Parfois erreur
    else:
        return random.choice([200] * 95 + [304] * 3 + [404] * 2)

def get_size(status):
    """Taille de la réponse basée sur le status"""
    if status >= 400:
        return random.randint(200, 500)
    elif status == 304:
        return 0
    else:
        return random.randint(1000, 50000)

# Générer les logs
print(f"Génération de {NUM_LOGS} logs...")

os.makedirs("data", exist_ok=True)

start_time = datetime(2024, 1, 10, 0, 0, 0)

with open(OUTPUT_FILE, 'w') as f:
    for i in range(NUM_LOGS):
        # Random IP
        ip = random.choice(IPS)

        # Timestamp incrémental avec un peu de random
        timestamp = start_time + timedelta(seconds=i * 10 + random.randint(0, 5))
        timestamp_str = timestamp.strftime('%d/%b/%Y:%H:%M:%S +0000')

        # Method et path
        method = random.choice(METHODS)
        path = random.choice(PATHS)
        protocol = "HTTP/1.1"

        # Status et size
        status = get_status_code(path)
        size = get_size(status)

        # Format Apache Common Log
        log_line = f'{ip} - - [{timestamp_str}] "{method} {path} {protocol}" {status} {size}\n'
        f.write(log_line)

print(f"✅ {NUM_LOGS} logs générés dans {OUTPUT_FILE}")

# Ajouter quelques lignes malformées pour tester le parsing
with open(OUTPUT_FILE, 'a') as f:
    f.write("MALFORMED LOG LINE\n")
    f.write("Another invalid line without proper format\n")
    f.write("\n")  # Ligne vide

print("✅ Logs malformés ajoutés pour tester la robustesse")
