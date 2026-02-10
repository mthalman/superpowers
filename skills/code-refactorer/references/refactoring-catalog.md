# Refactoring Catalog

Detailed before/after examples for common refactorings. Each entry shows the smell, the refactoring, and a concise example.

## Table of Contents

1. [Extract Method](#extract-method)
2. [Extract Class](#extract-class)
3. [Introduce Parameter Object](#introduce-parameter-object)
4. [Replace Conditional with Polymorphism](#replace-conditional-with-polymorphism)
5. [Replace Magic Numbers with Constants](#replace-magic-numbers-with-constants)
6. [Guard Clauses](#guard-clauses)
7. [Decompose Boolean Expression](#decompose-boolean-expression)
8. [Move Method](#move-method)
9. [Remove Dead Code](#remove-dead-code)
10. [Rename for Clarity](#rename-for-clarity)
11. [Replace Primitive with Object](#replace-primitive-with-object)
12. [Extract Interface / Dependency Injection](#extract-interface--dependency-injection)
13. [Unify Near-Duplicate Code](#unify-near-duplicate-code)
14. [Cross-File Pattern Consolidation](#cross-file-pattern-consolidation)

---

## Extract Method

**Smell:** Long method doing multiple things.

Before:
```python
def process_order(order):
    # validate
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Negative total")
    # apply discount
    if order.customer.is_premium:
        order.total *= 0.9
    # send confirmation
    email = f"Order {order.id} confirmed for ${order.total:.2f}"
    send_email(order.customer.email, email)
```

After:
```python
def process_order(order):
    validate_order(order)
    apply_discount(order)
    send_confirmation(order)

def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Negative total")

def apply_discount(order):
    if order.customer.is_premium:
        order.total *= 0.9

def send_confirmation(order):
    email = f"Order {order.id} confirmed for ${order.total:.2f}"
    send_email(order.customer.email, email)
```

---

## Extract Class

**Smell:** A class with multiple unrelated responsibilities.

Before:
```typescript
class User {
  name: string;
  email: string;
  street: string;
  city: string;
  zip: string;
  
  fullAddress(): string {
    return `${this.street}, ${this.city} ${this.zip}`;
  }
  
  validateZip(): boolean {
    return /^\d{5}$/.test(this.zip);
  }
}
```

After:
```typescript
class Address {
  constructor(public street: string, public city: string, public zip: string) {}
  
  full(): string {
    return `${this.street}, ${this.city} ${this.zip}`;
  }
  
  isValidZip(): boolean {
    return /^\d{5}$/.test(this.zip);
  }
}

class User {
  name: string;
  email: string;
  address: Address;
}
```

---

## Introduce Parameter Object

**Smell:** Multiple parameters that always travel together.

Before:
```java
public List<Event> findEvents(Date start, Date end, String timezone, boolean includeRecurring) { ... }
public void exportEvents(Date start, Date end, String timezone, boolean includeRecurring, String format) { ... }
```

After:
```java
public record DateRange(Date start, Date end, String timezone, boolean includeRecurring) {}

public List<Event> findEvents(DateRange range) { ... }
public void exportEvents(DateRange range, String format) { ... }
```

---

## Replace Conditional with Polymorphism

**Smell:** Repeated switch/if-else on a type discriminator.

Before:
```python
def calculate_area(shape):
    if shape.type == "circle":
        return math.pi * shape.radius ** 2
    elif shape.type == "rectangle":
        return shape.width * shape.height
    elif shape.type == "triangle":
        return 0.5 * shape.base * shape.height
    else:
        raise ValueError(f"Unknown shape: {shape.type}")
```

After:
```python
class Circle:
    def __init__(self, radius):
        self.radius = radius
    def area(self):
        return math.pi * self.radius ** 2

class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    def area(self):
        return self.width * self.height

class Triangle:
    def __init__(self, base, height):
        self.base = base
        self.height = height
    def area(self):
        return 0.5 * self.base * self.height
```

---

## Replace Magic Numbers with Constants

**Smell:** Unexplained literal values in logic.

Before:
```javascript
if (response.status === 429) {
  await sleep(3600000);
}
if (retries > 3) {
  throw new Error("Failed");
}
```

After:
```javascript
const HTTP_TOO_MANY_REQUESTS = 429;
const RATE_LIMIT_COOLDOWN_MS = 3_600_000;
const MAX_RETRIES = 3;

if (response.status === HTTP_TOO_MANY_REQUESTS) {
  await sleep(RATE_LIMIT_COOLDOWN_MS);
}
if (retries > MAX_RETRIES) {
  throw new Error("Failed");
}
```

---

## Guard Clauses

**Smell:** Deeply nested conditionals.

Before:
```go
func processPayment(payment Payment) error {
    if payment.Amount > 0 {
        if payment.Currency != "" {
            if payment.IsAuthorized {
                return executePayment(payment)
            } else {
                return errors.New("payment not authorized")
            }
        } else {
            return errors.New("missing currency")
        }
    } else {
        return errors.New("invalid amount")
    }
}
```

After:
```go
func processPayment(payment Payment) error {
    if payment.Amount <= 0 {
        return errors.New("invalid amount")
    }
    if payment.Currency == "" {
        return errors.New("missing currency")
    }
    if !payment.IsAuthorized {
        return errors.New("payment not authorized")
    }
    return executePayment(payment)
}
```

---

## Decompose Boolean Expression

**Smell:** Complex, hard-to-read boolean conditions.

Before:
```python
if (user.age >= 18 and user.country in ALLOWED_COUNTRIES
    and not user.is_banned and user.email_verified
    and (user.subscription == "pro" or user.trial_remaining > 0)):
    grant_access(user)
```

After:
```python
def is_eligible(user):
    return user.age >= 18 and user.country in ALLOWED_COUNTRIES

def is_in_good_standing(user):
    return not user.is_banned and user.email_verified

def has_active_plan(user):
    return user.subscription == "pro" or user.trial_remaining > 0

if is_eligible(user) and is_in_good_standing(user) and has_active_plan(user):
    grant_access(user)
```

---

## Move Method

**Smell:** A method that uses another class's data more than its own (Feature Envy).

Before:
```typescript
class OrderPrinter {
  printSummary(order: Order): string {
    const subtotal = order.items.reduce((sum, i) => sum + i.price * i.qty, 0);
    const tax = subtotal * order.taxRate;
    const total = subtotal + tax;
    return `Items: ${order.items.length}, Total: $${total.toFixed(2)}`;
  }
}
```

After:
```typescript
class Order {
  get subtotal(): number {
    return this.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  }
  get tax(): number {
    return this.subtotal * this.taxRate;
  }
  get total(): number {
    return this.subtotal + this.tax;
  }
  summary(): string {
    return `Items: ${this.items.length}, Total: $${this.total.toFixed(2)}`;
  }
}
```

---

## Remove Dead Code

**Smell:** Unused functions, unreachable branches, commented-out code.

Before:
```python
def calculate_price(item):
    # Old pricing logic - keeping just in case
    # price = item.base * 1.1 + get_legacy_fee(item)
    price = item.base * item.multiplier
    return price

def get_legacy_fee(item):
    """No longer called anywhere."""
    return item.weight * 0.05
```

After:
```python
def calculate_price(item):
    return item.base * item.multiplier
```

---

## Rename for Clarity

**Smell:** Ambiguous names that require reading the implementation to understand.

Before:
```javascript
function proc(d, f) {
  const r = [];
  for (const x of d) {
    if (f(x)) r.push(transform(x));
  }
  return r;
}
```

After:
```javascript
function filterAndTransform(items, predicate) {
  const results = [];
  for (const item of items) {
    if (predicate(item)) results.push(transform(item));
  }
  return results;
}
```

---

## Replace Primitive with Object

**Smell:** A primitive value (string, number) carrying domain meaning and scattered validation.

Before:
```python
def send_money(amount: float, currency: str):
    if amount < 0:
        raise ValueError("Negative amount")
    if currency not in ("USD", "EUR", "GBP"):
        raise ValueError("Unsupported currency")
    # ... logic using amount and currency separately
```

After:
```python
@dataclass(frozen=True)
class Money:
    amount: float
    currency: str
    
    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Negative amount")
        if self.currency not in ("USD", "EUR", "GBP"):
            raise ValueError("Unsupported currency")

def send_money(money: Money):
    # ... logic using money object
```

---

## Extract Interface / Dependency Injection

**Smell:** Hard-coded dependencies making code untestable.

Before:
```typescript
class OrderService {
  async placeOrder(order: Order): Promise<void> {
    const db = new PostgresDatabase();
    await db.save(order);
    const mailer = new SmtpMailer();
    await mailer.send(order.customer.email, "Order placed");
  }
}
```

After:
```typescript
interface Database {
  save(entity: unknown): Promise<void>;
}
interface Mailer {
  send(to: string, body: string): Promise<void>;
}

class OrderService {
  constructor(private db: Database, private mailer: Mailer) {}

  async placeOrder(order: Order): Promise<void> {
    await this.db.save(order);
    await this.mailer.send(order.customer.email, "Order placed");
  }
}
```

---

## Unify Near-Duplicate Code

**Smell:** Two or more code blocks that are structurally similar but not textually identical — they follow the same pattern with minor variations in names, types, constants, or operations.

### How to Detect Near-Duplicates

Look for functions/methods that:
- Have the same control flow structure (same sequence of if/for/try blocks)
- Differ only in specific values, field names, or type references
- Perform analogous operations on different entities
- Were likely copy-pasted and then modified

### Strategy: Parameterize the Differences

Identify exactly what varies between the duplicates. Extract a shared function/template that accepts the varying parts as parameters, callbacks, or generics.

### Example 1: Parameterize differing values

Before:
```python
def export_users_csv(users):
    rows = []
    for user in users:
        if user.is_active:
            rows.append(f"{user.name},{user.email}")
    write_file("users.csv", "\n".join(rows))

def export_products_csv(products):
    rows = []
    for product in products:
        if product.is_active:
            rows.append(f"{product.name},{product.price}")
    write_file("products.csv", "\n".join(rows))
```

After:
```python
def export_csv(items, filename, format_row, is_included=lambda x: x.is_active):
    rows = [format_row(item) for item in items if is_included(item)]
    write_file(filename, "\n".join(rows))

# Usage
export_csv(users, "users.csv", lambda u: f"{u.name},{u.email}")
export_csv(products, "products.csv", lambda p: f"{p.name},{p.price}")
```

### Example 2: Unify structurally similar API handlers

Before:
```typescript
async function createUser(req: Request, res: Response) {
  try {
    validate(req.body, userSchema);
    const user = await db.users.create(req.body);
    await audit.log("user_created", user.id);
    res.status(201).json(user);
  } catch (e) {
    if (e instanceof ValidationError) res.status(400).json({ error: e.message });
    else res.status(500).json({ error: "Internal error" });
  }
}

async function createProject(req: Request, res: Response) {
  try {
    validate(req.body, projectSchema);
    const project = await db.projects.create(req.body);
    await audit.log("project_created", project.id);
    res.status(201).json(project);
  } catch (e) {
    if (e instanceof ValidationError) res.status(400).json({ error: e.message });
    else res.status(500).json({ error: "Internal error" });
  }
}
```

After:
```typescript
function createEntityHandler(schema: Schema, repo: Repository, auditEvent: string) {
  return async (req: Request, res: Response) => {
    try {
      validate(req.body, schema);
      const entity = await repo.create(req.body);
      await audit.log(auditEvent, entity.id);
      res.status(201).json(entity);
    } catch (e) {
      if (e instanceof ValidationError) res.status(400).json({ error: e.message });
      else res.status(500).json({ error: "Internal error" });
    }
  };
}

const createUser = createEntityHandler(userSchema, db.users, "user_created");
const createProject = createEntityHandler(projectSchema, db.projects, "project_created");
```

### Example 3: Unify with generics (statically typed languages)

Before:
```java
public UserDTO toUserDTO(User user) {
    UserDTO dto = new UserDTO();
    dto.setId(user.getId());
    dto.setName(user.getName());
    dto.setCreatedAt(user.getCreatedAt());
    return dto;
}

public ProjectDTO toProjectDTO(Project project) {
    ProjectDTO dto = new ProjectDTO();
    dto.setId(project.getId());
    dto.setName(project.getName());
    dto.setCreatedAt(project.getCreatedAt());
    return dto;
}
```

After:
```java
public interface HasIdNameDate {
    Long getId();
    String getName();
    Instant getCreatedAt();
}

public <S extends HasIdNameDate, D extends BaseDTO> D toDTO(S source, Supplier<D> dtoFactory) {
    D dto = dtoFactory.get();
    dto.setId(source.getId());
    dto.setName(source.getName());
    dto.setCreatedAt(source.getCreatedAt());
    return dto;
}
```

### When NOT to Unify

- If the duplicates are likely to diverge in the future (different business domains)
- If unifying requires overly complex parameterization (the cure is worse than the disease)
- If there are only 2 instances and they're short — the Rule of Three applies (wait for a third occurrence before extracting)

---

## Cross-File Pattern Consolidation

**Smell:** Multiple files contain structurally identical logic — same control flow, same error handling, same setup/teardown — varying only in entity names, field references, or configuration values. Unlike near-duplicates within a single file, these are scattered across the codebase and require systematic search to discover.

### Example 1: Parallel service handlers → Generic handler factory

Discovered by searching for files matching `*Service.*` and finding identical CRUD patterns.

Before (`user_service.py`, `product_service.py`, `order_service.py` — 3 separate files):
```python
# user_service.py
class UserService:
    def __init__(self, db, logger):
        self.db = db
        self.logger = logger

    def create(self, data):
        self.logger.info(f"Creating user")
        validated = UserSchema.validate(data)
        result = self.db.users.insert(validated)
        self.logger.info(f"Created user {result.id}")
        return result

    def get_by_id(self, id):
        result = self.db.users.find_by_id(id)
        if not result:
            raise NotFoundError(f"User {id} not found")
        return result

    def update(self, id, data):
        self.get_by_id(id)  # ensure exists
        validated = UserSchema.validate(data)
        return self.db.users.update(id, validated)

    def delete(self, id):
        self.get_by_id(id)  # ensure exists
        self.db.users.delete(id)
        self.logger.info(f"Deleted user {id}")

# product_service.py — nearly identical, replacing "user" with "product"
# order_service.py — nearly identical, replacing "user" with "order"
```

After (single `base_service.py` + thin subclasses):
```python
# base_service.py
class BaseService:
    entity_name: str       # set by subclass
    schema: Schema         # set by subclass

    def __init__(self, db, logger):
        self.db = db
        self.logger = logger

    @property
    def collection(self):
        return getattr(self.db, self._collection_name)

    @property
    def _collection_name(self):
        return f"{self.entity_name}s"

    def create(self, data):
        self.logger.info(f"Creating {self.entity_name}")
        validated = self.schema.validate(data)
        result = self.collection.insert(validated)
        self.logger.info(f"Created {self.entity_name} {result.id}")
        return result

    def get_by_id(self, id):
        result = self.collection.find_by_id(id)
        if not result:
            raise NotFoundError(f"{self.entity_name} {id} not found")
        return result

    def update(self, id, data):
        self.get_by_id(id)
        validated = self.schema.validate(data)
        return self.collection.update(id, validated)

    def delete(self, id):
        self.get_by_id(id)
        self.collection.delete(id)
        self.logger.info(f"Deleted {self.entity_name} {id}")

# user_service.py
class UserService(BaseService):
    entity_name = "user"
    schema = UserSchema

# product_service.py
class ProductService(BaseService):
    entity_name = "product"
    schema = ProductSchema
```

### Example 2: Scattered error handling → Shared decorator

Discovered by searching for repeated `try/except` blocks with logging and retry across handler files.

Before (pattern repeated in 5+ route handler files):
```python
# routes/users.py
def create_user(request):
    try:
        data = parse_json(request.body)
        result = user_service.create(data)
        return JsonResponse(result, status=201)
    except ValidationError as e:
        logger.warning(f"Validation failed: {e}")
        return JsonResponse({"error": str(e)}, status=400)
    except NotFoundError as e:
        logger.warning(f"Not found: {e}")
        return JsonResponse({"error": str(e)}, status=404)
    except Exception as e:
        logger.error(f"Unexpected error in create_user: {e}", exc_info=True)
        return JsonResponse({"error": "Internal server error"}, status=500)

# routes/products.py — identical try/except structure
# routes/orders.py — identical try/except structure
```

After:
```python
# middleware/error_handler.py
def handle_errors(func):
    @wraps(func)
    def wrapper(request, *args, **kwargs):
        try:
            return func(request, *args, **kwargs)
        except ValidationError as e:
            logger.warning(f"Validation failed: {e}")
            return JsonResponse({"error": str(e)}, status=400)
        except NotFoundError as e:
            logger.warning(f"Not found: {e}")
            return JsonResponse({"error": str(e)}, status=404)
        except Exception as e:
            logger.error(f"Unexpected error in {func.__name__}: {e}", exc_info=True)
            return JsonResponse({"error": "Internal server error"}, status=500)
    return wrapper

# routes/users.py
@handle_errors
def create_user(request):
    data = parse_json(request.body)
    result = user_service.create(data)
    return JsonResponse(result, status=201)
```

### Example 3: Repeated test setup → Shared fixtures

Discovered by searching for identical `setUp`/`beforeEach` blocks across test files.

Before (pattern in `test_user_service.py`, `test_product_service.py`, `test_order_service.py`):
```python
class TestUserService(unittest.TestCase):
    def setUp(self):
        self.db = MockDatabase()
        self.db.connect("test_db")
        self.db.clear_all()
        self.logger = MockLogger()
        self.service = UserService(self.db, self.logger)

    def tearDown(self):
        self.db.clear_all()
        self.db.disconnect()

    def test_create(self):
        result = self.service.create({"name": "Alice"})
        self.assertIsNotNone(result.id)

# test_product_service.py — same setUp/tearDown, different service class
# test_order_service.py — same setUp/tearDown, different service class
```

After:
```python
# tests/conftest.py or tests/base.py
class ServiceTestBase(unittest.TestCase):
    service_class = None  # set by subclass
    
    def setUp(self):
        self.db = MockDatabase()
        self.db.connect("test_db")
        self.db.clear_all()
        self.logger = MockLogger()
        self.service = self.service_class(self.db, self.logger)

    def tearDown(self):
        self.db.clear_all()
        self.db.disconnect()

# test_user_service.py
class TestUserService(ServiceTestBase):
    service_class = UserService

    def test_create(self):
        result = self.service.create({"name": "Alice"})
        self.assertIsNotNone(result.id)
```

### When NOT to Consolidate Cross-File Patterns

All the cautions from "Unify Near-Duplicate Code" apply, plus:

- **Different bounded contexts.** Code in `billing/` and `shipping/` may look identical but serves different domains. Coupling them creates cross-domain dependencies that are worse than duplication.
- **Pattern is still forming.** If the similar files were created recently or are under active development, the pattern hasn't stabilized. Premature abstraction locks in a structure that may not fit.
- **Abstraction requires >3 extension points.** If every instance needs its own hooks, callbacks, or overrides, the "shared" code is really a framework — and frameworks are much harder to maintain than a few similar files.
- **Test coverage is sparse.** Cross-file refactoring without adequate tests is high-risk. Write characterization tests for each instance first.
