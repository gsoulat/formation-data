# 🔤 Chapitre 2 : Conventions de Nommage et Style de Code

## Introduction

Les conventions de nommage et le style de code sont essentiels pour la lisibilité et la maintenabilité. Un code bien nommé se lit comme de la prose et communique clairement son intention. Ce chapitre couvre les conventions pour Python (PEP 8) et JavaScript/Vue.js.

## 🐍 Python : PEP 8 et Au-delà

### Vue d'ensemble PEP 8

PEP 8 est le guide de style officiel pour Python. Il définit les conventions que tous les développeurs Python devraient suivre.

### Nommage en Python

#### Variables et Fonctions : snake_case

```python
# ✅ Bon
user_name = "Alice"
total_amount = 150.50
is_active = True

def calculate_total_price(base_price, tax_rate):
    return base_price * (1 + tax_rate)

def get_user_by_email(email):
    # Implementation
    pass

# ❌ Mauvais
userName = "Alice"  # camelCase
TotalAmount = 150.50  # PascalCase
ISACTIVE = True  # UPPER_CASE pour une variable

def CalculateTotalPrice(basePrice, taxRate):  # PascalCase
    return basePrice * (1 + taxRate)
```

#### Classes : PascalCase

```python
# ✅ Bon
class UserAccount:
    pass

class HTTPException:
    pass

class DatabaseConnection:
    pass

# ❌ Mauvais
class user_account:  # snake_case
    pass

class httpException:  # camelCase
    pass
```

#### Constantes : UPPER_SNAKE_CASE

```python
# ✅ Bon
MAX_CONNECTIONS = 100
DEFAULT_TIMEOUT = 30
API_VERSION = "v1"
DATABASE_URL = "postgresql://localhost/mydb"

# ❌ Mauvais
max_connections = 100  # Ressemble à une variable
DefaultTimeout = 30    # PascalCase
```

#### Méthodes Privées : Préfixe underscore

```python
class UserService:
    def get_user(self, user_id):
        # Méthode publique
        return self._fetch_from_database(user_id)
    
    def _fetch_from_database(self, user_id):
        # Méthode privée (convention)
        pass
    
    def __validate_input(self, data):
        # Name mangling (très rare)
        pass
```

### Organisation des Imports

```python
# ✅ Bon : Ordre correct des imports
# 1. Bibliothèque standard
import os
import sys
from datetime import datetime
from typing import List, Optional, Dict

# 2. Bibliothèques tierces
import requests
import numpy as np
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine

# 3. Imports locaux
from app.core.config import settings
from app.models.user import User
from app.services.email import EmailService

# ❌ Mauvais : Imports mélangés
from app.models.user import User
import os
from fastapi import FastAPI
import sys
from datetime import datetime
```

### Formatage du Code

#### Indentation : 4 espaces

```python
# ✅ Bon
def process_data(data):
    if data:
        for item in data:
            if item.is_valid():
                process_item(item)

# ❌ Mauvais : 2 espaces ou tabs
def process_data(data):
  if data:
    for item in data:
      if item.is_valid():
        process_item(item)
```

#### Longueur de ligne : 79 caractères

```python
# ✅ Bon : Ligne coupée proprement
long_function_name = some_function(
    argument_one, argument_two,
    argument_three, argument_four
)

# Alternative avec backslash
total = first_variable + second_variable + \
        third_variable + fourth_variable

# ❌ Mauvais : Ligne trop longue
long_function_name = some_function(argument_one, argument_two, argument_three, argument_four, argument_five)
```

#### Espacement

```python
# ✅ Bon : Espaces autour des opérateurs
x = 5
y = x * 2 + 3
values = [1, 2, 3, 4]

# ✅ Bon : Pas d'espace dans les appels de fonction
result = function(arg1, arg2)
dictionary = {"key": "value"}

# ❌ Mauvais
x=5
y = x*2+3
values = [ 1,2,3,4 ]
result = function( arg1, arg2 )
```

### Docstrings et Commentaires

```python
def calculate_discount(price: float, discount_percent: float) -> float:
    """
    Calcule le prix après application d'une remise.
    
    Args:
        price: Le prix initial du produit
        discount_percent: Le pourcentage de remise (0-100)
    
    Returns:
        Le prix final après remise
    
    Raises:
        ValueError: Si le pourcentage est négatif ou supérieur à 100
    
    Example:
        >>> calculate_discount(100, 20)
        80.0
    """
    if not 0 <= discount_percent <= 100:
        raise ValueError("Le pourcentage doit être entre 0 et 100")
    
    # Calcul du montant de la remise
    discount_amount = price * (discount_percent / 100)
    
    # Retour du prix final
    return price - discount_amount


class User:
    """
    Représente un utilisateur du système.
    
    Attributes:
        email: L'adresse email unique de l'utilisateur
        name: Le nom complet de l'utilisateur
        is_active: Indique si le compte est actif
    """
    
    def __init__(self, email: str, name: str):
        """Initialise un nouvel utilisateur."""
        self.email = email
        self.name = name
        self.is_active = True
```

## 🌐 JavaScript et Vue.js

### Conventions JavaScript Modernes

#### Variables : camelCase avec const/let

```javascript
// ✅ Bon
const userName = 'Alice'
const maxRetries = 3
let currentCount = 0
const isLoggedIn = true

// Objets
const userConfig = {
  firstName: 'John',
  lastName: 'Doe',
  emailAddress: 'john@example.com'
}

// ❌ Mauvais
var user_name = 'Alice'  // snake_case et var
const MaxRetries = 3     // PascalCase
const ISLOGGEDIN = true  // UPPER_CASE
```

#### Fonctions : camelCase

```javascript
// ✅ Bon
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0)
}

const getUserById = async (userId) => {
  const response = await api.get(`/users/${userId}`)
  return response.data
}

// Méthodes d'objet
const userService = {
  async createUser(userData) {
    // Implementation
  },
  
  validateEmail(email) {
    // Implementation
  }
}

// ❌ Mauvais
function Calculate_Total(items) { }  // Snake_Case
const GetUserById = async (userId) => { }  // PascalCase
```

#### Classes et Constructeurs : PascalCase

```javascript
// ✅ Bon
class UserAccount {
  constructor(email, password) {
    this.email = email
    this.password = password
  }
}

class HTTPClient {
  async get(url) {
    // Implementation
  }
}

// Composants Vue
export default {
  name: 'UserProfile'
}

// ❌ Mauvais
class userAccount { }  // camelCase
class http_client { }  // snake_case
```

#### Constantes : UPPER_SNAKE_CASE

```javascript
// ✅ Bon
const API_BASE_URL = 'https://api.example.com'
const MAX_FILE_SIZE = 5 * 1024 * 1024  // 5MB
const STATUS_CODES = {
  OK: 200,
  NOT_FOUND: 404,
  SERVER_ERROR: 500
}

// Enum-like objects
const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  GUEST: 'guest'
}

// ❌ Mauvais
const apiBaseUrl = 'https://api.example.com'  // camelCase
const MAXFILESIZE = 5 * 1024 * 1024          // Pas de séparation
```

### Conventions Vue.js Spécifiques

#### Noms de Composants

```vue
<!-- ✅ Bon : PascalCase dans les templates et scripts -->
<template>
  <div>
    <UserProfile :user="currentUser" />
    <BaseButton @click="handleClick">
      Click me
    </BaseButton>
  </div>
</template>

<script>
import UserProfile from '@/components/UserProfile.vue'
import BaseButton from '@/components/BaseButton.vue'

export default {
  name: 'UserDashboard',
  components: {
    UserProfile,
    BaseButton
  }
}
</script>

<!-- ❌ Mauvais : kebab-case dans les imports -->
<script>
import userProfile from '@/components/user-profile.vue'  // Mauvais
</script>
```

#### Structure de Fichiers Composants

```
components/
├── base/                    # Composants de base réutilisables
│   ├── BaseButton.vue
│   ├── BaseInput.vue
│   └── BaseModal.vue
├── user/                    # Composants domaine utilisateur
│   ├── UserList.vue
│   ├── UserCard.vue
│   └── UserForm.vue
└── layout/                  # Composants de layout
    ├── TheHeader.vue        # 'The' prefix pour singletons
    ├── TheFooter.vue
    └── TheSidebar.vue
```

#### Props et Events

```vue
<script setup>
// ✅ Bon : Props en camelCase
const props = defineProps({
  userId: {
    type: Number,
    required: true
  },
  userName: {
    type: String,
    default: 'Anonymous'
  },
  isActive: {
    type: Boolean,
    default: true
  }
})

// ✅ Bon : Events en kebab-case
const emit = defineEmits([
  'update:modelValue',
  'user-deleted',
  'form-submitted'
])

// Utilisation
emit('user-deleted', userId)
</script>

<!-- Dans le template parent -->
<UserForm
  :user-id="123"
  :user-name="name"
  :is-active="active"
  @user-deleted="handleUserDeleted"
  @form-submitted="handleFormSubmit"
/>
```

### Formatage JavaScript/Vue

#### Indentation : 2 espaces

```javascript
// ✅ Bon
function processUser(user) {
  if (user.isActive) {
    return {
      ...user,
      lastSeen: new Date()
    }
  }
  return user
}

// Vue component
export default {
  data() {
    return {
      users: [],
      loading: false
    }
  },
  methods: {
    async fetchUsers() {
      this.loading = true
      try {
        const response = await api.getUsers()
        this.users = response.data
      } finally {
        this.loading = false
      }
    }
  }
}
```

#### Point-virgules : Optionnels mais cohérents

```javascript
// Style 1 : Sans point-virgules (recommandé avec Prettier)
const name = 'Alice'
const age = 25

function greet(name) {
  return `Hello, ${name}!`
}

// Style 2 : Avec point-virgules
const name = 'Alice';
const age = 25;

function greet(name) {
  return `Hello, ${name}!`;
}
```

## 📁 Nommage de Fichiers et Dossiers

### Backend Python

```
backend/
├── app/
│   ├── __init__.py          # Toujours en minuscules
│   ├── main.py
│   ├── config.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py          # snake_case
│   │   └── product.py
│   ├── schemas/
│   │   ├── user_schema.py   # Optionnel: suffixe _schema
│   │   └── product_schema.py
│   └── services/
│       ├── email_service.py # Suffixe _service pour clarté
│       └── auth_service.py
└── tests/
    ├── test_user.py         # Préfixe test_
    └── test_product.py
```

### Frontend Vue.js

```
frontend/
├── src/
│   ├── components/
│   │   ├── BaseButton.vue      # PascalCase pour composants
│   │   ├── UserProfile.vue
│   │   └── ProductList.vue
│   ├── views/
│   │   ├── HomeView.vue        # Suffixe View pour les pages
│   │   ├── LoginView.vue
│   │   └── DashboardView.vue
│   ├── utils/
│   │   ├── validators.js       # camelCase pour JS
│   │   ├── formatters.js
│   │   └── api-client.js       # kebab-case acceptable
│   └── assets/
│       ├── images/
│       │   └── logo-dark.png   # kebab-case pour assets
│       └── styles/
│           └── main.scss
```

## 🛠️ Outils d'Automatisation

### Python : Black et Ruff

```bash
# Installation
pip install black ruff

# Configuration dans pyproject.toml
[tool.black]
line-length = 88
target-version = ['py311']
include = '\.pyi?$'

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W"]
ignore = ["E501"]  # Line too long (handled by Black)

# Utilisation
black .
ruff check . --fix
```

### JavaScript : ESLint et Prettier

```javascript
// .eslintrc.js
module.exports = {
  root: true,
  env: {
    node: true,
    browser: true,
    es2022: true
  },
  extends: [
    'eslint:recommended',
    'plugin:vue/vue3-recommended',
    'prettier'
  ],
  rules: {
    'vue/component-name-in-template-casing': ['error', 'PascalCase'],
    'vue/prop-name-casing': ['error', 'camelCase'],
    'camelcase': ['error', { properties: 'always' }],
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off'
  }
}

// .prettierrc
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80,
  "arrowParens": "always"
}
```

## 📋 Tableau Récapitulatif

| Contexte | Python | JavaScript/Vue |
|----------|---------|----------------|
| Variables | `snake_case` | `camelCase` |
| Fonctions | `snake_case` | `camelCase` |
| Classes | `PascalCase` | `PascalCase` |
| Constantes | `UPPER_SNAKE_CASE` | `UPPER_SNAKE_CASE` |
| Fichiers | `snake_case.py` | `PascalCase.vue` / `kebab-case.js` |
| Modules/Packages | `snake_case` | `kebab-case` |
| Props Vue | - | `camelCase` (script) / `kebab-case` (template) |
| Events Vue | - | `kebab-case` |
| CSS Classes | - | `kebab-case` |

## 🎯 Exercices Pratiques

### Exercice 1 : Refactoring de Noms
Refactorisez ce code en appliquant les bonnes conventions :

```python
# Avant
def GET_USER_DATA(USER_ID):
    User_Name = fetchFromDB(USER_ID)
    return User_Name

class user_manager:
    def CreateUser(self, Email, passWord):
        # Code
        pass
```

### Exercice 2 : Configuration des Outils
1. Configurez Black, Ruff, ESLint et Prettier dans un projet
2. Créez des scripts npm/pip pour automatiser le formatage
3. Configurez les pre-commit hooks

### Exercice 3 : Conventions Projet
Créez un fichier CONTRIBUTING.md documentant les conventions de votre projet.

## 📚 Points Clés à Retenir

1. **Cohérence** > Préférence personnelle
2. **Lisibilité** > Concision
3. **Conventions standards** = Moins de friction en équipe
4. **Outils automatiques** = Gain de temps
5. **Documentation** des choix non standards

## 🔗 Ressources Complémentaires

- [PEP 8 - Style Guide for Python](https://pep8.org/)
- [Vue.js Style Guide Officiel](https://vuejs.org/style-guide/)
- [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Black - The Uncompromising Code Formatter](https://black.readthedocs.io/)

---

**Prochain chapitre** : [Code Propre et Lisible →](03-code-propre.md)