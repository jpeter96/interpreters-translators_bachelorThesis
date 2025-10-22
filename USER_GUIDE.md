# Complete User Guide

## Table of Contents
1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Language Syntax](#language-syntax)
4. [Command Reference](#command-reference)
5. [Example Workflows](#example-workflows)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites
- macOS, Linux, or WSL on Windows
- 2GB free disk space
- Internet connection for initial setup

### Step 1: Install opam (if not already installed)

**macOS:**
```bash
brew install opam
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install opam
```

### Step 2: Initialize opam
```bash
opam init --auto-setup --yes
eval $(opam env)
```

### Step 3: Install OCaml compiler
```bash
opam switch create 5.2.0 --yes
eval $(opam env --switch=5.2.0)
```

### Step 4: Install dependencies
```bash
cd interpreters-translators_bachelorThesis
opam install dune menhir alcotest --yes
```

### Step 5: Build the project
```bash
dune build
```

### Verify Installation
```bash
dune runtest  # Should show 17/17 tests passing
```

---

## Basic Usage

### Running Interpreters

#### LOOP Programs
```bash
# Basic execution
dune exec interpreters_translators -- loop examples/loop/simple_test.loop

# With trace mode
dune exec interpreters_translators -- loop examples/loop/simple_test.loop --trace
```

#### WHILE Programs
```bash
# Basic execution
dune exec interpreters_translators -- while examples/while/countdown_test.while

# Auto-detect language from extension
dune exec interpreters_translators -- examples/while/countdown_test.while
```

#### GOTO Programs
```bash
# Basic execution
dune exec interpreters_translators -- goto examples/goto/add_test.goto

# With trace mode
dune exec interpreters_translators -- examples/goto/add_test.goto --trace
```

### Running Translators

#### LOOP to WHILE
```bash
# Basic translation
dune exec interpreters_translators -- translate loop-to-while examples/loop/simple_test.loop

# With verification
dune exec interpreters_translators -- translate loop-to-while examples/loop/simple_test.loop --verify

# Save to file
dune exec interpreters_translators -- translate loop-to-while examples/loop/simple_test.loop -o output.while
```

#### WHILE to GOTO
```bash
# Basic translation
dune exec interpreters_translators -- translate while-to-goto examples/while/countdown_test.while

# With verification
dune exec interpreters_translators -- translate while-to-goto examples/while/countdown_test.while --verify
```

#### GOTO to WHILE
```bash
# Basic translation
dune exec interpreters_translators -- translate goto-to-while examples/goto/add_test.goto

# With verification
dune exec interpreters_translators -- translate goto-to-while examples/goto/add_test.goto --verify
```

---

## Language Syntax

### LOOP Language

**Grammar:**
```
Program ::= Statement
Statement ::= 
  | SKIP
  | Variable := Expression
  | Statement ; Statement
  | LOOP Variable DO Statement END

Expression ::=
  | Number                    (e.g., 0, 1, 42)
  | Variable                  (e.g., x0, x1, x2)
  | Expression + Expression
  | Expression - Expression   (saturating subtraction)
  | Expression * Expression
  | ( Expression )
```

**Example:**
```ocaml
(* Compute x0 = x1 + x2 *)
x0 := x1;
LOOP x2 DO
  x0 := x0 + 1
END
```

**Key Properties:**
- All loops are bounded (iteration count fixed at loop entry)
- Subtraction saturates at 0 (natural number semantics)
- All variables start at 0
- Corresponds to primitive recursive functions
- **Always terminates**

---

### WHILE Language

**Grammar:**
```
Program ::= Statement
Statement ::= 
  | SKIP
  | Variable := Expression
  | Statement ; Statement
  | WHILE Condition DO Statement END

Condition ::=
  | Expression = Expression
  | Expression != Expression
  | Expression < Expression
  | Expression > Expression
  | Expression <= Expression
  | Expression >= Expression
  | Condition AND Condition
  | Condition OR Condition
  | NOT Condition
  | ( Condition )

Expression ::= (same as LOOP)
```

**Example:**
```ocaml
(* Compute x0 = x1 * x2 *)
x0 := 0;
WHILE x2 != 0 DO
  x0 := x0 + x1;
  x2 := x2 - 1
END
```

**Key Properties:**
- Unbounded iteration (loop may run forever)
- Condition re-evaluated each iteration
- Turing-complete
- **May not terminate**

---

### GOTO Language

**Grammar:**
```
Program ::= LabeledInstruction ; ... ; LabeledInstruction

LabeledInstruction ::=
  | Instruction
  | Label : Instruction

Instruction ::=
  | SKIP
  | Variable := Expression
  | GOTO Label
  | IF Expression CompOp Expression THEN GOTO Label
  | HALT

CompOp ::= = | != | < | > | <= | >=
```

**Example:**
```ocaml
(* Compute x0 = max(x1, x2) *)
IF x1 >= x2 THEN GOTO FIRST;
x0 := x2;
GOTO END;

FIRST: x0 := x1;

END: HALT
```

**Key Properties:**
- Sequential list of instructions
- Explicit control flow with labels
- Program counter-based execution
- Equivalent to WHILE (both Turing-complete)
- **May not terminate**

---

## Command Reference

### Interpreter Mode

```bash
interpreters_translators <language> <file> [options]
interpreters_translators <file> [options]  # Auto-detect language
```

**Languages:** `loop`, `while`, `goto`

**Options:**
- `-t, --trace` - Enable step-by-step execution tracing

**Examples:**
```bash
# Execute LOOP program
dune exec interpreters_translators -- loop program.loop

# Execute with trace
dune exec interpreters_translators -- program.while --trace

# Auto-detect language from .goto extension
dune exec interpreters_translators -- program.goto
```

### Translator Mode

```bash
interpreters_translators translate <translation> <file> [options]
```

**Translations:**
- `loop-to-while` - LOOP → WHILE (always possible)
- `while-to-goto` - WHILE → GOTO (equivalence)
- `goto-to-while` - GOTO → WHILE (equivalence)

**Options:**
- `-v, --verify` - Verify translation by executing both versions
- `-o, --output <file>` - Save translated program to file

**Examples:**
```bash
# Translate LOOP to WHILE
dune exec interpreters_translators -- translate loop-to-while program.loop

# Translate with verification
dune exec interpreters_translators -- translate while-to-goto program.while --verify

# Save output
dune exec interpreters_translators -- translate goto-to-while program.goto -o output.while
```

### Other Commands

```bash
# Show help
dune exec interpreters_translators -- help

# Run test suite
dune runtest

# Build project
dune build

# Clean build
dune clean
```

---

## Example Workflows

### Workflow 1: Write and Test a LOOP Program

**Step 1: Create program**
```bash
cat > my_program.loop << 'EOF'
(* Compute 3^2 = 9 *)
x1 := 3;
x0 := 0;

LOOP x1 DO
  LOOP x1 DO
    x0 := x0 + 1
  END
END
EOF
```

**Step 2: Run it**
```bash
dune exec interpreters_translators -- my_program.loop
```

**Expected output:**
```
=== Final State ===
{ x0 = 9, x1 = 3 }
```

**Step 3: Translate to WHILE**
```bash
dune exec interpreters_translators -- translate loop-to-while my_program.loop
```

**Step 4: Verify correctness**
```bash
dune exec interpreters_translators -- translate loop-to-while my_program.loop --verify
```

---

### Workflow 2: Compare WHILE and GOTO

**Step 1: Write WHILE program**
```bash
cat > fibonacci.while << 'EOF'
(* Compute 7th Fibonacci number *)
x1 := 7;
x0 := 0;
x2 := 1;
x3 := 0;

WHILE x1 != 0 DO
  x3 := x0 + x2;
  x0 := x2;
  x2 := x3;
  x1 := x1 - 1
END
EOF
```

**Step 2: Run WHILE version**
```bash
dune exec interpreters_translators -- fibonacci.while
# Result: x0 = 13 (7th Fibonacci number)
```

**Step 3: Translate to GOTO**
```bash
dune exec interpreters_translators -- translate while-to-goto fibonacci.while -o fibonacci.goto
```

**Step 4: Run GOTO version**
```bash
dune exec interpreters_translators -- fibonacci.goto
# Result: x0 = 13 (same result!)
```

---

### Workflow 3: Debug with Trace Mode

**Step 1: Create program**
```bash
cat > debug_me.goto << 'EOF'
x0 := 5;
x1 := 0;

LOOP: IF x0 = 0 THEN GOTO END;
x1 := x1 + x0;
x0 := x0 - 1;
GOTO LOOP;

END: HALT
EOF
```

**Step 2: Run with trace**
```bash
dune exec interpreters_translators -- debug_me.goto --trace
```

**Output shows each step:**
```
[PC=0]     x0 := 5
State: { (empty state) }

[PC=1]     x1 := 0
State: { x0 = 5 }

[PC=2] LOOP: IF x0 = 0 THEN GOTO END
State: { x0 = 5, x1 = 0 }

[PC=3]     x1 := (x1 + x0)
State: { x0 = 5, x1 = 0 }

[PC=4]     x0 := (x0 - 1)
State: { x0 = 5, x1 = 5 }
...
```

---

## Advanced Features

### Comments

All three languages support OCaml-style comments:
```ocaml
(* This is a comment *)
x0 := 1;  (* Inline comment *)

(* Multi-line
   comment *)
```

### Variable Naming

Variables must follow the pattern: `x` followed by digits
```ocaml
x0 := 1;   (* Valid *)
x1 := 2;   (* Valid *)
x42 := 3;  (* Valid *)
myVar := 4; (* Invalid! *)
```

### Natural Number Semantics

All values are natural numbers (≥ 0):
```ocaml
x0 := 5;
x1 := 3;
x2 := x0 - x1;  (* x2 = 2 *)

x3 := 2;
x4 := 5;
x5 := x3 - x4;  (* x5 = 0, NOT -3! *)
```

### Operator Precedence

From highest to lowest:
1. Parentheses `( )`
2. Multiplication `*`
3. Addition `+`, Subtraction `-` (left-to-right)

```ocaml
x0 := 2 + 3 * 4;    (* x0 = 14, not 20 *)
x1 := (2 + 3) * 4;  (* x1 = 20 *)
```

### Initial State

All variables start at 0:
```ocaml
x0 := x1 + 1;  (* x1 is 0, so x0 = 1 *)
```

To use specific values, assign them first:
```ocaml
x1 := 5;
x0 := x1 + 1;  (* Now x0 = 6 *)
```

---

## Troubleshooting

### Build Errors

**Error:** `command not found: dune`
```bash
eval $(opam env)
```

**Error:** `Error: Unbound module X`
```bash
dune clean
dune build
```

**Error:** `Error: 'menhir' is available only when...`
- Already fixed in dune-project (using menhir 2.1)
- Run `dune build` again

### Parse Errors

**Error:** `Parse error at position X`
- Check for missing semicolons between statements
- Ensure all loops/conditions have matching DO/END
- Verify variable names follow `x[0-9]+` pattern

**Example of common mistake:**
```ocaml
(* WRONG *)
x0 := 1
x1 := 2  (* Missing semicolon! *)

(* CORRECT *)
x0 := 1;
x1 := 2
```

### Runtime Errors

**Error:** `Infinite loop detected`
- WHILE/GOTO programs may not terminate
- Increase iteration limit in interpreter (see TECHNICAL_GUIDE.md)
- Or fix your logic to ensure termination

**Error:** `Undefined label: X`
- GOTO program references non-existent label
- Check label spelling
- Ensure label is defined before GOTO instruction

### Translation Issues

**Verification fails** (states differ):
- This is often due to temporary variables introduced by translation
- Check that **important variables** (x0, x1, etc.) match
- Temporary variables (loop_0, pc_0, etc.) are implementation details

**Example:**
```
LOOP  final state: { x0 = 8, x1 = 5, x2 = 3 }
WHILE final state: { loop_0 = 0, x0 = 8, x1 = 5, x2 = 3 }
✗ Translation verification failed: states differ!
```
☝️ This is OK! The important variables (x0, x1, x2) match.

---

## Performance Tips

### For Large Programs

1. **Disable trace mode** in production (huge speedup)
2. **Use LOOP when possible** (guaranteed termination)
3. **Avoid deep nesting** (each level multiplies iterations)

### Optimization Examples

**Inefficient:**
```ocaml
(* O(n²) addition! *)
x0 := 0;
LOOP x1 DO
  LOOP x2 DO
    x0 := x0 + 1
  END
END
```

**Efficient:**
```ocaml
(* O(n) addition *)
x0 := x1;
LOOP x2 DO
  x0 := x0 + 1
END
```

---

## Testing Your Programs

### Manual Testing

Create test inputs and expected outputs:
```bash
# Create test program
cat > test.loop << 'EOF'
x1 := 5;
x2 := 3;
x0 := x1;
LOOP x2 DO
  x0 := x0 + 1
END
EOF

# Run and check
dune exec interpreters_translators -- test.loop
# Verify x0 = 8 (5 + 3)
```

### Automated Testing

Add to test suite (see CONTRIBUTING.md):
```ocaml
let test_my_feature () =
  let prog = Loop.Ast.(...) in
  let result = Loop.Interpreter.run_empty prog in
  Alcotest.(check int) "result" 8 (State.get result "x0")
```

---

## File Organization

```
my_project/
├── programs/
│   ├── loop/
│   │   ├── addition.loop
│   │   └── factorial.loop
│   ├── while/
│   │   ├── fibonacci.while
│   │   └── division.while
│   └── goto/
│       ├── max.goto
│       └── search.goto
└── outputs/
    ├── addition.while      (translated from LOOP)
    ├── fibonacci.goto      (translated from WHILE)
    └── results.txt         (execution outputs)
```

---

## Getting Help

### Documentation
- **USER_GUIDE.md** (this file) - How to use
- **TECHNICAL_GUIDE.md** - How it works internally
- **ARCHITECTURE.md** - System design
- **CONTRIBUTING.md** - Extending the system

### Commands
```bash
# Show help
dune exec interpreters_translators -- help

# Run examples
ls examples/*/

# Run tests
dune runtest
```

### Common Questions

**Q: Can I use negative numbers?**
A: No, all values are natural numbers (≥ 0). Subtraction saturates at 0.

**Q: Can I use floating-point numbers?**
A: No, only integers (natural numbers).

**Q: Why do variables start at 0?**
A: This follows the formal semantics from computability theory (FSK script).

**Q: Can I define functions/procedures?**
A: Not in the base languages. This could be added as an extension.

**Q: How do I input values?**
A: Currently, assign constants in your program. CLI input could be added.

**Q: Can LOOP programs run forever?**
A: No! LOOP always terminates (primitive recursive). WHILE/GOTO may not.

**Q: Why can't I translate WHILE to LOOP?**
A: Because WHILE is more powerful (Turing-complete) than LOOP (primitive recursive). Not all WHILE programs can be expressed in LOOP.

---

## Next Steps

1. ✅ Try the examples in `examples/`
2. ✅ Write your own programs
3. ✅ Experiment with translations
4. ✅ Read TECHNICAL_GUIDE.md to understand the implementation
5. ✅ Extend the system (see CONTRIBUTING.md)

---

*For technical implementation details, see TECHNICAL_GUIDE.md*
*For architectural overview, see ARCHITECTURE.md*

