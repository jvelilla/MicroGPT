Based on the engineering principles and stylistic guidelines provided, here are the official rules for LLM agents to follow when generating or reviewing Eiffel code.

---

## 1. General Philosophy: "Egoful Design, Egoless Expression"

* **Precision over Shortcuts:** Never skimp on keystrokes at the expense of clarity. "Typing is cheap; maintenance is expensive."
* **Micro-Terseness vs. Macro-Size:** Aim for a "telegram style" in low-level details (like comments) but accept larger codebases if they result from architectural rigor (Assertions, Genericity, Inheritance).
* **Proactive Quality:** Apply style rules from the first line of code. Do not "clean up later."

---

## 2. Naming Conventions (Identifiers)

### General Rules

* **No Abbreviations:** Use full words. Use `number` instead of `num`, `account` instead of `accnt`, and `display` instead of `disp`.
* *Exception:* Use domain-standard terms (e.g., `usa` in GIS) or established Eiffel library shorthand (e.g., `G` for generic parameters).


* **Underscore Separation:** Use underscores to connect words (`annual_rate`). Never use camelCase (`yearlyPremium`).
* **The Composite Feature Name Rule:** Do not include the class name in the feature name.
* *Bad:* `class PART` with feature `part_number`.
* *Good:* `class PART` with feature `number`.



### Letter Case Requirements

| Entity Type | Case Style | Example |
| --- | --- | --- |
| **Classes & Generic Parameters** | ALL_UPPER_CASE | `LINKED_LIST`, `G` |
| **Routines, Attributes, Locals** | all_lower_case | `balance`, `put_left`, `i` |
| **Constants & Once-functions** | Camel_case_with_underscore | `Pi`, `Error_window` |
| **Keywords (Syntactic)** | **bold** / lower case | `class`, `do`, `if` |
| **Built-in semantic entities** | Capitalized | `Current`, `Result`, `True` |

---

## 3. Routine and Feature Design

### Command-Query Separation (CQS)

* **Procedures (Commands):** Must be verbs in the infinitive or imperative. (e.g., `make`, `move`, `deposit`).
* **Attributes/Functions (Queries):** Must be nouns or adjectives; never imperative verbs.
* *Bad:* `get_value`. *Good:* `value`.
* **Boolean Queries:** Use adjectives (e.g., `full`). For clarity in English, the `is_` prefix is preferred (e.g., `is_empty`).



### Standard Library Names

Agents must use these specific names for consistency across structures:

* **Access:** `item`
* **Addition:** `extend` (basic), `put` (standard), `force` (no precondition/resizing)
* **Removal:** `remove` (general), `prune` (specific element), `wipe_out` (all)
* **Status:** `count`, `capacity`, `has`, `is_empty`, `is_full`

---

## 4. The Symbolic Constant Principle

* **Zero-Element Rule:** Do not use manifest constants (literals) in code.
* *Forbidden:* `make (1, 50)` or `print ("Error")`.
* *Mandatory:* Define a symbolic constant: `State_count: INTEGER = 50`.


* **Exceptions:** The "zero elements" of operations are allowed: `0`, `1`, `0.0`, `""`, and `'%0'`.

---

## 5. Documentation and Comments

### Routine Header Comments

The header comment is the primary documentation for the "short form" of the class.

* **Terseness:** Remove noise words like "The", "This routine returns...", or "Return the...".
* **Query Formatting:** Describe the result as a noun, no period. (e.g., `-- Distance to origin`).
* **Command Formatting:** Use imperative style, end with a period. (e.g., `-- Record outgoing call.`).
* **Boolean Formatting:** Use a question mark. (e.g., `-- Is list empty?`).
* **Entity Referencing:** Place arguments or local entities in backquotes: ``v``.
* **No Redundancy:** Do not repeat type information or preconditions in the comment. If a precondition says `x >= 0`, do not write "x must be positive" in the comment.

### Note (Indexing) and Feature Clauses

* **Class Note Clause:** Every class must have a `description` entry.
* *Format:* `description: "Sequential lists, in chained representation"`.


* **Feature Grouping:** Group features into labeled clauses (e.g., `feature -- Access`, `feature -- Element change`).

---

## 6. Layout and Cosmetics

* **Alignment:** Indent header comments one level deeper than the routine start to make them stand out.
* **Semicolons:** Avoid semicolons unless necessary for separating multiple instructions on a single line.
* **Single-line constructs:** Grouping related small components is permitted:
`from i := 1 invariant i <= n until i = n loop`

---
