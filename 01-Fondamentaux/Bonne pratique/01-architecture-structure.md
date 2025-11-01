# 📐 Chapitre 1 : Architecture et Structure de Projet

## Introduction

L'architecture logicielle est la fondation sur laquelle repose toute application. Une bonne architecture facilite le développement, la maintenance et l'évolution du projet. Dans ce chapitre, nous explorerons les principes d'architecture et leur application pratique avec FastAPI et Vue.js.

## 🏗️ Principes Fondamentaux

### SOLID Principles

Les principes SOLID constituent la base d'une architecture orientée objet solide :

#### 1. **S**ingle Responsibility Principle (SRP)
Chaque classe/module ne doit avoir qu'une seule raison de changer.

```python
# ❌ Mauvais : Classe avec plusieurs responsabilités
class User:
    def __init__(self, email, password):
        self.email = email
        self.password = password
    
    def save_to_database(self):
        # Logique de sauvegarde
        pass
    
    def send_welcome_email(self):
        # Logique d'envoi d'email
        pass
    
    def validate_password(self):
        # Logique de validation
        pass

# ✅ Bon : Responsabilités séparées
class User:
    def __init__(self, email, password):
        self.email = email
        self.password = password

class UserRepository:
    def save(self, user: User):
        # Logique de sauvegarde
        pass

class EmailService:
    def send_welcome_email(self, user: User):
        # Logique d'envoi
        pass

class PasswordValidator:
    def validate(self, password: str) -> bool:
        # Logique de validation
        pass
```

#### 2. **O**pen/Closed Principle (OCP)
Les entités doivent être ouvertes à l'extension mais fermées à la modification.

```python
from abc import ABC, abstractmethod

# Interface pour les stratégies de notification
class NotificationStrategy(ABC):
    @abstractmethod
    def send(self, user, message):
        pass

class EmailNotification(NotificationStrategy):
    def send(self, user, message):
        # Envoi par email
        pass

class SMSNotification(NotificationStrategy):
    def send(self, user, message):
        # Envoi par SMS
        pass

# Utilisation
class NotificationService:
    def __init__(self, strategy: NotificationStrategy):
        self.strategy = strategy
    
    def notify(self, user, message):
        self.strategy.send(user, message)
```

#### 3. **L**iskov Substitution Principle (LSP)
Les sous-classes doivent pouvoir remplacer leurs classes parentes.

#### 4. **I**nterface Segregation Principle (ISP)
Les clients ne doivent pas dépendre d'interfaces qu'ils n'utilisent pas.

#### 5. **D**ependency Inversion Principle (DIP)
Dépendre des abstractions, pas des implémentations concrètes.

## 🎯 Architecture MVC avec FastAPI et Vue.js

### Vue d'ensemble

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│    Vue.js       │────▶│    FastAPI      │────▶│   PostgreSQL    │
│   (Frontend)    │     │   (Backend)     │     │   (Database)    │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        View                Controller              Model
```

### Structure Backend (FastAPI)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # Point d'entrée FastAPI
│   ├── config.py            # Configuration centralisée
│   ├── database.py          # Connexion base de données
│   │
│   ├── api/                 # Couche Contrôleur
│   │   ├── __init__.py
│   │   ├── deps.py          # Dépendances communes
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── endpoints/
│   │       │   ├── __init__.py
│   │       │   ├── users.py
│   │       │   ├── auth.py
│   │       │   └── items.py
│   │       └── api.py       # Routeur principal
│   │
│   ├── core/                # Configuration et sécurité
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── security.py
│   │   └── logging.py
│   │
│   ├── models/              # Couche Modèle (ORM)
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── user.py
│   │   └── item.py
│   │
│   ├── schemas/             # Schémas Pydantic
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   │
│   ├── services/            # Logique métier
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── auth_service.py
│   │
│   └── repositories/        # Accès aux données
│       ├── __init__.py
│       ├── base.py
│       └── user_repository.py
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   └── integration/
│
├── migrations/              # Alembic migrations
├── requirements.txt
├── .env.example
└── Dockerfile
```

### Structure Frontend (Vue.js)

```
frontend/
├── public/
│   └── index.html
│
├── src/
│   ├── main.js              # Point d'entrée
│   ├── App.vue              # Composant racine
│   │
│   ├── assets/              # Images, fonts, etc.
│   │   ├── images/
│   │   └── styles/
│   │       └── main.css
│   │
│   ├── components/          # Composants réutilisables
│   │   ├── common/
│   │   │   ├── BaseButton.vue
│   │   │   ├── BaseInput.vue
│   │   │   └── BaseModal.vue
│   │   └── user/
│   │       ├── UserList.vue
│   │       ├── UserCard.vue
│   │       └── UserForm.vue
│   │
│   ├── views/               # Pages/Vues
│   │   ├── HomeView.vue
│   │   ├── LoginView.vue
│   │   └── users/
│   │       ├── UsersView.vue
│   │       └── UserDetailView.vue
│   │
│   ├── router/              # Configuration routes
│   │   └── index.js
│   │
│   ├── stores/              # État global (Pinia)
│   │   ├── index.js
│   │   ├── auth.js
│   │   └── user.js
│   │
│   ├── services/            # Services API
│   │   ├── api.js
│   │   ├── auth.service.js
│   │   └── user.service.js
│   │
│   ├── utils/               # Fonctions utilitaires
│   │   ├── validators.js
│   │   ├── formatters.js
│   │   └── constants.js
│   │
│   └── composables/         # Composition API hooks
│       ├── useAuth.js
│       └── useApi.js
│
├── tests/
│   ├── unit/
│   └── e2e/
│
├── package.json
├── vite.config.js
└── Dockerfile
```

## 🔧 Implémentation Pratique

### Backend : main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.api import api_router
from app.core.config import settings
from app.core.logging import setup_logging

# Configuration du logging
setup_logging()

# Création de l'application
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusion des routes
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.on_event("startup")
async def startup_event():
    """Actions au démarrage de l'application"""
    logger.info(f"Starting {settings.PROJECT_NAME}")

@app.on_event("shutdown")
async def shutdown_event():
    """Actions à l'arrêt de l'application"""
    logger.info(f"Shutting down {settings.PROJECT_NAME}")
```

### Configuration centralisée : config.py

```python
from pydantic import BaseSettings, AnyHttpUrl, validator
from typing import List, Optional

class Settings(BaseSettings):
    # Informations projet
    PROJECT_NAME: str = "FastAPI Best Practices"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Base de données
    DATABASE_URL: str
    
    # Sécurité
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    BACKEND_CORS_ORIGINS: List[AnyHttpUrl] = []
    
    @validator("BACKEND_CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # Redis (optionnel)
    REDIS_URL: Optional[str] = None
    
    # Email
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

### Repository Pattern : base.py

```python
from typing import Generic, TypeVar, Type, Optional, List
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.models.base import Base

ModelType = TypeVar("ModelType", bound=Base)
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)

class BaseRepository(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    def __init__(self, model: Type[ModelType]):
        self.model = model
    
    def get(self, db: Session, id: int) -> Optional[ModelType]:
        return db.query(self.model).filter(self.model.id == id).first()
    
    def get_multi(
        self, db: Session, *, skip: int = 0, limit: int = 100
    ) -> List[ModelType]:
        return db.query(self.model).offset(skip).limit(limit).all()
    
    def create(self, db: Session, *, obj_in: CreateSchemaType) -> ModelType:
        obj_in_data = obj_in.dict()
        db_obj = self.model(**obj_in_data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def update(
        self,
        db: Session,
        *,
        db_obj: ModelType,
        obj_in: UpdateSchemaType
    ) -> ModelType:
        obj_data = obj_in.dict(exclude_unset=True)
        for field in obj_data:
            setattr(db_obj, field, obj_data[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def delete(self, db: Session, *, id: int) -> ModelType:
        obj = db.query(self.model).get(id)
        db.delete(obj)
        db.commit()
        return obj
```

### Service Layer : user_service.py

```python
from typing import Optional, List
from sqlalchemy.orm import Session
from app.repositories.user_repository import user_repository
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash, verify_password

class UserService:
    def create_user(self, db: Session, user_in: UserCreate) -> User:
        # Vérifier si l'email existe déjà
        if self.get_by_email(db, email=user_in.email):
            raise ValueError("Email already registered")
        
        # Hasher le mot de passe
        hashed_password = get_password_hash(user_in.password)
        
        # Créer l'utilisateur
        user = user_repository.create(
            db,
            obj_in=UserCreate(
                email=user_in.email,
                hashed_password=hashed_password,
                full_name=user_in.full_name
            )
        )
        return user
    
    def authenticate(
        self, db: Session, email: str, password: str
    ) -> Optional[User]:
        user = self.get_by_email(db, email=email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
    
    def get_by_email(self, db: Session, email: str) -> Optional[User]:
        return user_repository.get_by_email(db, email=email)
    
    def get_users(
        self, db: Session, skip: int = 0, limit: int = 100
    ) -> List[User]:
        return user_repository.get_multi(db, skip=skip, limit=limit)

user_service = UserService()
```

### Frontend : Service API

```javascript
// services/api.js
import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1'

// Créer une instance axios
const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Intercepteur pour ajouter le token
apiClient.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()
    if (authStore.token) {
      config.headers.Authorization = `Bearer ${authStore.token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Intercepteur pour gérer les erreurs
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const authStore = useAuthStore()
    
    if (error.response?.status === 401) {
      // Token expiré ou invalide
      authStore.logout()
      window.location.href = '/login'
    }
    
    return Promise.reject(error)
  }
)

export default apiClient
```

### Composable Vue.js

```javascript
// composables/useApi.js
import { ref } from 'vue'

export function useApi() {
  const loading = ref(false)
  const error = ref(null)
  
  const execute = async (apiCall) => {
    loading.value = true
    error.value = null
    
    try {
      const response = await apiCall()
      return response.data
    } catch (err) {
      error.value = err.response?.data?.detail || 'Une erreur est survenue'
      throw err
    } finally {
      loading.value = false
    }
  }
  
  return {
    loading,
    error,
    execute
  }
}
```

## 🏛️ Patterns Architecturaux

### 1. Repository Pattern
Sépare la logique d'accès aux données de la logique métier.

### 2. Service Layer Pattern
Encapsule la logique métier complexe.

### 3. Dependency Injection
Facilite les tests et réduit le couplage.

```python
from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db

@router.get("/users/")
async def read_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    skip: int = 0,
    limit: int = 100
):
    users = user_service.get_users(db, skip=skip, limit=limit)
    return users
```

### 4. Factory Pattern
Pour créer des objets complexes.

```python
class UserFactory:
    @staticmethod
    def create_user(user_type: str, **kwargs):
        if user_type == "admin":
            return AdminUser(**kwargs)
        elif user_type == "regular":
            return RegularUser(**kwargs)
        else:
            raise ValueError(f"Unknown user type: {user_type}")
```

## 📋 Bonnes Pratiques

### 1. Séparation des Préoccupations
- **Models** : Structure des données uniquement
- **Schemas** : Validation et sérialisation
- **Services** : Logique métier
- **Repositories** : Accès aux données
- **Controllers** : Orchestration

### 2. Configuration Externalisée
```python
# Utiliser des variables d'environnement
DATABASE_URL=postgresql://user:pass@localhost/db
SECRET_KEY=your-secret-key
DEBUG=false
```

### 3. Versioning d'API
```python
# api/v1/endpoints/users.py
router = APIRouter(prefix="/users", tags=["users"])

# api/v2/endpoints/users.py
router = APIRouter(prefix="/users", tags=["users"])
```

### 4. Error Handling Centralisé
```python
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse

@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)}
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )
```

## 📚 Points Clés à Retenir

1. **Architecture claire** = Code maintenable
2. **Séparation des responsabilités** = Flexibilité
3. **Patterns éprouvés** = Solutions robustes
4. **Configuration externalisée** = Déploiement facile
5. **Tests à tous les niveaux** = Confiance

## 🔗 Ressources Complémentaires

- [FastAPI Best Practices](https://github.com/zhanymkanov/fastapi-best-practices)
- [Vue.js Style Guide](https://vuejs.org/style-guide/)
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html)

---

**Prochain chapitre** : [Conventions de Nommage et Style de Code →](02-conventions-nommage.md)