# Eiffel Inheritance Rules for LLMs
## A Complete Guide to Correct Inheritance Implementation

---

## Table of Contents
1. [Core Inheritance Concepts](#1-core-inheritance-concepts)
2. [When to Use Inheritance](#2-when-to-use-inheritance)
3. [When to Use Multiple Inheritance](#3-when-to-use-multiple-inheritance)
4. [Solving Inheritance Conflicts](#4-solving-inheritance-conflicts)
5. [Contract Rules](#5-contract-rules)
6. [Code Examples](#6-code-examples)
7. [Common Pitfalls](#7-common-pitfalls)
8. [Quick Reference Checklist](#8-quick-reference-checklist)

---

## 1. Core Inheritance Concepts

### 1.1 Basic Syntax
```eiffel
class
    HEIR_CLASS
inherit
    PARENT_CLASS_1
    PARENT_CLASS_2  -- Multiple inheritance is supported
feature
    -- Your features here
end
```

### 1.2 The "Is-A" Relationship
**Rule:** Use inheritance ONLY when the heir truly "is-a" instance of the parent.

✅ **Correct:** `TAXI inherit VEHICLE` (a taxi IS-A vehicle)
❌ **Incorrect:** `PERSON inherit ADDRESS` (a person is NOT an address; use composition instead)

### 1.3 Terminology
- **Heir/Descendant:** The class inheriting
- **Parent/Ancestor:** The class being inherited from
- **Proper descendant:** Descendants excluding the class itself
- **Feature:** Any routine (procedure/function) or attribute

---

## 2. When to Use Inheritance

### 2.1 Primary Use Cases

#### A. Taxonomy (Classification)
Use inheritance to express type relationships:
```eiffel
class
    SAVINGS_ACCOUNT
inherit
    ACCOUNT
```

#### B. Feature Accumulation
Inherit to reuse existing features:
```eiffel
class
    INTEGER
inherit
    NUMERIC      -- Gets arithmetic operations
    COMPARABLE   -- Gets comparison operations
```

#### C. Abstraction with Deferred Classes
Use deferred (abstract) classes to define behavior templates:
```eiffel
deferred class
    VEHICLE
feature
    start_engine
        deferred
        end
end
```

### 2.2 When NOT to Use Inheritance

❌ **Don't** use inheritance for:
- Code reuse alone (use composition or clients instead)
- Convenience (creates tight coupling)
- Implementation sharing without conceptual "is-a" relationship

---

## 3. When to Use Multiple Inheritance

### 3.1 The Rule
**Use multiple inheritance when a concept is a specialization of TWO OR MORE existing concepts simultaneously.**

### 3.2 Valid Examples

#### Example 1: Mathematical Classes
```eiffel
class
    INTEGER
inherit
    NUMERIC      -- Provides +, -, *, /
    COMPARABLE   -- Provides <, >, =, <=, >=
```
**Why?** Integers are both numeric AND comparable.

#### Example 2: Transportation
```eiffel
class
    TROLLEY
inherit
    TRAM
    BUS
```
**Why?** A trolley combines characteristics of both trams and buses.

#### Example 3: Business Domain
```eiffel
class
    COMPANY_PLANE
inherit
    PLANE   -- Has altitude, speed, can take off/land
    ASSET   -- Has value, depreciation, can be sold
```

### 3.3 When to Avoid Multiple Inheritance

❌ Avoid if:
- There's no genuine conceptual overlap
- You're trying to share implementation details (use composition)
- The hierarchy becomes confusing (violates clarity principle)

---

## 4. Solving Inheritance Conflicts

### 4.1 Name Clashes (Renaming)

**Problem:** Two parents have features with the same name.

**Solution:** Use the `rename` clause.

```eiffel
class
    D
inherit
    A
        rename
            display as display_a
        end
    B
        rename
            display as display_b
        end
feature
    show_both
        do
            display_a
            display_b
        end
end
```

**Rules for Renaming:**
- Rename in the inherit clause, NOT in the feature clause
- Both features remain available under new names
- Original names are no longer accessible in the heir

### 4.2 Repeated Inheritance (Diamond Problem)

**Problem:** Class D inherits from B and C, which both inherit from A.

```
    A
   / \
  B   C
   \ /
    D
```

**Solution 1: Sharing (Default)**
If you DON'T rename, the feature is **shared** (one copy):
```eiffel
class
    D
inherit
    B
    C
    -- Feature 'f' from A is shared
```

**Solution 2: Replication**
If you DO rename, the feature is **replicated** (two copies):
```eiffel
class
    D
inherit
    B
        rename
            f as f_from_b
        end
    C
        rename
            f as f_from_c
        end
    -- Now have two distinct features
```

### 4.3 Dynamic Binding Ambiguity (Selection)

**Problem:** After replication, which version should dynamic binding use?

**Solution:** Use the `select` clause to specify the dominant version:

```eiffel
class
    D
inherit
    B
        rename
            f as f_from_b
        select
            f_from_b  -- This is the default for dynamic binding
        end
    C
        rename
            f as f_from_c
        end
```

**Select Rules:**
- Use only when you have replicated features
- Select the version that should respond to polymorphic calls
- You can still call non-selected versions explicitly

---

## 5. Contract Rules

### 5.1 Design by Contract in Inheritance

**Core Principle:** You cannot invalidate a parent's contract.

### 5.2 Preconditions (require)

**Rule:** Can ONLY be **weakened** (accept more inputs).

**Syntax:** Use `require else`

```eiffel
class
    PARENT
feature
    process (x: INTEGER)
        require
            x > 0
        do
            ...
        end
end

class
    CHILD
inherit
    PARENT
        redefine
            process
        end
feature
    process (x: INTEGER)
        require else
            x > -10  -- Weaker: accepts more values
        do
            ...
        end
end
```

**Why?** The child must accept at least everything the parent accepts (Liskov Substitution Principle).

### 5.3 Postconditions (ensure)

**Rule:** Can ONLY be **strengthened** (promise more output).

**Syntax:** Use `ensure then`

```eiffel
class
    PARENT
feature
    deposit (amount: INTEGER)
        ensure
            balance_increased: balance >= old balance
        end
end

class
    CHILD
inherit
    PARENT
        redefine
            deposit
        end
feature
    deposit (amount: INTEGER)
        ensure then
            interest_updated: interest_updated_correctly
        end
end
```

**Why?** The child must deliver at least everything the parent promises.

### 5.4 Invariants

**Rule:** Invariants are automatically accumulated.

```eiffel
class
    PARENT
invariant
    positive_balance: balance >= 0
end

class
    CHILD
inherit
    PARENT
invariant
    has_account_number: account_number /= Void
    -- Both invariants apply to CHILD
end
```

---

## 6. Code Examples

### 6.1 Complete Example: Bank Accounts

```eiffel
deferred class
    ACCOUNT
feature
    balance: INTEGER
    
    deposit (amount: INTEGER)
        require
            positive_amount: amount > 0
        deferred
        ensure
            balance_increased: balance = old balance + amount
        end
        
    withdraw (amount: INTEGER)
        require
            positive_amount: amount > 0
            sufficient_funds: amount <= balance
        deferred
        ensure
            balance_decreased: balance = old balance - amount
        end
        
invariant
    non_negative_balance: balance >= 0
end
```

```eiffel
class
    SAVINGS_ACCOUNT
inherit
    ACCOUNT
        redefine
            deposit
        end
feature
    interest_rate: REAL
    
    deposit (amount: INTEGER)
        do
            Precursor (amount)  -- Call parent version
            update_interest
        end
        
    update_interest
        do
            -- Interest calculation logic
        end
        
invariant
    valid_interest_rate: interest_rate >= 0.0 and interest_rate <= 1.0
end
```

### 6.2 Multiple Inheritance Example

```eiffel
deferred class
    NUMERIC
feature
    plus alias "+" (other: like Current): like Current
        deferred
        end
        
    times alias "*" (other: like Current): like Current
        deferred
        end
end

deferred class
    COMPARABLE
feature
    less_than alias "<" (other: like Current): BOOLEAN
        deferred
        end
        
    less_equal alias "<=" (other: like Current): BOOLEAN
        do
            Result := Current < other or equal (other)
        end
end

class
    INTEGER
inherit
    NUMERIC
    COMPARABLE
feature
    plus alias "+" (other: INTEGER): INTEGER
        do
            -- Implementation
        end
        
    less_than alias "<" (other: INTEGER): BOOLEAN
        do
            -- Implementation
        end
end
```

### 6.3 Handling Conflicts

```eiffel
class
    MULTI_DEVICE
inherit
    PRINTER
        rename
            initialize as initialize_printer,
            status as printer_status
        end
    SCANNER
        rename
            initialize as initialize_scanner,
            status as scanner_status
        end
feature
    initialize
        -- Initialize both components
        do
            initialize_printer
            initialize_scanner
        end
        
    show_status
        do
            print ("Printer: " + printer_status)
            print ("Scanner: " + scanner_status)
        end
end
```

---

## 7. Common Pitfalls

### 7.1 Forgetting to Redefine

❌ **Wrong:**
```eiffel
class
    CHILD
inherit
    PARENT
feature
    process  -- ERROR: Name clash without redefine
        do
            ...
        end
end
```

✅ **Correct:**
```eiffel
class
    CHILD
inherit
    PARENT
        redefine
            process
        end
feature
    process
        do
            ...
        end
end
```

### 7.2 Violating Contracts

❌ **Wrong:** Strengthening precondition
```eiffel
class
    CHILD
inherit
    PARENT
        redefine
            process
        end
feature
    process (x: INTEGER)
        require
            x > 100  -- ERROR: Stronger than parent's x > 0
        do
            ...
        end
end
```

✅ **Correct:** Weakening precondition
```eiffel
class
    CHILD
inherit
    PARENT
        redefine
            process
        end
feature
    process (x: INTEGER)
        require else
            x > -10  -- OK: Weaker (accepts more)
        do
            ...
        end
end
```

### 7.3 Misusing Multiple Inheritance

❌ **Wrong:** No "is-a" relationship
```eiffel
class
    CAR
inherit
    ENGINE  -- Wrong: a car HAS an engine, not IS an engine
    WHEEL   -- Wrong: a car HAS wheels, not IS a wheel
```

✅ **Correct:** Use composition
```eiffel
class
    CAR
feature
    engine: ENGINE
    wheels: ARRAY[WHEEL]
```

---

## 8. Quick Reference Checklist

### ✅ Before Using Inheritance

- [ ] Does an "is-a" relationship exist?
- [ ] Am I reusing behavior, not just implementation?
- [ ] Will the heir satisfy all parent contracts?
- [ ] Is the abstraction appropriate for both parent and heir?

### ✅ For Multiple Inheritance

- [ ] Does the heir genuinely combine multiple concepts?
- [ ] Have I resolved all name conflicts with `rename`?
- [ ] If features are replicated, have I used `select` if needed?
- [ ] Is the resulting hierarchy clear and understandable?

### ✅ For Contracts

- [ ] Used `require else` for weaker preconditions?
- [ ] Used `ensure then` for stronger postconditions?
- [ ] Verified all invariants are compatible?
- [ ] Tested that contracts are satisfied in all cases?

### ✅ For Redefinition

- [ ] Declared feature in `redefine` clause?
- [ ] Used `Precursor` if calling parent implementation?
- [ ] Maintained or strengthened the contract?
- [ ] Preserved the original purpose of the feature?

---

## Summary: The Three Golden Rules

1. **Use `rename` to resolve name clashes**
   - Two features with same name → rename one or both

2. **Sharing vs. Replication in repeated inheritance**
   - No rename → sharing (one copy)
   - Rename → replication (multiple copies)
   
3. **Use `select` to resolve dynamic binding ambiguity**
   - After replication, specify which version is dominant

4. **Contract discipline**
   - Preconditions: weaken only (`require else`)
   - Postconditions: strengthen only (`ensure then`)
   - Never violate parent contracts

---

## Additional Resources

- Eiffel Documentation: https://www.eiffel.org/doc/eiffel/ET-_Inheritance
- Object-Oriented Software Construction (OOSC) by Bertrand Meyer, Chapters 14-16
- Touch of Class textbook (referenced in your notes)

---

*This guide provides LLMs with clear, actionable rules for generating correct Eiffel inheritance code. Follow these patterns to ensure your generated code respects Eiffel's inheritance mechanisms and Design by Contract principles.*
