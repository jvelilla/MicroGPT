# Eiffel.md — LLM Code Generation Rules for Eiffel

This document defines strict rules for generating **valid, idiomatic, contract-driven Eiffel code** using Large Language Models.

LLMs MUST comply with these rules whenever outputting Eiffel.

---

# 1. General Principles

1. Produce **real, compilable Eiffel**, never pseudo-code.  
2. Follow **Design by Contract**, **Command–Query Separation**, and **Uniform Access**.  
3. Prefer clarity and correctness over cleverness.  
4. If details are missing, make safe, documented assumptions.  
5. Output **only Eiffel** unless the user explicitly asks for commentary.
6. Review the code style using the Eiffel style guide defined in [Eiffel Style Guide](Eiffel_style.md)	
---

# 2. Naming Rules (Strict)

| Entity | Style | Examples |
|--------|--------|-----------|
| Class names | UPPERCASE | `PERSON`, `BANK_ACCOUNT` |
| Features | lowercase_with_underscores | `set_age`, `is_empty` |
| Locals | short & descriptive | `i`, `result_val`, `item` |
| Booleans | adjectives or `is_` prefix | `is_valid`, `has_value` |

Rules:
- No camelCase or PascalCase for features.  
- Avoid abbreviations unless universally standard.  
- Once routines & constants use leading uppercase (`Pi`, `Max_int`).  

---

# 3. Formatting & Layout

- **Use TAB indentation** (mandatory).  
- Space before parentheses: `f (x)` not `f(x)`.  
- Space after commas: `f (a, b)`.  
- No space around dot calls: `list.count`.  
- Comments start with `-- ` (two dashes and a space).
- **Inline comments must be indented** to match the indentation level of the code they describe.

### Comment Indentation Example:

**Incorrect (left-aligned):**
```eiffel
do
	create Result.make (4096)
	
-- PDF header
	Result.append ("%%PDF-1.7%N")
-- Binary comment
	Result.append ("%%%/0xE4/%/0xF0/%/0xD3/%/0xFA/%N")
end
```

**Correct (indented):**
```eiffel
do
	create Result.make (4096)
	
	    -- PDF header
	Result.append ("%%PDF-1.7%N")
	    -- Binary comment (4 bytes > 127 per ISO 32000-1 Section 7.5.2)
	Result.append ("%%%/0xE4/%/0xF0/%/0xD3/%/0xFA/%N")
end
```

Grouping of feature clauses:

```
feature -- Initialization
feature -- Access
feature -- Element Change
feature -- Implementation
feature -- Constants
```

---

# 4. Special Characters and Escaping

In Eiffel, special characters within strings and character literals are represented using escape sequences that begin with a percent sign (`%`).

### Common Escape Sequences

| Character | Escape Code | Description |
|-----------|-------------|-------------|
| `@` | `%A` | At-sign |
| Backspace | `%B` | Backspace character |
| `^` | `%C` | Circumflex |
| `$` | `%D` | Dollar sign |
| Form feed | `%F` | Form feed character |
| `\` | `%H` | Backslash |
| `~` | `%L` | Tilde |
| Newline | `%N` | Newline character |
| `` ` `` | `%Q` | Backquote |
| Carriage return | `%R` | Carriage return character |
| `#` | `%S` | Sharp (hash) |
| Tab | `%T` | Horizontal tab character |
| Null | `%U` | Null character |
| `\|` | `%V` | Vertical bar |
| `%` | `%%` | Percent sign (to escape `%` itself) |
| `'` | `%'` | Single quote |
| `"` | `%"` | Double quote |
| `[` | `%(` | Opening bracket |
| `]` | `%)` | Closing bracket |
| `{` | `%<` | Opening brace |
| `}` | `%>` | Closing brace |

### Numeric Character Codes

Characters can also be represented by their numeric codes:

- **Decimal:** `%/123/` - character with decimal code 123
- **Hexadecimal:** `%/0x2200/` - character with hexadecimal code U+2200
- **Octal:** `%/0c21000/` - character with octal code 21000
- **Binary:** `%/0b10001000000000/` - character with binary code

### Examples:

```eiffel
-- String with newline
message := "Hello%NWorld"

-- String with tab and quotes
text := "She said %"Hello%", then left.%TBye!"

-- String with percent sign
percentage := "Discount: 50%% off"

-- Character literals
newline_char: CHARACTER = '%N'
quote_char: CHARACTER = '%"'

-- Using numeric codes
unicode_char: CHARACTER = '%/0x2200/'  -- ∀ (for all)
```

### Rules:
- Use escape sequences for special characters in strings and character literals.
- Always use `%%` to represent a literal percent sign.
- Use `%N` for newlines, `%T` for tabs, `%R` for carriage returns.
- Use numeric codes for Unicode characters or characters not covered by standard escape sequences.

**Reference:** [Eiffel Syntax - Special Characters](https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax#Special_characters)

---

# 5. Class Structure (Strict Template)

LLMs must follow this exact structure:

```eiffel
note
	description: "Short description."

class
	CLASS_NAME

create
	make


inherit
	-- Optional

feature -- Initialization

	make (...)
			-- Constructor comment.
		require
			-- Preconditions
		do
			-- Body
		ensure
			-- Postconditions
		end

feature -- Access

	...

feature -- Element Change

	...

invariant
	invariant_label: condition

end
```

---

# 6. Once Classes

Once classes represent a mechanism to specify **unique values** in a program. They behave like any other objects but preserve their identity at creation time. Only a single distinguishable instance of a class is created per creation procedure, regardless of how many times the creation is used.

### Declaration

A once class is declared with the keyword `once` before `class`. **All creation procedures** listed in the declaration must be once procedures.

```eiffel
once class
	DIRECTION

create
	down, left, right, up

feature {NONE} -- Creation

	down
		once
			y_scroll := 3
		end

	left
		once
			x_scroll := -1
		end

	right
		once
			x_scroll := 1
		end

	up
		once
			y_scroll := -3
		end

feature -- Access

	x_scroll: INTEGER
			-- The number of columns to scroll.

	y_scroll: INTEGER
			-- The number of lines to scroll.

end
```

### Key Properties

- **Uniqueness:** Only one instance is created per creation procedure. Successive attempts to create an object with the same creation procedure yield the same object.
- **Frozen:** Once classes are automatically frozen and cannot be used as parents of other classes.
- **Equality:** Objects created with the same creation procedure are equal (`=`).
- **State sharing:** Changing attributes of a once object updates them for all references to that object.

### Access and Creation

Objects of a once class can be created using regular creation syntax:

```eiffel
-- Creation instruction
create direction.up

-- Creation expression
foo (create {DIRECTION}.up)

-- Simplified creation expression (create keyword can be omitted)
foo ({DIRECTION}.up)
```

### Multi-Branch Constructs

Once classes can be used in `inspect` statements, similar to integers:

```eiffel
inspect direction
when {DIRECTION}.down then
	io.put_string ("Down")
when {DIRECTION}.left then
	io.put_string ("Left")
when {DIRECTION}.right then
	io.put_string ("Right")
when {DIRECTION}.up then
	io.put_string ("Up")
end
```

**Intervals:** The order of creation procedures in the `create` clause determines their relative order for interval matching:

```eiffel
once class
	DAY_OF_WEEK

create
	Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday

-- Can use intervals:
inspect day
when {DAY_OF_WEEK}.Monday .. {DAY_OF_WEEK}.Friday then
	is_weekend := False
else
	is_weekend := True
end
```

### SCOOP (Concurrency)

Once classes follow default once-per-thread behavior. To create a single instance across all threads and SCOOP regions, specify the `"PROCESS"` once key:

```eiffel
up
	once ("PROCESS")
		y_scroll := -3
	end
```

Without the once key, each thread gets its own instance. With `"PROCESS"`, all threads share the same instance.

### Use Cases

**1. Singleton Pattern:**
```eiffel
once class
	LOGGER

create
	make

feature -- Initialization

	make
		once
			-- Initialize logger
		end

feature -- Access

	log (message: STRING)
		do
			-- Log message
		end

end
```

**2. Enumeration-like Values:**
Use once classes to represent fixed sets of values (like enums in other languages).

**3. Iteration:**
Provide an `instances` feature returning all values:

```eiffel
instances: ITERABLE [DAY_OF_WEEK]
		-- All days of week.
	once
		Result := <<{DAY_OF_WEEK}.Sunday, {DAY_OF_WEEK}.Monday,
			{DAY_OF_WEEK}.Tuesday, {DAY_OF_WEEK}.Wednesday,
			{DAY_OF_WEEK}.Thursday, {DAY_OF_WEEK}.Friday,
			{DAY_OF_WEEK}.Saturday>>
	ensure
		class
	end
```

### Rules:
- All creation procedures in a once class must be once procedures.
- Once classes are automatically frozen (cannot inherit from them).
- Use once classes when you need unique, distinguishable values.
- Use `"PROCESS"` once key for system-wide uniqueness in concurrent programs.
- Creation expression syntax can omit `create` keyword: `{DIRECTION}.up` instead of `create {DIRECTION}.up`.

**Reference:** [Once Classes - Eiffel Blog](https://www.eiffel.org/blog/Alexander%20Kogtenkov/2020/12/once-classes)

For more specific uses of SCOOP use [SCOOP - Guide](Eiffel_scoop_guide.md)
For more specific uses of Inheritance use [Eiffel Inheritance](Eiffel_inheritance.md)

---

# 7. Attachment Status (Types are Attached by Default)

In modern Eiffel, **all reference types are attached by default**. This means:

- A variable of type `STRING` cannot be `Void` unless explicitly declared as `detachable STRING`.
- No need for `/= Void` checks on attached types.
- Use `detachable TYPE` only when `Void` is a valid value.
- Use `attached TYPE` explicitly when you want to emphasize attachment (optional but clear).

### Rules:
- **Default:** All reference types are attached (`STRING`, `LIST [INTEGER]`, etc.).
- **Explicit detachment:** Use `detachable STRING` when `Void` is allowed.
- **Explicit attachment:** Use `attached STRING` for clarity (redundant but allowed).
- **Preconditions:** Do NOT check `a_string /= Void` for attached types.
- **Preconditions:** DO check `a_string /= Void` for `detachable STRING` parameters.

### Examples:

```eiffel
-- Attached by default (cannot be Void)
name: STRING

-- Explicitly detachable (can be Void)
optional_name: detachable STRING

-- In preconditions for attached types (unnecessary):
-- name_not_void: a_name /= Void  -- WRONG: a_name is attached

-- In preconditions for detachable types (necessary):
-- name_not_void: a_name /= Void  -- CORRECT: a_name is detachable
```

---

# 8. Design by Contract (Mandatory)

### Preconditions (`require`)
Define what the **client** must guarantee.

### Postconditions (`ensure`)
Define what the **supplier** guarantees.

### Invariants
Define long-term correctness constraints.

### Loop Invariants and Variants (Optional)
Loop invariants and variants are optional parts of loops that help guarantee loop correctness.

**Loop Invariants:**
- Express properties that must be true after initialization and preserved by each loop iteration.
- The initialization part must establish the invariant.
- Each loop body execution must preserve the invariant.
- When the loop terminates, both the invariant and exit condition are true.

**Loop Variants:**
- Provide an integer expression whose value is non-negative after initialization.
- The variant value must decrease by at least one (while remaining non-negative) with each loop iteration.
- This guarantees loop termination (a non-negative integer cannot decrease forever).

**Syntax:**
```eiffel
from
	-- Initialization (establishes invariant, variant >= 0)
invariant
	invariant_label: condition  -- Must hold after init and each iteration
variant
	variant_label: integer_expression  -- Must decrease each iteration
until
	exit_condition
loop
	-- Loop body (preserves invariant, decreases variant)
end
```

**Example:**
```eiffel
find_index (target: INTEGER): INTEGER
		-- Find index of `target` in array, or -1 if not found.
	local
		i: INTEGER
	do
		from
			i := 1
			Result := -1
		invariant
			valid_range: i >= 1 and i <= array.count + 1
			not_found_yet: Result = -1 implies (∀ j: 1 |..| (i - 1) ¦ array [j] /= target)
		variant
			remaining_elements: array.count + 1 - i
		until
			i > array.count or Result >= 0
		loop
			if array [i] = target then
				Result := i
			else
				i := i + 1
			end
		end
	end
```

**Rules:**
- Loop invariants and variants are **optional** but recommended for complex loops.
- Invariants must be **labeled**.
- Variants must be **labeled**.
- Variants must be non-negative integers that decrease with each iteration.
- When assertion monitoring is enabled, these properties are checked after initialization and each iteration.

**Reference:** [Loop Invariants and Variants](https://www.eiffel.org/doc/eiffel/ET-_Instructions#Loop_invariants_and_variants)

Rules:
- Preconditions may be **weakened** in subclasses. `require else` 
- Postconditions may be **strengthened**.   `ensure then`
- Invariants must always hold around exported features.  
- Assertions must be **labeled**.


### DbC Principles:  How to write Contracts?
- `Separate command and queries`: Queries return a result, doesn't change the state of the object. Commands might change the state of the object, do not return a result.
- `Separate basic queries from derived queries`: Derived queries can be specified in terms of basic queries.
- `For each derived query, write a postcondition that specify what result will be returned in term of one or more queries`: If we know the values of the basic queries we also know the values of the derived ones.
- `For each command, write a postcondition that specifies the value of every basic query`: Taken together with the principle of `defining derived queries in term of basic queries`, this means that now we know the total visible effect of each command.
- `For every query and command, decide on a suitable precondition`: Preconditions constrain when clients may call the queries and commands.
- `Write invariants to define unchanging properties of objects`: Concentrate on properties that help the reader build 
an appropriate conceptual model of the abstraction that the class embodies.


### DbC Guidelines
- `Add physical constraints where appropriate`: Typically these will be constraints that variables should not be Void.
- `Make sure that queries used in preconditions are cheap to calculate`: If needed, add a cheap-to-calculate derived queries whose postconditions verify them against more expensive ones.
- `Constraint attributes using an invariant`: When a derived query is implemented as an attribute, it can be constrained to be consistent with other queries by an assertion in the class's invariant section
- `To support redefinition of features, guard each postcondition clause with it's corresponding precondition`: This allows unforeseen redefinitions by those developing subclasses.
- `Place constraints on desired changes and frame rules in separate classes`: This allows developers more freedom to redefine features in subclasses.

---

# 9. Commands vs Queries

- **Commands:** Procedures that mutate state, return nothing.  
- **Queries:** Functions that return a value, must NOT mutate state.  

This is strict.

---

# 10. Loops and Iteration

Eiffel supports several loop constructs. The `across` loop provides iteration over iterable collections.

### Across Loops

The `across` loop iterates over collections that conform to `ITERABLE [G]`. It provides access to both the current item and cursor features.

**Syntax:**
```eiffel
across iterable_expression as cursor_name loop
	-- Loop body
	-- Access current item: cursor_name
	-- Access cursor features: @ cursor_name.feature_name
end
```

**Unified Cursor Syntax:**
- **Current item:** Accessed directly by the cursor name (e.g., `x` or `y`)
- **Cursor features:** Accessed by preceding the cursor name with `@` (e.g., `@ x.target_index` or `@ y.key`)

**Examples:**

```eiffel
-- Iterate over array, accessing current item
across array as x loop
	print (x)
	io.put_new_line
end

-- Access cursor features using @ syntax
∀ x: array ¦ (@ x.target_index \\ 2 = 0 ⇒ x > 0)
	-- All elements at even positions are positive.

-- Iterate over hash table, accessing both key and value
across table as y loop
	print (@ y.key)  -- Access key via cursor
	print (": ")
	print (y)        -- Access value (current item)
	io.put_new_line
end

-- Iterate over integer interval
across 5 |..| 15 as i loop
	print (i.out + "%N")
end

-- Iterate in reverse order
across my_list.new_cursor.reversed as ic loop
	print (ic)  -- Current item accessed directly
end
```

**Symbolic Loops (Quantifier Forms) - Optional:**
[Symbolic loops]((https://www.eiffel.org/blog/Alexander%20Kogtenkov/2020/03/symbolic-forms-loops) use quantifier notation and are **optional** but **preferred** for use in preconditions, postconditions, and invariants.


```eiffel
-- Universal quantifier (all elements satisfy condition)
∀ x: collection ¦ condition

-- Existential quantifier (at least one element satisfies condition)
∃ x: collection ¦ condition
```

**When to Use Symbolic Loops:**
- **Preferred** in preconditions (`require` clauses)
- **Preferred** in postconditions (`ensure` clauses)
- **Preferred** in invariants
- **Preferred** in loop invariants
- Use regular `across ... loop ... end` for executable code in routine bodies

**Examples in Contracts:**
```eiffel
feature -- Access

	is_sorted: BOOLEAN
			-- Are all elements in sorted order?
		do
			Result := ∀ i: 1 |..| (array.count - 1) ¦ array [i] <= array [i + 1]
		end

feature -- Element Change

	add_all (items: ITERABLE [INTEGER])
			-- Add all items to the collection.
		require
			all_positive: ∀ x: items ¦ x > 0
		do
			across items as x loop
				collection.extend (x)
			end
		ensure
			all_added: ∀ x: items ¦ collection.has (x)
		end

invariant
	no_duplicates: ∀ i: 1 |..| list.count ¦ (∀ j: 1 |..| list.count ¦ (i /= j ⇒ list [i] /= list [j]))
```

**Rules:**
- The iterable expression must conform to `ITERABLE [G]` for some type `G`.
- The cursor name is a local variable scoped to the loop body or assertion.
- Use the cursor name directly to access the current item.
- Use `@ cursor_name.feature_name` to access cursor features (e.g., `target_index`, `key`, `index`).
- Works with arrays, lists, hash tables, intervals, and any class implementing `ITERABLE`.
- Symbolic loops are **optional** but recommended for assertions (preconditions, postconditions, invariants).
- Use regular `across ... loop ... end` syntax for executable code in routine bodies.


**Reference:** [EiffelStudio 21.11 Release Notes](https://www.eiffel.org/doc/eiffelstudio/Release_notes_for_EiffelStudio_21.11)

---

# 11. Agents

Agents provide a mechanism for representing routines as objects, enabling deferred execution, event-driven programming, and flexible iteration patterns.

### Basic Concepts

An agent is an object that represents a routine (procedure or function). Agents are instances of:
- `PROCEDURE [TUPLE [...]]` - for procedures
- `FUNCTION [TUPLE [...], T]` - for functions returning type `T`
- `PREDICATE [TUPLE [...]]` - for boolean functions (predicates)

**Basic Syntax:**
```eiffel
-- Create an agent from an existing routine
agent routine_name
agent routine_name (arg1, arg2, ...)

-- Call an agent
agent_object.call ([arg1, arg2, ...])  -- For procedures
agent_object.item ([arg1, arg2, ...])  -- For functions
```

**Example:**
```eiffel
apply_twice (f: FUNCTION [INTEGER, INTEGER]; x: INTEGER): INTEGER
		-- Apply agent `f` twice to `x`.
	do
		Result := f.item (f.item (x))
	end
```

is a short-hand for:

```eiffel
apply_twice (f: FUNCTION [TUPLE [INTEGER], INTEGER]; x: INTEGER): INTEGER
		-- Apply agent `f` twice to `x`.
	do
		Result := f.item ([f.item ([x])])
	end
```	

### Tuple Type Unfolding and Agent Calls 
**Source Reference:** ECMA-367, Section 8.16 (Tuples)

The shorthand syntax without explicit tuples is allowed because of tuple type unfolding. When calling an agent, arguments are implicitly wrapped in a tuple if needed. This applies to both open and closed arguments in agent definitions and calls.

### Open and Closed Arguments

Agents can have **open** and **closed** arguments. Closed arguments are set when the agent is created; open arguments are provided when the agent is called.

**Syntax:**
- `?` denotes an open argument
- Values or variables denote closed arguments

**Examples:**
```eiffel
-- All arguments open (equivalent to agent routine_name)
agent routine_name (?, ?)

-- Some arguments closed, some open
agent record_city (name, population, ?, ?)
	-- First two arguments are closed, last two are open

-- All arguments closed
agent routine_name (25, 32)
	-- Type: PROCEDURE [TUPLE] (no open arguments)
	-- Call with: agent_object.call ([])
```

When all arguments are open, the arguments can be omitted (recommended):
```eiffel
agent f (?, ?, ?)  -- All open
agent f            -- Recommended shorthand for all open
```

**Type Rules:**
- The agent type is determined by the **open arguments and open targets**
- When an open target is used, the type of the target appears first in the TUPLE type.
- `agent record_city (name, population, ?, ?)` has type `PROCEDURE [TUPLE [INTEGER, INTEGER]]`
- A completely closed agent has type `PROCEDURE [TUPLE]` (empty tuple)

### Open Targets

Agents can also have open or closed targets (the object on which the routine is called).

**Syntax:**
```eiffel
-- Closed target (target is set when agent is created)
agent object.feature_name
agent object.feature_name (arg1, arg2)

-- Open target (target is provided when agent is called)
agent {CLASS_NAME}.feature_name
agent {CLASS_NAME}.feature_name (?, ?)
agent {CLASS_NAME}.feature_name (?, closed_arg)
```

**Examples:**
```eiffel
-- Iterate over accounts, depositing money on each
account_list.do_all (agent {ACCOUNT}.deposit_one_grand)
	-- Target is open, will be each account in the list

-- Iterate over integers, adding each to total
integer_list.do_all (agent add_to_total)
	-- Target is closed (Current), argument is open
```

### Inline Agents

Inline agents allow you to define a routine directly within an agent expression, without creating a separate feature.

**Syntax:**
```eiffel
agent (formal_args): RETURN_TYPE
	require
		-- Optional preconditions
	local
		-- Optional local variables
	do
		-- Body
	ensure
		-- Optional postconditions
	end
```

**Examples:**
```eiffel
-- Inline agent as procedure
account_list.do_all (agent (a: ACCOUNT)
	do
		a.deposit (1000)
	end)

-- Inline agent as function
integer_list.for_all (agent (i: INTEGER): BOOLEAN
	do
		Result := (i > 0)
	ensure
		definition: Result = (i > 0)
	end)

-- Inline agent with local variables
list.do_all (agent (item: STRING)
	local
		upper: STRING
	do
		upper := item.as_upper
		process (upper)
	end)
```

**Rules:**
- Inline agents can have preconditions, postconditions, and local variables
- Inline agents do **not** have access to local variables of the enclosing routine
- If needed, pass local variables as arguments to the inline agent

### Common Use Cases

**1. Iteration:**
```eiffel
-- Apply a procedure to all elements
list.do_all (agent process_item)

-- Apply a procedure with closed arguments
list.do_all (agent process_item (closed_arg, ?))

-- Check if all elements satisfy a condition
all_positive: BOOLEAN
	do
		Result := integer_list.for_all (agent (i: INTEGER): BOOLEAN
			do
				Result := i > 0
			end)
	end
```

**2. Event-Driven Programming:**
```eiffel
-- Register a callback
button.click_actions.extend (agent on_button_click)
button.click_actions.extend (agent handle_click (button_id, ?))
```

**3. Higher-Order Functions:**
```eiffel
integrate (f: FUNCTION [REAL, REAL]; a, b: REAL): REAL
		-- Integrate function `f` from `a` to `b`.
	do
		-- Integration implementation
	end

-- Use with partially closed arguments
integrator.integrate (agent function3 (3.5, ?, 6.0), 0.0, 1.0)
```

### Rules:
- Agents are attached by default (no `Void` check needed for agent parameters)
- Use `?` to denote open arguments
- Use `{TYPE}.feature_name` for open targets
- Inline agents cannot access enclosing routine's local variables
- Agent types are determined by open arguments and open targets
- Use `call` for procedures, `item` for functions

**Reference:** [Eiffel Agents Tutorial](https://www.eiffel.org/doc/eiffel/ET-_Agents)

---


# 12. How to write comments


### a. **Markup Syntax**
- **Class references**: Wrap class names in braces  
  Example:  
  ```eiffel
  -- See {DEBUG_OUTPUT} for more information.
  ```
- **Feature references (same class or parent)**: Use double back quotes  
  Example:  
  ```eiffel
  -- See `debug_output` for more information.
  ```
- **Feature references from another class**: Combine class markup with feature name  
  Example:  
  ```eiffel
  -- See {DEBUG_OUTPUT}.debug_output for more information.
  ```

### b. **Precursor Comments**
- Use `-- <Precursor>` to inherit parent feature comments when redefining.  
- This avoids duplication and ensures consistency.  
- Example:  
  ```eiffel
  test (a_arg: INTEGER): BOOLEAN
      -- <Precursor>
  do
  end
  ```

### c. **Comment Augmentation**
- Add extra notes before or after `-- <Precursor>`.  
- Keep `-- <Precursor>` on its own line for clarity.  
- Example:  
  ```eiffel
  test (a_arg: INTEGER): BOOLEAN
      -- Comments before the original comments from {BASE}.
      -- <Precursor>
      -- Some additional comments.
  do
  end
  ```

### d. **Multiple Redefinitions**
- When inheriting from multiple parents, specify the source class explicitly:  
  ```eiffel
  f (a_arg: INTEGER): BOOLEAN
      -- <Precursor {BASE}>
  do
  end
  ```
- If the class is incorrect, EiffelStudio will warn:  
  ```
  -- Unable to retrieve the comments from redefinition of {CLASS_NAME}.
  ```

### e. **Documentation Integration**
- Precursor comments are supported in all EiffelStudio tools (Contract Viewer, Feature Relation Tool, documentation generators).  
- Using `-- <Precursor>` ensures inherited documentation is visible and consistent.

### f. **Example**

```eiffel

feature -- Access

    do_something (a_arg: INTEGER)
        	-- <Precursor>
    	do
				-- Add some comment
        	instruction 
			instruction 
		end

end

**Reference:** [Eiffel Code  Comments](https://www.eiffel.org/doc/eiffel/Eiffel_Code_Comments)
---

# 13. Prohibited Patterns

LLM MUST NEVER:

- Generate camelCase or mixed styles  
- Auto-format with spaces instead of TABs  
- Use pseudo-Eiffel syntax patterns (incorrect syntax that resembles Eiffel but is invalid):
  - **Incorrect type annotations**: 
    -  WRONG: `{}`, `{ }`, `{TYPE}` (with spaces or empty)
    - CORRECT: `{STRING}`, `{LIST [INTEGER]}`, `{ARRAY [G]}`
  - **Incorrect generic syntax**: 
    -  WRONG: `LIST[]`, `ARRAY[STRING]` (no space before bracket), `[]` (empty generics)
    -  CORRECT: `LIST [INTEGER]`, `ARRAY [STRING]`, `HASH_TABLE [STRING, INTEGER]` (space before bracket required)
  - **Mixed-language patterns**: 
    -  WRONG: `null`, `==`, `!=`, `&&`, `||`, `.equals()`, `->`
    -  CORRECT: `Void`, `=`, `/=`, `and`, `or`, `.is_equal`, `.`
  - **Invalid assignment or expression patterns**: 
    -  WRONG: Using `:=` in function return statements, using `return` keyword, using `;` as statement separator
    -  CORRECT: `Result := value` in functions, no `return` keyword, no statement separators needed  
- Use `null` instead of `Void`  
- Output routines without contracts (except trivial once constants)  
- Mix other languages into Eiffel blocks  
- Duplicate comments that restate code  
- Check `/= Void` for attached types (types are attached by default)  

---


# 14. Working with Strings

Eiffel provides multiple string classes to handle different character encodings and mutability requirements. Understanding when to use each type is essential for writing correct and efficient string-handling code.

## String Type Hierarchy

### a. **READABLE_STRING_GENERAL**
- **Description:** Ancestor of all string variants (mutable, immutable, 8-bit, 32-bit)
- **Use when:** A feature needs to accept **any** string variant as a formal argument
- **Example:**
```eiffel
process_text (text: READABLE_STRING_GENERAL)
		-- Process any string type.
	do
		-- Can handle STRING_8, STRING_32, IMMUTABLE_STRING_8, etc.
	end
```

### b. **READABLE_STRING_32**
- **Description:** Read-only interface for 32-bit Unicode strings (mutable or immutable)
- **Use when:** The code needs to handle Unicode and work with either mutable or immutable versions
- **Benefits:** Direct Unicode support, future-proof

### c. **STRING_32**
- **Description:** Mutable Unicode (32-bit) string variant
- **Use when:** You need to modify string content and support Unicode characters
- **Example:**
```eiffel
feature -- Element Change

	uppercase_name (a_name: STRING_32)
			-- Convert `a_name` to uppercase in place.
		require
			name_exists: a_name /= Void
		do
			a_name.to_upper
		ensure
			is_upper: ∀ i: 1 |..| a_name.count ¦ a_name [i].is_upper or not a_name [i].is_alpha
		end
```

### d. **STRING**
- **Description:** Alias that maps to either `STRING_8` or `STRING_32` depending on configuration
- **Current behavior:** Most libraries currently map to `STRING_8`
- **Future behavior:** May default to `STRING_32` for better Unicode support
- **Recommendation:** Use explicit `STRING_32` for new code requiring Unicode support

### e. **STRING_8**
- **Description:** Mutable 8-bit (ASCII/Latin-1) string
- **Use when:** You are certain the text is ASCII/Latin-1 only and need mutability
- **Limitation:** Cannot represent Unicode characters beyond U+00FF

## Recommended Practices

### 1. **Default Choice: STRING_32**
For most new code, prefer `STRING_32` for direct Unicode support:

```eiffel
feature -- Access

	user_name: STRING_32
			-- User's name (supports international characters).

	greeting_message (name: STRING_32): STRING_32
			-- Create greeting for `name`.
		do
			create Result.make_empty
			Result.append ("Hello, ")
			Result.append (name)
			Result.append ("!")
		ensure
			contains_name: Result.has_substring (name)
		end
```

### 2. **For Generic String Parameters: READABLE_STRING_GENERAL**
When a feature accepts any string type:

```eiffel
feature -- Validation

	is_valid_identifier (text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `text` a valid identifier?
		do
			Result := not text.is_empty and then text [1].is_alpha
		end
```

### 3. **Output Operations: STRING_32**
Use `io.put_string_32` for Unicode output:

```eiffel
feature -- Output

	display_message (msg: STRING_32)
			-- Display `msg` to standard output.
		do
			io.put_string_32 (msg)
			io.put_new_line
		end
```

## UTF Encoding Conversions: UTF_CONVERTER

When you need to convert between different UTF encodings (UTF-8, UTF-16, UTF-32), use the `UTF_CONVERTER` class.

### Key Features

**1. UTF-8 ↔ UTF-32 Conversion:**
```eiffel
feature -- Conversion

	convert_utf8_to_string (utf8_data: STRING_8): STRING_32
			-- Convert UTF-8 encoded `utf8_data` to STRING_32.
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.utf_8_string_8_to_string_32 (utf8_data)
		ensure
			valid_roundtrip: converter.is_valid_utf_8_string_8 (utf8_data) implies
				converter.utf_32_string_to_utf_8_string_8 (Result).same_string (utf8_data)
		end

	convert_string_to_utf8 (text: STRING_32): STRING_8
			-- Convert `text` to UTF-8 encoding.
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.string_32_to_utf_8_string_8 (text)
		ensure
			roundtrip: converter.utf_8_string_8_to_string_32 (Result).same_string (text)
		end
```

**2. UTF-16 ↔ UTF-32 Conversion:**
```eiffel
feature -- UTF-16 Handling

	convert_utf16_to_string (utf16_data: STRING_8): STRING_32
			-- Convert UTF-16LE encoded `utf16_data` to STRING_32.
		require
			even_count: (utf16_data.count & 1) = 0
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.utf_16le_string_8_to_string_32 (utf16_data)
		end

	convert_string_to_utf16 (text: STRING_32): STRING_8
			-- Convert `text` to UTF-16LE encoding.
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.utf_32_string_to_utf_16le_string_8 (text)
		end
```

**3. Validation:**
```eiffel
feature -- Validation

	is_valid_utf8 (data: STRING_8): BOOLEAN
			-- Is `data` a valid UTF-8 sequence?
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.is_valid_utf_8_string_8 (data)
		end
```

**4. Escaped String Handling:**

The `UTF_CONVERTER` provides "escaped" variants that handle invalid UTF sequences by using a replacement character (U+FFFD) followed by hexadecimal codes. This enables roundtrip conversion even with invalid encodings.

```eiffel
feature -- Escaped Conversion

	safe_utf8_conversion (data: STRING_8): STRING_32
			-- Convert UTF-8 `data` to STRING_32, escaping invalid sequences.
		local
			converter: UTF_CONVERTER
		do
			create converter
			Result := converter.utf_8_string_8_to_escaped_string_32 (data)
		ensure
			roundtrip: converter.escaped_utf_32_string_to_utf_8_string_8 (Result).same_string (data)
		end
```

### Byte Order Mark (BOM) Constants

```eiffel
feature -- BOM Detection

	detect_utf_encoding (data: STRING_8): STRING
			-- Detect UTF encoding from BOM.
		local
			converter: UTF_CONVERTER
		do
			create converter
			if data.starts_with (converter.utf_8_bom_to_string_8) then
				Result := "UTF-8"
			elseif data.starts_with (converter.utf_16le_bom_to_string_8) then
				Result := "UTF-16LE"
			elseif data.starts_with (converter.utf_16be_bom_to_string_8) then
				Result := "UTF-16BE"
			elseif data.starts_with (converter.utf_32le_bom_to_string_8) then
				Result := "UTF-32LE"
			elseif data.starts_with (converter.utf_32be_bom_to_string_8) then
				Result := "UTF-32BE"
			else
				Result := "Unknown"
			end
		end
```

## Complete Example

```eiffel
note
	description: "Demonstrates string handling and UTF conversion."

class
	TEXT_PROCESSOR

create
	make

feature -- Initialization

	make
			-- Initialize processor.
		do
			create converter
		end

feature -- Access

	converter: UTF_CONVERTER
			-- UTF encoding converter.

feature -- Processing

	process_multilingual_text (text: STRING_32): STRING_32
			-- Process `text` with Unicode support.
		require
			text_exists: text /= Void
		local
			temp: STRING_32
		do
			create Result.make_from_string (text)
			Result.to_upper
			Result.prepend ("Processed: ")
		ensure
			has_prefix: Result.starts_with ("Processed: ")
		end

	load_utf8_file_content (utf8_content: STRING_8): STRING_32
			-- Convert UTF-8 file content to STRING_32.
		require
			valid_utf8: converter.is_valid_utf_8_string_8 (utf8_content)
		do
			Result := converter.utf_8_string_8_to_string_32 (utf8_content)
		ensure
			roundtrip: converter.string_32_to_utf_8_string_8 (Result).same_string (utf8_content)
		end

	save_as_utf8 (text: STRING_32): STRING_8
			-- Convert `text` to UTF-8 for file storage.
		require
			text_exists: text /= Void
		do
			Result := converter.string_32_to_utf_8_string_8 (text)
		ensure
			roundtrip: converter.utf_8_string_8_to_string_32 (Result).same_string (text)
		end

invariant
	converter_exists: converter /= Void

end
```

## Rules Summary

1. **Prefer STRING_32** for new code to ensure Unicode support
2. **Use READABLE_STRING_GENERAL** for formal arguments accepting any string variant
3. **Use UTF_CONVERTER** for encoding conversions between UTF-8, UTF-16, and UTF-32
4. **Use `io.put_string_32`** for Unicode output to standard output
5. **Validate UTF sequences** before conversion using `is_valid_utf_8_string_8` and similar features
6. **Use escaped variants** when you need guaranteed roundtrip conversion with potentially invalid encodings
7. **Be aware** that `STRING` may map to either `STRING_8` or `STRING_32` depending on library configuration
8. **Use `detachable`** when a feature may return `Void`

---
---
# 15. Compilation & Verification Commands
Use these commands to verify changes (replace <PROJECT_NAME> with the detected name):

- Compile Main:
  ec -config <PROJECT_NAME>.ecf -target <PROJECT_NAME> [-clean] -c_compile -finalize
	-- Use -clean to delete previous build and perform a fresh compilation.

- Compile & Run Tests (with AutoTest):
  ec -config <PROJECT_NAME>.ecf -target tests -c_compile -finalize -tests 
	-- Use -clean to delete previous build and perform a fresh compilation.


## Compilation Rules

- Use -clean to delete previous build and perform a fresh compilation.
- Use -finalize to finalize the build.
- Use -tests to run tests. (AutoTest doesn't have a filter to run an specific test)

---
# 16. Ask Before Coding

If the spec is ambiguous, the model must ask clarifying questions before generating Eiffel code.

---
# 17. Final Checklist (LLM MUST verify before generating)

- [ ] Class name is UPPERCASE  
- [ ] Feature names in snake_case  
- [ ] Proper class template used  
- [ ] Preconditions & postconditions included and labeled  
- [ ] Invariant included (if applicable)  
- [ ] All indentation uses TABs  
- [ ] Comments concise  
- [ ] No pseudo-eiffel  
- [ ] Command–Query separation preserved  
- [ ] No missing types  
- [ ] No unnecessary `/= Void` checks for attached types  
- [ ] `detachable` used only when `Void` is a valid value  
- [ ] Special characters in strings use proper escape sequences (`%N`, `%T`, `%"`, etc.)  
- [ ] Once classes have `once` keyword before `class` and all creation procedures are once procedures  
- [ ] Allways use the compiler to double check the generated code.

---

# 18. Example (Reference)

```eiffel
note
	description: "Represents a person with name and age."

class
	PERSON

create
	make

feature -- Initialization

	make (a_name: STRING; an_age: INTEGER)
			-- Initialize with name and age.
		require
			age_non_negative: an_age >= 0
		do
			name := a_name
			age := an_age
		ensure
			name_set: name = a_name
			age_set: age = an_age
		end

feature -- Access

	name: STRING
			-- Person's name.

	age: INTEGER
			-- Age in years.

feature -- Element Change

	set_age (new_age: INTEGER)
			-- Set `age` to `new_age`.
		require
			age_non_negative: new_age >= 0
		do
			age := new_age
		ensure
			age_updated: age = new_age
		end

invariant
	valid_age: age >= 0

end
```