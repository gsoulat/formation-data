# 🎨 Chapitre 3 : Code Propre et Lisible

## Introduction

Un code propre est un code qui se lit comme de la prose bien écrite. Il exprime clairement l'intention du développeur et minimise le temps nécessaire pour le comprendre. Ce chapitre explore les principes et pratiques pour écrire du code de qualité professionnelle.

## 📖 Les Principes du Clean Code

### 1. La Règle du Boy Scout

> "Laissez le code plus propre que vous ne l'avez trouvé" - Robert C. Martin

```python
# ❌ Avant : Code trouvé
def calc(x,y,z):
    # calcul compliqué
    return x*y+z*2-x/y if y!=0 else 0

# ✅ Après : Code amélioré
def calculate_weighted_score(base_value: float, 
                            multiplier: float, 
                            bonus: float) -> float:
    """
    Calcule un score pondéré selon la formule :
    (base * multiplier) + (bonus * 2) - (base / multiplier)
    """
    if multiplier == 0:
        return 0
    
    product = base_value * multiplier
    weighted_bonus = bonus * 2
    ratio = base_value / multiplier
    
    return product + weighted_bonus - ratio
```

### 2. DRY (Don't Repeat Yourself)

```python
# ❌ Mauvais : Duplication de code
def create_admin_user(email, password):
    if not email or '@' not in email:
        raise ValueError("Email invalide")
    if not password or len(password) < 8:
        raise ValueError("Mot de passe trop court")
    
    hashed_password = hash_password(password)
    user = User(email=email, password=hashed_password, role="admin")
    db.save(user)
    send_welcome_email(email)
    return user

def create_regular_user(email, password):
    if not email or '@' not in email:
        raise ValueError("Email invalide")
    if not password or len(password) < 8:
        raise ValueError("Mot de passe trop court")
    
    hashed_password = hash_password(password)
    user = User(email=email, password=hashed_password, role="user")
    db.save(user)
    send_welcome_email(email)
    return user

# ✅ Bon : Code réutilisable
def validate_email(email: str) -> None:
    """Valide le format d'un email."""
    if not email or '@' not in email:
        raise ValueError("Email invalide")

def validate_password(password: str) -> None:
    """Valide la force d'un mot de passe."""
    if not password or len(password) < 8:
        raise ValueError("Mot de passe trop court")

def create_user(email: str, password: str, role: str = "user") -> User:
    """Crée un utilisateur avec le rôle spécifié."""
    validate_email(email)
    validate_password(password)
    
    user = User(
        email=email,
        password=hash_password(password),
        role=role
    )
    
    db.save(user)
    send_welcome_email(email)
    
    return user

# Utilisation
admin = create_user("admin@example.com", "securepass123", role="admin")
regular = create_user("user@example.com", "password123")
```

### 3. KISS (Keep It Simple, Stupid)

```javascript
// ❌ Mauvais : Sur-ingénierie
class UserAuthenticationManager {
  constructor() {
    this.strategies = new Map()
    this.middlewares = []
    this.validators = []
  }
  
  addStrategy(name, strategy) {
    this.strategies.set(name, strategy)
  }
  
  addMiddleware(middleware) {
    this.middlewares.push(middleware)
  }
  
  async authenticate(credentials, strategyName) {
    const strategy = this.strategies.get(strategyName)
    for (const middleware of this.middlewares) {
      credentials = await middleware(credentials)
    }
    return strategy.authenticate(credentials)
  }
}

// ✅ Bon : Simple et direct
class AuthService {
  async login(email, password) {
    const user = await this.getUserByEmail(email)
    if (!user || !this.verifyPassword(password, user.hashedPassword)) {
      throw new Error('Invalid credentials')
    }
    return this.generateToken(user)
  }
  
  async getUserByEmail(email) {
    return await db.users.findOne({ email })
  }
  
  verifyPassword(password, hashedPassword) {
    return bcrypt.compare(password, hashedPassword)
  }
  
  generateToken(user) {
    return jwt.sign({ userId: user.id }, process.env.JWT_SECRET)
  }
}
```

## 🔍 Noms Expressifs

### Variables : Le Contexte Est Roi

```python
# ❌ Mauvais : Noms cryptiques
d = 86400  # Qu'est-ce que c'est ?
u = get_user()
p = u.profile if u else None

# ✅ Bon : Noms explicites
SECONDS_IN_DAY = 86400
current_user = get_user()
user_profile = current_user.profile if current_user else None

# ❌ Mauvais : Abréviations ambiguës
def calc_disc(p, d):
    return p * d

# ✅ Bon : Noms complets et clairs
def calculate_discount_amount(price: float, discount_percentage: float) -> float:
    return price * discount_percentage

# ❌ Mauvais : Noms génériques
def process_data(data):
    result = []
    for item in data:
        if item > 0:
            result.append(item * 2)
    return result

# ✅ Bon : Noms spécifiques au domaine
def double_positive_scores(scores: List[float]) -> List[float]:
    """Double tous les scores positifs."""
    doubled_scores = []
    for score in scores:
        if score > 0:
            doubled_scores.append(score * 2)
    return doubled_scores
```

### Fonctions : Verbes d'Action

```javascript
// ❌ Mauvais : Noms vagues ou trompeurs
function userData(id) {
  return db.query(`SELECT * FROM users WHERE id = ${id}`)
}

function handle(user) {
  // Que fait cette fonction ?
}

// ✅ Bon : Intentions claires
function fetchUserById(userId) {
  return db.query('SELECT * FROM users WHERE id = ?', [userId])
}

function sendWelcomeEmailToUser(user) {
  const emailContent = generateWelcomeEmail(user.name)
  return emailService.send(user.email, emailContent)
}

// Préfixes utiles pour les fonctions
function getUserName() { }      // get : récupère une valeur
function setUserName() { }      // set : définit une valeur
function isUserActive() { }     // is/has : retourne un booléen
function createUser() { }       // create : crée une nouvelle entité
function updateUser() { }       // update : modifie une entité
function deleteUser() { }       // delete : supprime une entité
function validateUser() { }     // validate : vérifie la validité
function convertToUser() { }    // convert/transform : transforme
```

## 📏 Fonctions Courtes et Focalisées

### La Règle des 20 Lignes

```python
# ❌ Mauvais : Fonction qui fait trop de choses
def process_order(order_data):
    # Validation
    if not order_data.get('items'):
        raise ValueError("Pas d'articles dans la commande")
    
    total = 0
    for item in order_data['items']:
        if item['quantity'] <= 0:
            raise ValueError("Quantité invalide")
        if item['price'] < 0:
            raise ValueError("Prix invalide")
        total += item['quantity'] * item['price']
    
    # Calcul des taxes
    tax_rate = 0.2
    if order_data.get('country') == 'US':
        tax_rate = 0.08
    elif order_data.get('country') == 'UK':
        tax_rate = 0.15
    
    tax_amount = total * tax_rate
    total_with_tax = total + tax_amount
    
    # Calcul des frais de livraison
    shipping = 10
    if total > 100:
        shipping = 0
    elif order_data.get('express'):
        shipping = 25
    
    final_total = total_with_tax + shipping
    
    # Sauvegarde en base
    order = Order(
        items=order_data['items'],
        subtotal=total,
        tax=tax_amount,
        shipping=shipping,
        total=final_total
    )
    db.save(order)
    
    # Envoi d'email
    send_email(
        to=order_data['email'],
        subject="Confirmation de commande",
        body=f"Votre commande de {final_total}€ a été confirmée"
    )
    
    return order

# ✅ Bon : Fonctions séparées avec responsabilité unique
def validate_order_items(items: List[dict]) -> None:
    """Valide que tous les articles de la commande sont corrects."""
    if not items:
        raise ValueError("Pas d'articles dans la commande")
    
    for item in items:
        if item['quantity'] <= 0:
            raise ValueError(f"Quantité invalide pour {item['name']}")
        if item['price'] < 0:
            raise ValueError(f"Prix invalide pour {item['name']}")

def calculate_subtotal(items: List[dict]) -> float:
    """Calcule le sous-total de la commande."""
    return sum(item['quantity'] * item['price'] for item in items)

def get_tax_rate(country: str) -> float:
    """Retourne le taux de taxe selon le pays."""
    tax_rates = {
        'US': 0.08,
        'UK': 0.15,
        'FR': 0.20
    }
    return tax_rates.get(country, 0.20)  # Défaut 20%

def calculate_shipping(subtotal: float, is_express: bool = False) -> float:
    """Calcule les frais de livraison."""
    if subtotal > 100:
        return 0
    return 25 if is_express else 10

def create_order(order_data: dict) -> Order:
    """Crée et sauvegarde une nouvelle commande."""
    # Validation
    validate_order_items(order_data['items'])
    
    # Calculs
    subtotal = calculate_subtotal(order_data['items'])
    tax_rate = get_tax_rate(order_data.get('country', 'FR'))
    tax_amount = subtotal * tax_rate
    shipping = calculate_shipping(subtotal, order_data.get('express', False))
    
    # Création de la commande
    order = Order(
        items=order_data['items'],
        subtotal=subtotal,
        tax=tax_amount,
        shipping=shipping,
        total=subtotal + tax_amount + shipping
    )
    
    # Sauvegarde et notification
    db.save(order)
    notify_order_confirmation(order, order_data['email'])
    
    return order

def notify_order_confirmation(order: Order, email: str) -> None:
    """Envoie un email de confirmation de commande."""
    send_email(
        to=email,
        subject="Confirmation de commande",
        body=f"Votre commande #{order.id} de {order.total}€ a été confirmée"
    )
```

## 🎯 Gestion des Erreurs

### Fail Fast

```python
# ❌ Mauvais : Erreurs silencieuses
def divide(a, b):
    try:
        return a / b
    except:
        return None  # Masque l'erreur

# ✅ Bon : Erreurs explicites
def divide(dividend: float, divisor: float) -> float:
    """Divise deux nombres avec gestion d'erreur explicite."""
    if divisor == 0:
        raise ValueError("Division par zéro impossible")
    return dividend / divisor

# Ou avec une approche plus sophistiquée
from typing import Union, Optional
from dataclasses import dataclass

@dataclass
class DivisionError:
    message: str

def safe_divide(dividend: float, 
                divisor: float) -> Union[float, DivisionError]:
    """Divise deux nombres en retournant soit le résultat, soit une erreur."""
    if divisor == 0:
        return DivisionError("Division par zéro impossible")
    return dividend / divisor

# Utilisation
result = safe_divide(10, 2)
if isinstance(result, DivisionError):
    print(f"Erreur : {result.message}")
else:
    print(f"Résultat : {result}")
```

### Exceptions Personnalisées

```python
# ✅ Bon : Exceptions métier spécifiques
class BusinessError(Exception):
    """Classe de base pour les erreurs métier."""
    pass

class InsufficientFundsError(BusinessError):
    """Levée quand un compte n'a pas assez de fonds."""
    def __init__(self, account_id: str, required: float, available: float):
        self.account_id = account_id
        self.required = required
        self.available = available
        super().__init__(
            f"Fonds insuffisants sur le compte {account_id}: "
            f"requis={required}, disponible={available}"
        )

class AccountNotFoundError(BusinessError):
    """Levée quand un compte n'existe pas."""
    def __init__(self, account_id: str):
        self.account_id = account_id
        super().__init__(f"Compte non trouvé: {account_id}")

# Utilisation
def transfer_money(from_account_id: str, 
                  to_account_id: str, 
                  amount: float) -> None:
    from_account = get_account(from_account_id)
    if not from_account:
        raise AccountNotFoundError(from_account_id)
    
    to_account = get_account(to_account_id)
    if not to_account:
        raise AccountNotFoundError(to_account_id)
    
    if from_account.balance < amount:
        raise InsufficientFundsError(
            from_account_id, 
            amount, 
            from_account.balance
        )
    
    # Effectuer le transfert
    from_account.withdraw(amount)
    to_account.deposit(amount)
```

## 💬 Commentaires et Documentation

### Quand Commenter

```python
# ❌ Mauvais : Commentaires évidents
# Incrémente i de 1
i += 1

# Retourne True si l'utilisateur est actif
def is_user_active(user):
    return user.is_active

# ✅ Bon : Commentaires qui expliquent le "pourquoi"
# Utilisation d'une limite de 1000 pour éviter les attaques DoS
MAX_ITEMS_PER_REQUEST = 1000

# L'algorithme de Luhn est utilisé pour valider les numéros de carte
# Voir : https://en.wikipedia.org/wiki/Luhn_algorithm
def validate_credit_card(number: str) -> bool:
    # Implementation de l'algorithme de Luhn
    pass

# Workaround pour le bug #1234 dans la librairie externe
# TODO: Retirer quand la librairie sera mise à jour
time.sleep(0.1)
```

### Documentation des APIs

```python
from typing import List, Optional
from datetime import datetime

class UserService:
    def search_users(
        self,
        query: str,
        active_only: bool = True,
        limit: int = 50,
        offset: int = 0
    ) -> List[User]:
        """
        Recherche des utilisateurs selon les critères donnés.
        
        Cette méthode utilise une recherche full-text sur les champs
        nom, email et description. Les résultats sont triés par
        pertinence.
        
        Args:
            query: Terme de recherche (min 3 caractères)
            active_only: Si True, ne retourne que les utilisateurs actifs
            limit: Nombre maximum de résultats (max 100)
            offset: Décalage pour la pagination
        
        Returns:
            Liste des utilisateurs correspondant aux critères
        
        Raises:
            ValueError: Si query a moins de 3 caractères
            ValueError: Si limit > 100
        
        Example:
            >>> service = UserService()
            >>> users = service.search_users("john", limit=10)
            >>> print(f"Trouvé {len(users)} utilisateurs")
        
        Note:
            La recherche est insensible à la casse et supporte
            les caractères accentués.
        """
        if len(query) < 3:
            raise ValueError("La recherche requiert au moins 3 caractères")
        
        if limit > 100:
            raise ValueError("La limite ne peut pas dépasser 100")
        
        # Implementation...
```

## 🔄 Refactoring Continu

### Signes qu'un Refactoring est Nécessaire

1. **Code Smell** : Duplication, longues méthodes, grandes classes
2. **Difficile à tester** : Trop de dépendances, effets de bord
3. **Difficile à comprendre** : Noms peu clairs, logique complexe
4. **Difficile à modifier** : Changement = casse partout

### Exemple de Refactoring Progressif

```javascript
// Version 1 : Code initial
function getPrice(item) {
  let price = item.price
  if (item.type === 'book') {
    price = price * 0.9
  } else if (item.type === 'food') {
    price = price * 0.95
  } else if (item.type === 'electronics') {
    price = price * 0.8
  }
  
  if (item.quantity > 10) {
    price = price * 0.9
  }
  
  return price
}

// Version 2 : Extraction des constantes
const DISCOUNTS = {
  book: 0.9,
  food: 0.95,
  electronics: 0.8
}

const BULK_DISCOUNT = 0.9
const BULK_THRESHOLD = 10

function getPrice(item) {
  let price = item.price
  
  const typeDiscount = DISCOUNTS[item.type] || 1
  price = price * typeDiscount
  
  if (item.quantity > BULK_THRESHOLD) {
    price = price * BULK_DISCOUNT
  }
  
  return price
}

// Version 3 : Séparation des responsabilités
class PricingService {
  constructor(discountRules) {
    this.discountRules = discountRules
  }
  
  calculatePrice(item) {
    const basePrice = item.price
    const discounts = this.getApplicableDiscounts(item)
    return this.applyDiscounts(basePrice, discounts)
  }
  
  getApplicableDiscounts(item) {
    const discounts = []
    
    // Remise par type
    const typeDiscount = this.discountRules.byType[item.type]
    if (typeDiscount) {
      discounts.push(typeDiscount)
    }
    
    // Remise quantité
    if (item.quantity > this.discountRules.bulkThreshold) {
      discounts.push(this.discountRules.bulkDiscount)
    }
    
    return discounts
  }
  
  applyDiscounts(price, discounts) {
    return discounts.reduce((p, discount) => p * discount, price)
  }
}

// Configuration
const pricingService = new PricingService({
  byType: {
    book: 0.9,
    food: 0.95,
    electronics: 0.8
  },
  bulkThreshold: 10,
  bulkDiscount: 0.9
})

// Utilisation
const price = pricingService.calculatePrice(item)
```

## 📊 Métriques de Code Propre

### Complexité Cyclomatique

Maintenez la complexité cyclomatique faible (< 10) :

```python
# ❌ Mauvais : Complexité élevée
def process_payment(payment):
    if payment.amount > 0:
        if payment.currency == 'EUR':
            if payment.method == 'card':
                if validate_card(payment.card):
                    if check_balance(payment.card, payment.amount):
                        return charge_card(payment.card, payment.amount)
                    else:
                        return "Insufficient funds"
                else:
                    return "Invalid card"
            elif payment.method == 'paypal':
                # ... plus de conditions imbriquées
    else:
        return "Invalid amount"

# ✅ Bon : Complexité réduite
def process_payment(payment):
    validators = [
        validate_amount,
        validate_currency,
        validate_payment_method,
        validate_payment_details
    ]
    
    for validator in validators:
        error = validator(payment)
        if error:
            return error
    
    return execute_payment(payment)
```

## 🎯 Exercices Pratiques

### Exercice 1 : Refactoring de Noms
Améliorez les noms dans ce code :

```python
def fn(lst):
    r = []
    for i in lst:
        if i > 0:
            r.append(i)
    return r
```

### Exercice 2 : Simplification de Fonction
Refactorisez cette fonction complexe en plusieurs fonctions simples :

```javascript
function processUser(userData) {
  // validation
  if (!userData.email || !userData.email.includes('@')) {
    return { error: 'Invalid email' }
  }
  if (!userData.password || userData.password.length < 8) {
    return { error: 'Password too short' }
  }
  
  // transformation
  userData.email = userData.email.toLowerCase()
  userData.createdAt = new Date()
  
  // save
  const user = db.save(userData)
  
  // send email
  emailService.send(userData.email, 'Welcome!')
  
  return { success: true, user }
}
```

### Exercice 3 : Documentation
Ajoutez une documentation complète à cette classe :

```python
class Cache:
    def __init__(self, max_size=100):
        self.max_size = max_size
        self.items = {}
        
    def get(self, key):
        return self.items.get(key)
    
    def set(self, key, value):
        if len(self.items) >= self.max_size:
            self.items.pop(next(iter(self.items)))
        self.items[key] = value
```

## 📚 Points Clés à Retenir

1. **Code = Communication** : Écrivez pour les humains, pas les machines
2. **Simplicité > Complexité** : La solution simple est souvent la meilleure
3. **Refactoring continu** : Améliorez le code à chaque modification
4. **Tests = Documentation vivante** : Les tests montrent comment utiliser le code
5. **Boy Scout Rule** : Laissez le code meilleur que trouvé

## 🔗 Ressources Complémentaires

- [Clean Code - Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Refactoring - Martin Fowler](https://refactoring.com/)
- [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)
- [Code Complete - Steve McConnell](https://www.amazon.com/Code-Complete-Practical-Handbook-Construction/dp/0735619670)

---

**Prochain chapitre** : [Gestion de Version avec Git →](04-git-version-control.md)