# Architecture Documentation

## Overview

This project implements interpreters and translators for three theoretical programming languages from computability theory: LOOP, WHILE, and GOTO. The architecture is modular, with each language implemented as a separate library.

## Module Structure

### 1. Common (`src/common/`)

Shared utilities used across all three languages.

#### `state.ml`
- **Purpose**: Variable state management
- **Key Type**: `type t = int VarMap.t` (mapping variable names to natural numbers)
- **Operations**:
  - `empty`: Create empty state
  - `get`: Get variable value (returns 0 if undefined, per FSK semantics)
  - `set`: Set variable value
  - `to_string`: Pretty-print state

#### `utils.ml`
- **Purpose**: Helper functions
- **Functions**:
  - `read_file`/`write_file`: File I/O
  - `nat_sub`: Natural number subtraction (saturates at 0)
  - `fresh_var`/`fresh_label`: Generate unique identifiers for translations
  - `repeat`: Repeat a function n times

### 2. LOOP Language (`src/loop/`)

Implementation of the LOOP language (§10.1 of FSK script).

#### `ast.ml`
```ocaml
type expr =
  | Const of int
  | Var of string
  | Add of expr * expr
  | Sub of expr * expr
  | Mul of expr * expr

type program =
  | Skip
  | Assign of string * expr
  | Seq of program * program
  | Loop of string * program
```

**Key Property**: LOOP constructs have bounded iteration (number of iterations fixed at loop entry).

#### `lexer.mll` (OCamllex)
Tokenizes LOOP source code:
- Keywords: `LOOP`, `DO`, `END`, `SKIP`
- Operators: `:=`, `+`, `-`, `*`
- Comments: `(* ... *)`

#### `parser.mly` (Menhir)
Parses token stream into AST using LALR parser generator.

#### `interpreter.ml`
- **Function**: `eval_expr : expr -> State.t -> int`
  - Evaluates arithmetic expressions
  - Variables default to 0 if undefined
  
- **Function**: `exec : mode -> program -> State.t -> State.t`
  - Executes LOOP programs
  - `Loop (x, body)`: Evaluates `x` once at start, executes `body` that many times
  - Supports trace mode for step-by-step execution

### 3. WHILE Language (`src/while_lang/`)

Implementation of the WHILE language (§10.2 of FSK script).

#### `ast.ml`
Extends LOOP with boolean conditions:
```ocaml
type comp_op = Eq | Neq | Lt | Gt | Leq | Geq

type condition =
  | Compare of expr * comp_op * expr
  | And of condition * condition
  | Or of condition * condition
  | Not of condition

type program =
  | Skip
  | Assign of string * expr
  | Seq of program * program
  | While of condition * program
```

**Key Property**: WHILE loops have unbounded iteration (Turing-complete).

#### `interpreter.ml`
- **Function**: `eval_condition : condition -> State.t -> bool`
  - Evaluates boolean conditions
  
- **Function**: `exec : mode -> program -> State.t -> State.t`
  - `While (cond, body)`: Re-evaluates condition at each iteration
  - Includes iteration limit (`max_iterations`) to prevent infinite loops in testing

### 4. GOTO Language (`src/goto/`)

Implementation of the GOTO language (§10.3 of FSK script).

#### `ast.ml`
```ocaml
type instruction =
  | Skip
  | Assign of string * expr
  | Goto of string
  | IfGoto of expr * comp_op * expr * string
  | Halt

type labeled_instr = {
  label: string option;
  instr: instruction;
}

type program = labeled_instr list
```

**Key Property**: Sequential list of labeled instructions with explicit control flow.

#### `interpreter.ml`
- **Design**: Program counter (PC) based execution
- **Label Resolution**: Hash table maps labels to instruction indices
- **Execution**:
  1. Start at PC = 0
  2. Execute instruction at PC
  3. Update PC (sequential or jump)
  4. Stop at `HALT` or when PC exceeds program length

### 5. Translators (`src/translators/`)

#### `loop_to_while.ml`

**Theorem**: Every LOOP program can be translated to WHILE (LOOP ⊂ WHILE).

**Translation**:
```ocaml
LOOP x DO P END
  ⟹
tmp := x;
WHILE tmp ≠ 0 DO
  P;
  tmp := tmp - 1
END
```

**Correctness**: LOOP's bounded iteration is simulated by counting down a temporary variable.

#### `while_to_goto.ml`

**Theorem**: WHILE and GOTO are equivalent in expressive power (§10.4).

**Key Translations**:

1. **Sequential composition**: Direct mapping
2. **WHILE loop**:
```ocaml
WHILE c DO P END
  ⟹
L_start: IF NOT c THEN GOTO L_end
         P (translated)
         GOTO L_start
L_end:   SKIP
```

3. **Condition handling**:
   - Simple comparisons → `IfGoto`
   - `AND`/`OR` → Short-circuit evaluation with labels
   - `NOT` → Swap target labels

#### `goto_to_while.ml`

**Theorem**: Every GOTO program can be simulated in WHILE.

**Strategy**: Simulate program counter with a variable:
```ocaml
pc := 0;
WHILE pc ≠ -1 DO
  IF pc = 0 THEN ... execute instruction 0 ... pc := next
  ELSE IF pc = 1 THEN ... execute instruction 1 ... pc := next
  ...
END
```

**Challenges**:
- GOTO's conditional jumps simulated using nested WHILE loops
- Label table built at translation time
- Each instruction updates `pc` appropriately

**Note**: This translation is theoretically elegant but produces verbose code.

### 6. Main CLI (`src/main.ml`)

Command-line interface with two modes:

#### Interpret Mode
```bash
interpreters_translators <language> <file> [--trace]
```

1. Parse source file
2. Execute with interpreter
3. Display final state

#### Translate Mode
```bash
interpreters_translators translate <source-to-target> <file> [--verify] [--output <file>]
```

1. Parse source program
2. Apply translator
3. Pretty-print translated program
4. Optionally verify by executing both versions

## Design Principles

### 1. Separation of Concerns
Each language is a self-contained library with AST, parser, and interpreter.

### 2. Pure Functional Core
- Interpreters are pure functions: `program → state → state`
- State is immutable (functional maps)
- Side effects isolated to CLI layer

### 3. Type Safety
- ADTs encode language syntax precisely
- Pattern matching ensures exhaustive case handling
- Compiler enforces correctness

### 4. Modularity
- Easy to extend with new language features
- Translators depend only on language interfaces
- Testing each component in isolation

### 5. Theoretical Fidelity
- Implementation directly follows FSK script definitions
- Comments reference specific sections (e.g., §10.1.4)
- Preserves semantic properties (termination, expressiveness)

## Data Flow

### Interpretation Pipeline
```
Source File
    ↓
[Lexer] → Tokens
    ↓
[Parser] → AST
    ↓
[Interpreter] → Final State
    ↓
Display
```

### Translation Pipeline
```
Source File
    ↓
[Lexer] → Tokens
    ↓
[Parser] → Source AST
    ↓
[Translator] → Target AST
    ↓
[Pretty Printer] → Target Source Code
    ↓
(Optional) [Target Interpreter] → Verification
```

## Testing Strategy

### Unit Tests (`test/`)

1. **Interpreter Tests**: Verify correctness of each language
   - Basic operations (addition, multiplication)
   - Control flow (loops, conditionals)
   - Edge cases (zero iterations, false conditions)

2. **Translator Tests**: Verify translation correctness
   - Execute source and target programs with same input
   - Compare final states
   - Round-trip translations (LOOP→WHILE→GOTO)

### Property-Based Testing (Future)
- Use QCheck to generate random programs
- Verify semantic equivalence after translation

## Performance Considerations

### Time Complexity
- **LOOP**: O(program size × loop iterations)
- **WHILE**: O(program size × actual iterations)
- **GOTO**: O(program size × steps), with hash table label lookup

### Space Complexity
- State size: O(number of variables)
- AST size: O(program size)
- Call stack: O(nesting depth) for recursive interpreter

### Optimization Opportunities (Future Work)
1. Compile to bytecode for faster execution
2. Constant folding in expressions
3. Dead code elimination in GOTO
4. Tail-call optimization for LOOP

## Extension Points

### Adding New Language Features

1. **Subroutines**: Add `Call` and `Return` to AST
2. **Arrays**: Extend state to map variables to arrays
3. **I/O**: Add `Read` and `Write` instructions
4. **Macros**: Preprocessing layer before parsing

### Adding New Translations

1. Create new file in `src/translators/`
2. Implement AST conversion
3. Add test cases
4. Update CLI with new translation option

## Theoretical Foundations

### Computability Classes

```
LOOP (Primitive Recursive)
  ⊂
WHILE (μ-Recursive) ≡ GOTO
  =
Turing Machines
```

### Key Theorems Demonstrated

1. **LOOP ⊂ WHILE**: Ackermann function not LOOP-computable (§11.1.4)
2. **WHILE ≡ GOTO**: Mutual translation (§10.4)
3. **Church-Turing Thesis**: WHILE/GOTO Turing-complete (§10.5)

## References

- **FSK Script**: Chapter 10 (LOOP-, WHILE-, und GOTO-Berechenbarkeit)
- **Real World OCaml**: https://dev.realworldocaml.org/
- **Menhir Manual**: http://gallium.inria.fr/~fpottier/menhir/
- **Computability Theory**: Sipser, "Introduction to the Theory of Computation"

