# 🔐 Chapitre 7 : Sécurité

## Introduction

La sécurité n'est pas une fonctionnalité qu'on ajoute à la fin, c'est un état d'esprit qui doit guider chaque décision de développement. Ce chapitre couvre les vulnérabilités les plus courantes et les bonnes pratiques pour construire des applications sécurisées.

## 🛡️ OWASP Top 10 (2021)

### A01 - Broken Access Control

#### Le Problème
Les contrôles d'accès mal implémentés permettent aux utilisateurs d'agir en dehors de leurs permissions.

```python
# ❌ Mauvais : Pas de vérification d'autorisation
@app.route('/api/users/<user_id>/profile')
def get_user_profile(user_id):
    user = User.query.get(user_id)
    return jsonify(user.to_dict())

# ❌ Mauvais : Vérification côté client uniquement
@app.route('/admin/delete-user/<user_id>')
def delete_user(user_id):
    # L'UI cache le bouton, mais l'endpoint reste accessible
    user = User.query.get(user_id)
    db.session.delete(user)
    db.session.commit()
    return {'success': True}

# ✅ Bon : Contrôle d'accès approprié
from functools import wraps

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return {'error': 'Token required'}, 401
        
        try:
            payload = jwt.decode(token.split(' ')[1], SECRET_KEY, algorithms=['HS256'])
            current_user = User.query.get(payload['user_id'])
            if not current_user:
                return {'error': 'Invalid token'}, 401
        except jwt.InvalidTokenError:
            return {'error': 'Invalid token'}, 401
        
        return f(current_user, *args, **kwargs)
    return decorated_function

def require_admin(f):
    @wraps(f)
    def decorated_function(current_user, *args, **kwargs):
        if not current_user.is_admin:
            return {'error': 'Admin access required'}, 403
        return f(current_user, *args, **kwargs)
    return decorated_function

def require_owner_or_admin(f):
    @wraps(f)
    def decorated_function(current_user, user_id, *args, **kwargs):
        if current_user.id != int(user_id) and not current_user.is_admin:
            return {'error': 'Access denied'}, 403
        return f(current_user, user_id, *args, **kwargs)
    return decorated_function

@app.route('/api/users/<user_id>/profile')
@require_auth
@require_owner_or_admin
def get_user_profile(current_user, user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())

@app.route('/admin/delete-user/<user_id>', methods=['DELETE'])
@require_auth
@require_admin
def delete_user(current_user, user_id):
    user = User.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return {'success': True}
```

### A02 - Cryptographic Failures

#### Stockage Sécurisé des Mots de Passe

```python
from werkzeug.security import generate_password_hash, check_password_hash
import bcrypt
import os

# ❌ Mauvais : Stockage en clair ou hash faible
def create_user_bad(email, password):
    user = User(
        email=email,
        password=password  # En clair !
    )
    # ou
    user.password = hashlib.md5(password.encode()).hexdigest()  # MD5 cassé

# ✅ Bon : Bcrypt avec coût approprié
def create_user_good(email, password):
    # Bcrypt avec coût adaptatif
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=12))
    
    user = User(
        email=email,
        password_hash=hashed.decode('utf-8')
    )
    return user

def verify_password(user, password):
    return bcrypt.checkpw(
        password.encode('utf-8'), 
        user.password_hash.encode('utf-8')
    )

# Alternative avec Werkzeug
def create_user_werkzeug(email, password):
    user = User(
        email=email,
        password_hash=generate_password_hash(password, method='pbkdf2:sha256')
    )
    return user

def verify_password_werkzeug(user, password):
    return check_password_hash(user.password_hash, password)
```

#### Chiffrement des Données Sensibles

```python
from cryptography.fernet import Fernet
import base64
import os

class DataEncryption:
    def __init__(self):
        # Clé stockée de manière sécurisée (variables d'environnement)
        key = os.environ.get('ENCRYPTION_KEY')
        if not key:
            # Générer une nouvelle clé (une seule fois)
            key = Fernet.generate_key()
            print(f"Store this key securely: {key.decode()}")
        else:
            key = key.encode()
        
        self.cipher_suite = Fernet(key)
    
    def encrypt(self, data: str) -> str:
        """Chiffre une chaîne de caractères."""
        encrypted_data = self.cipher_suite.encrypt(data.encode())
        return base64.urlsafe_b64encode(encrypted_data).decode()
    
    def decrypt(self, encrypted_data: str) -> str:
        """Déchiffre une chaîne de caractères."""
        decoded_data = base64.urlsafe_b64decode(encrypted_data.encode())
        decrypted_data = self.cipher_suite.decrypt(decoded_data)
        return decrypted_data.decode()

# Utilisation avec SQLAlchemy
from sqlalchemy_utils import EncryptedType
from sqlalchemy_utils.types.encrypted.encrypted_type import AesEngine

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    
    # Données sensibles chiffrées
    ssn = db.Column(EncryptedType(db.String, os.environ.get('SECRET_KEY'), AesEngine, 'pkcs5'))
    credit_card = db.Column(EncryptedType(db.String, os.environ.get('SECRET_KEY'), AesEngine, 'pkcs5'))
    
    # Mots de passe : hash, jamais chiffrement !
    password_hash = db.Column(db.String(255), nullable=False)
```

### A03 - Injection

#### Protection contre l'Injection SQL

```python
# ❌ JAMAIS : Concaténation de chaînes
def get_user_by_email_bad(email):
    query = f"SELECT * FROM users WHERE email = '{email}'"
    return db.execute(query)
    # Vulnérable à : ' OR '1'='1' --

# ❌ JAMAIS : Formatage de chaînes
def get_orders_bad(user_id, status):
    query = "SELECT * FROM orders WHERE user_id = {} AND status = '{}'".format(user_id, status)
    return db.execute(query)

# ✅ TOUJOURS : Requêtes paramétrées
def get_user_by_email_good(email):
    query = "SELECT * FROM users WHERE email = %s"
    return db.execute(query, (email,))

def get_orders_good(user_id, status):
    query = "SELECT * FROM orders WHERE user_id = %s AND status = %s"
    return db.execute(query, (user_id, status))

# ✅ Avec SQLAlchemy ORM (le plus sûr)
def get_user_by_email_orm(email):
    return User.query.filter_by(email=email).first()

def get_orders_orm(user_id, status):
    return Order.query.filter(
        Order.user_id == user_id,
        Order.status == status
    ).all()

# ✅ Avec SQLAlchemy Core et requêtes textuelles
from sqlalchemy import text

def complex_query_safe(user_id, start_date):
    query = text("""
        SELECT u.name, COUNT(o.id) as order_count
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.id = :user_id AND o.created_at >= :start_date
        GROUP BY u.id, u.name
    """)
    return db.execute(query, {
        'user_id': user_id,
        'start_date': start_date
    })
```

#### Protection contre l'Injection de Commandes

```python
import subprocess
import shlex

# ❌ Mauvais : Exécution directe
def resize_image_bad(filename, width, height):
    cmd = f"convert {filename} -resize {width}x{height} output.jpg"
    subprocess.run(cmd, shell=True)  # Vulnérable !

# ✅ Bon : Validation et échappement
def resize_image_good(filename, width, height):
    # Validation des entrées
    if not filename.replace('_', '').replace('.', '').isalnum():
        raise ValueError("Nom de fichier invalide")
    
    if not (isinstance(width, int) and isinstance(height, int)):
        raise ValueError("Dimensions invalides")
    
    if width > 5000 or height > 5000:
        raise ValueError("Dimensions trop grandes")
    
    # Utilisation de liste d'arguments (pas de shell)
    cmd = [
        'convert',
        shlex.quote(filename),  # Échappement
        '-resize',
        f'{width}x{height}',
        'output.jpg'
    ]
    subprocess.run(cmd, shell=False)  # Plus sûr
```

### A04 - Insecure Design

#### Mise en Place de Rate Limiting

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import redis
import time
from functools import wraps

# Configuration avec Redis
limiter = Limiter(
    app,
    key_func=get_remote_address,
    storage_uri="redis://localhost:6379"
)

# Rate limiting sur les endpoints sensibles
@app.route('/api/login', methods=['POST'])
@limiter.limit("5 per minute")  # Max 5 tentatives par minute
def login():
    # Implementation du login
    pass

@app.route('/api/users', methods=['POST'])
@limiter.limit("10 per hour")  # Max 10 créations par heure
def create_user():
    # Implementation
    pass

# Rate limiting personnalisé par utilisateur
def rate_limit_by_user(max_requests=100, window=3600):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_id = get_current_user_id()
            if not user_id:
                return {'error': 'Authentication required'}, 401
            
            # Clé Redis spécifique à l'utilisateur
            key = f"rate_limit:user:{user_id}:{int(time.time() // window)}"
            
            # Vérifier le nombre de requêtes
            current_requests = redis_client.get(key)
            if current_requests and int(current_requests) >= max_requests:
                return {'error': 'Rate limit exceeded'}, 429
            
            # Incrémenter le compteur
            pipe = redis_client.pipeline()
            pipe.incr(key)
            pipe.expire(key, window)
            pipe.execute()
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/api/upload', methods=['POST'])
@rate_limit_by_user(max_requests=50, window=3600)  # 50 uploads/heure
def upload_file():
    # Implementation
    pass
```

#### Validation Robuste des Entrées

```python
from marshmallow import Schema, fields, validate, ValidationError
import re

class UserRegistrationSchema(Schema):
    email = fields.Email(required=True)
    password = fields.String(
        required=True,
        validate=[
            validate.Length(min=8, max=128),
            validate.Regexp(
                r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
                error="Password must contain uppercase, lowercase, digit and special character"
            )
        ]
    )
    name = fields.String(
        required=True,
        validate=[
            validate.Length(min=2, max=50),
            validate.Regexp(r'^[a-zA-ZÀ-ÿ\s\-\']+$', error="Name contains invalid characters")
        ]
    )
    age = fields.Integer(
        required=True,
        validate=validate.Range(min=13, max=120)
    )

# Utilisation
@app.route('/api/register', methods=['POST'])
def register():
    schema = UserRegistrationSchema()
    try:
        data = schema.load(request.json)
    except ValidationError as err:
        return {'errors': err.messages}, 400
    
    # Données validées, continuer le traitement
    user = create_user(data)
    return {'user': user.to_dict()}, 201
```

### A05 - Security Misconfiguration

#### Configuration Sécurisée de FastAPI

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
import os

# Configuration selon l'environnement
DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'
ENVIRONMENT = os.getenv('ENVIRONMENT', 'production')

# Application avec configuration sécurisée
app = FastAPI(
    title="Secure API",
    description="API with security best practices",
    version="1.0.0",
    # En production : pas de documentation publique
    docs_url="/docs" if DEBUG else None,
    redoc_url="/redoc" if DEBUG else None,
    openapi_url="/openapi.json" if DEBUG else None
)

# Validation des hosts autorisés
allowed_hosts = os.getenv('ALLOWED_HOSTS', 'localhost').split(',')
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=allowed_hosts
)

# CORS sécurisé
if ENVIRONMENT == 'development':
    origins = ["http://localhost:3000", "http://localhost:8080"]
else:
    origins = os.getenv('CORS_ORIGINS', '').split(',')

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # JAMAIS "*" en production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Headers de sécurité
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    
    # Prévention XSS
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    
    # HTTPS obligatoire
    if ENVIRONMENT == 'production':
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    # CSP basique
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'"
    )
    
    return response
```

#### Variables d'Environnement Sécurisées

```python
# config.py
from pydantic import BaseSettings, validator
import os

class Settings(BaseSettings):
    # Database
    database_url: str
    
    # Security
    secret_key: str
    jwt_secret: str
    encryption_key: str
    
    # Validation de la force des secrets
    @validator('secret_key', 'jwt_secret', 'encryption_key')
    def validate_secret_strength(cls, v):
        if len(v) < 32:
            raise ValueError('Secret must be at least 32 characters long')
        return v
    
    # CORS
    cors_origins: list = []
    
    @validator('cors_origins', pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(',')]
        return v
    
    # Environment
    environment: str = 'production'
    debug: bool = False
    
    class Config:
        env_file = '.env'
        env_file_encoding = 'utf-8'

# .env.example (à ne jamais commiter avec vraies valeurs)
"""
DATABASE_URL=postgresql://user:password@localhost/dbname
SECRET_KEY=your-super-secret-key-at-least-32-chars-long
JWT_SECRET=another-super-secret-key-for-jwt-tokens
ENCRYPTION_KEY=base64-encoded-encryption-key-here
CORS_ORIGINS=http://localhost:3000,https://myapp.com
ENVIRONMENT=production
DEBUG=false
"""

# Génération sécurisée de secrets
import secrets

def generate_secret_key(length=64):
    """Génère une clé secrète cryptographiquement sûre."""
    return secrets.token_urlsafe(length)

# Usage
if __name__ == "__main__":
    print(f"SECRET_KEY={generate_secret_key()}")
    print(f"JWT_SECRET={generate_secret_key()}")
```

### A07 - Identification and Authentication Failures

#### JWT Sécurisé

```python
import jwt
from datetime import datetime, timedelta
import uuid

class JWTManager:
    def __init__(self, secret_key, algorithm='HS256'):
        self.secret_key = secret_key
        self.algorithm = algorithm
        # Stockage des tokens révoqués (Redis en production)
        self.revoked_tokens = set()
    
    def generate_tokens(self, user_id):
        """Génère access et refresh tokens."""
        now = datetime.utcnow()
        
        # Access token (courte durée)
        access_payload = {
            'user_id': user_id,
            'type': 'access',
            'iat': now,
            'exp': now + timedelta(minutes=15),
            'jti': str(uuid.uuid4())  # Unique ID pour révocation
        }
        
        # Refresh token (longue durée)
        refresh_payload = {
            'user_id': user_id,
            'type': 'refresh',
            'iat': now,
            'exp': now + timedelta(days=7),
            'jti': str(uuid.uuid4())
        }
        
        access_token = jwt.encode(access_payload, self.secret_key, self.algorithm)
        refresh_token = jwt.encode(refresh_payload, self.secret_key, self.algorithm)
        
        return {
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': 900  # 15 minutes
        }
    
    def verify_token(self, token, token_type='access'):
        """Vérifie et décode un token."""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            
            # Vérifier le type
            if payload.get('type') != token_type:
                raise jwt.InvalidTokenError('Invalid token type')
            
            # Vérifier si révoqué
            jti = payload.get('jti')
            if jti in self.revoked_tokens:
                raise jwt.InvalidTokenError('Token revoked')
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise jwt.InvalidTokenError('Token expired')
        except jwt.InvalidTokenError:
            raise jwt.InvalidTokenError('Invalid token')
    
    def refresh_access_token(self, refresh_token):
        """Génère un nouveau access token à partir d'un refresh token."""
        payload = self.verify_token(refresh_token, 'refresh')
        user_id = payload['user_id']
        
        # Générer seulement un nouvel access token
        now = datetime.utcnow()
        access_payload = {
            'user_id': user_id,
            'type': 'access',
            'iat': now,
            'exp': now + timedelta(minutes=15),
            'jti': str(uuid.uuid4())
        }
        
        return jwt.encode(access_payload, self.secret_key, self.algorithm)
    
    def revoke_token(self, token):
        """Révoque un token."""
        try:
            payload = jwt.decode(
                token, 
                self.secret_key, 
                algorithms=[self.algorithm],
                options={"verify_exp": False}  # Permettre tokens expirés
            )
            jti = payload.get('jti')
            if jti:
                self.revoked_tokens.add(jti)
        except jwt.InvalidTokenError:
            pass  # Token invalide, pas besoin de révoquer
```

#### Protection contre les Attaques par Force Brute

```python
import time
from collections import defaultdict
from threading import Lock

class LoginAttemptTracker:
    def __init__(self):
        self.attempts = defaultdict(list)  # IP -> [timestamps]
        self.locked_accounts = defaultdict(list)  # user_id -> [timestamps]
        self.lock = Lock()
    
    def is_ip_blocked(self, ip_address, max_attempts=5, window=300):
        """Vérifie si une IP est bloquée (5 tentatives en 5 minutes)."""
        with self.lock:
            now = time.time()
            # Nettoyer les tentatives anciennes
            self.attempts[ip_address] = [
                timestamp for timestamp in self.attempts[ip_address]
                if now - timestamp < window
            ]
            return len(self.attempts[ip_address]) >= max_attempts
    
    def is_account_locked(self, user_id, max_attempts=3, window=900):
        """Vérifie si un compte est verrouillé (3 tentatives en 15 minutes)."""
        with self.lock:
            now = time.time()
            self.locked_accounts[user_id] = [
                timestamp for timestamp in self.locked_accounts[user_id]
                if now - timestamp < window
            ]
            return len(self.locked_accounts[user_id]) >= max_attempts
    
    def record_failed_attempt(self, ip_address, user_id=None):
        """Enregistre une tentative échouée."""
        with self.lock:
            now = time.time()
            self.attempts[ip_address].append(now)
            if user_id:
                self.locked_accounts[user_id].append(now)

tracker = LoginAttemptTracker()

@app.route('/api/login', methods=['POST'])
def login():
    ip_address = request.remote_addr
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    # Vérifier si l'IP est bloquée
    if tracker.is_ip_blocked(ip_address):
        return {'error': 'Too many attempts from this IP'}, 429
    
    # Trouver l'utilisateur
    user = User.query.filter_by(email=email).first()
    if not user:
        tracker.record_failed_attempt(ip_address)
        return {'error': 'Invalid credentials'}, 401
    
    # Vérifier si le compte est verrouillé
    if tracker.is_account_locked(user.id):
        return {'error': 'Account temporarily locked'}, 423
    
    # Vérifier le mot de passe
    if not verify_password(user, password):
        tracker.record_failed_attempt(ip_address, user.id)
        return {'error': 'Invalid credentials'}, 401
    
    # Connexion réussie
    tokens = jwt_manager.generate_tokens(user.id)
    return tokens
```

## 🎯 Validation et Sanitisation Frontend

### Protection XSS côté Vue.js

```javascript
// composables/useSecurity.js
export function useSecurity() {
  const sanitizeHtml = (dirty) => {
    // Utiliser DOMPurify pour nettoyer le HTML
    return DOMPurify.sanitize(dirty, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
      ALLOWED_ATTR: ['href']
    })
  }
  
  const escapeHtml = (unsafe) => {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
  
  const validateInput = (value, type) => {
    const patterns = {
      email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      phone: /^\+?[1-9]\d{1,14}$/,
      alphanumeric: /^[a-zA-Z0-9]+$/,
      url: /^https?:\/\/.+/
    }
    
    return patterns[type]?.test(value) || false
  }
  
  return {
    sanitizeHtml,
    escapeHtml,
    validateInput
  }
}

// components/SecureDisplay.vue
<template>
  <div>
    <!-- ❌ Mauvais : v-html sans sanitisation -->
    <!-- <div v-html="userContent"></div> -->
    
    <!-- ✅ Bon : Sanitisation avant affichage -->
    <div v-html="sanitizedContent"></div>
    
    <!-- ✅ Meilleur : Éviter v-html complètement -->
    <div>{{ escapedContent }}</div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useSecurity } from '@/composables/useSecurity'

const props = defineProps({
  content: String
})

const { sanitizeHtml, escapeHtml } = useSecurity()

const sanitizedContent = computed(() => {
  return sanitizeHtml(props.content)
})

const escapedContent = computed(() => {
  return escapeHtml(props.content)
})
</script>
```

### Validation Côté Client Robuste

```javascript
// utils/validators.js
export const validators = {
  required: (value) => {
    if (!value || value.toString().trim() === '') {
      return 'Ce champ est requis'
    }
    return true
  },
  
  email: (value) => {
    const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!pattern.test(value)) {
      return 'Adresse email invalide'
    }
    return true
  },
  
  password: (value) => {
    const errors = []
    
    if (value.length < 8) {
      errors.push('au moins 8 caractères')
    }
    if (!/[A-Z]/.test(value)) {
      errors.push('une majuscule')
    }
    if (!/[a-z]/.test(value)) {
      errors.push('une minuscule')
    }
    if (!/\d/.test(value)) {
      errors.push('un chiffre')
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(value)) {
      errors.push('un caractère spécial')
    }
    
    if (errors.length > 0) {
      return `Le mot de passe doit contenir ${errors.join(', ')}`
    }
    return true
  },
  
  noScript: (value) => {
    // Détecter les tentatives d'injection de script
    const scriptPattern = /<script[^>]*>.*?<\/script>/gi
    const onEventPattern = /on\w+\s*=/gi
    const jsPattern = /javascript:/gi
    
    if (scriptPattern.test(value) || onEventPattern.test(value) || jsPattern.test(value)) {
      return 'Contenu non autorisé détecté'
    }
    return true
  },
  
  fileType: (allowedTypes) => (file) => {
    if (!file) return true
    
    const fileExtension = file.name.split('.').pop().toLowerCase()
    if (!allowedTypes.includes(fileExtension)) {
      return `Types de fichiers autorisés : ${allowedTypes.join(', ')}`
    }
    return true
  },
  
  fileSize: (maxSizeMB) => (file) => {
    if (!file) return true
    
    const maxSizeBytes = maxSizeMB * 1024 * 1024
    if (file.size > maxSizeBytes) {
      return `La taille du fichier ne doit pas dépasser ${maxSizeMB}MB`
    }
    return true
  }
}

// composables/useForm.js
import { ref, reactive } from 'vue'

export function useForm(initialData = {}, validationRules = {}) {
  const formData = reactive({ ...initialData })
  const errors = reactive({})
  const isValid = ref(true)
  
  const validate = (field = null) => {
    const fieldsToValidate = field ? [field] : Object.keys(validationRules)
    
    fieldsToValidate.forEach(fieldName => {
      const rules = validationRules[fieldName] || []
      const value = formData[fieldName]
      
      // Réinitialiser l'erreur
      errors[fieldName] = null
      
      // Appliquer les règles de validation
      for (const rule of rules) {
        const result = rule(value)
        if (result !== true) {
          errors[fieldName] = result
          break
        }
      }
    })
    
    // Vérifier si le formulaire est valide
    isValid.value = Object.values(errors).every(error => error === null)
  }
  
  const reset = () => {
    Object.keys(formData).forEach(key => {
      formData[key] = initialData[key] || ''
    })
    Object.keys(errors).forEach(key => {
      errors[key] = null
    })
    isValid.value = true
  }
  
  return {
    formData,
    errors,
    isValid,
    validate,
    reset
  }
}
```

## 🚨 Scanning et Tests de Sécurité

### Audit Automatisé des Dépendances

```bash
# Python
pip install safety bandit

# Audit des dépendances
safety check

# Analyse statique du code
bandit -r . -f json

# JavaScript/Node.js
npm audit
npm audit fix

# Audit avec yarn
yarn audit

# Configuration pour automatiser (package.json)
{
  "scripts": {
    "security:audit": "npm audit && pip-audit",
    "security:scan": "bandit -r .",
    "security:deps": "npm audit --audit-level moderate"
  }
}
```

### Configuration Sentry pour le Monitoring

```python
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

sentry_sdk.init(
    dsn=os.getenv('SENTRY_DSN'),
    integrations=[
        FlaskIntegration(transaction_style='endpoint'),
        SqlalchemyIntegration(),
    ],
    traces_sample_rate=0.1,  # 10% des transactions pour performance
    environment=os.getenv('ENVIRONMENT', 'production'),
    before_send=filter_sensitive_data
)

def filter_sensitive_data(event, hint):
    """Filtre les données sensibles avant envoi à Sentry."""
    # Supprimer les informations sensibles
    if 'request' in event:
        if 'headers' in event['request']:
            sensitive_headers = ['authorization', 'cookie', 'x-api-key']
            for header in sensitive_headers:
                event['request']['headers'].pop(header, None)
        
        if 'data' in event['request']:
            sensitive_fields = ['password', 'token', 'secret']
            for field in sensitive_fields:
                if field in event['request']['data']:
                    event['request']['data'][field] = '[Filtered]'
    
    return event
```

## 🎯 Exercices Pratiques

### Exercice 1 : Audit de Sécurité
Analysez ce code et identifiez toutes les vulnérabilités :

```python
@app.route('/search')
def search():
    query = request.args.get('q')
    results = db.execute(f"SELECT * FROM products WHERE name LIKE '%{query}%'")
    return render_template('results.html', results=results, query=query)

@app.route('/admin/users/<user_id>')
def admin_user(user_id):
    user = User.query.get(user_id)
    return jsonify(user.to_dict())

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files['file']
    file.save(f"uploads/{file.filename}")
    return "File uploaded"
```

### Exercice 2 : Implémentation Sécurisée
Implémentez un système de reset de mot de passe sécurisé incluant :
- Token à usage unique avec expiration
- Rate limiting
- Validation robuste
- Logging des tentatives

### Exercice 3 : Test de Pénétration
Créez des tests automatisés pour vérifier :
- Protection contre l'injection SQL
- Validation des inputs
- Contrôles d'accès
- Gestion des sessions

## 📚 Points Clés à Retenir

1. **Security by Design** : Penser sécurité dès la conception
2. **Validation partout** : Côté client ET serveur
3. **Principe du moindre privilège** : Accès minimal nécessaire
4. **Défense en profondeur** : Plusieurs couches de sécurité
5. **Audit régulier** : Dépendances et code
6. **Formation continue** : Rester à jour sur les menaces

## 🔗 Ressources Complémentaires

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cybersecurity)
- [Mozilla Web Security Guidelines](https://wiki.mozilla.org/Security/Guidelines/Web_Security)
- [Bandit - Python Security Linter](https://bandit.readthedocs.io/)

---

**Prochain chapitre** : [Performance et Optimisation →](08-performance.md)