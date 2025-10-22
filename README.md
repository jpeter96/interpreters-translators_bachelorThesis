# Interpreters and Translators for LOOP, WHILE, and GOTO Languages

Bachelor thesis project at Ludwig-Maximilians-Universität München (LMU)  
Course: **Formale Sprachen und Komplexität**  
Supervisor: Professor Blanchette

## Overview

This project implements interpreters and translators (transpilers) for three foundational programming languages from computability theory:

- **LOOP**: Models primitive recursive functions (guaranteed termination)
- **WHILE**: Models μ-recursive functions (Turing-complete)
- **GOTO**: Models imperative computation with labels and jumps

These languages are defined in Chapter 10 of the FSK lecture notes.

## Features

### Interpreters
- ✅ LOOP interpreter with bounded iteration
- ✅ WHILE interpreter with unbounded loops
- ✅ GOTO interpreter with label-based control flow
- ✅ Step-by-step execution tracing (optional)
- ✅ Variable state inspection

### Translators
- ✅ LOOP → WHILE (always possible)
- ✅ WHILE → GOTO (computability equivalence)
- ✅ GOTO → WHILE (computability equivalence)
- ✅ Translation correctness verification

## Project Structure

```
interpreters-translators_bachelorThesis/
├── src/
│   ├── common/          # Shared utilities and types
│   │   ├── state.ml     # Variable state management
│   │   └── utils.ml     # Helper functions
│   ├── loop/            # LOOP language implementation
│   │   ├── ast.ml       # Abstract syntax tree
│   │   ├── lexer.mll    # Lexer (OCamllex)
│   │   ├── parser.mly   # Parser (Menhir)
│   │   └── interpreter.ml
│   ├── while_lang/      # WHILE language implementation
│   │   ├── ast.ml
│   │   ├── lexer.mll
│   │   ├── parser.mly
│   │   └── interpreter.ml
│   ├── goto/            # GOTO language implementation
│   │   ├── ast.ml
│   │   ├── lexer.mll
│   │   ├── parser.mly
│   │   └── interpreter.ml
│   ├── translators/     # Language translators
│   │   ├── loop_to_while.ml
│   │   ├── while_to_goto.ml
│   │   └── goto_to_while.ml
│   └── main.ml          # CLI entry point
├── test/                # Test suite
│   ├── test_loop.ml
│   ├── test_while.ml
│   ├── test_goto.ml
│   └── test_translators.ml
├── examples/            # Example programs
│   ├── loop/
│   ├── while/
│   └── goto/
├── dune-project         # Dune build configuration
├── Makefile             # Build automation
└── README.md
```

## Installation

### Prerequisites

- **OCaml** (≥ 4.14.0)
- **opam** (OCaml package manager)
- **dune** (build system)

### Setup

```bash
# Install opam (if not already installed)
# macOS:
brew install opam

# Linux:
apt-get install opam  # or equivalent

# Initialize opam
opam init
eval $(opam env)

# Install dependencies
make install

# Build the project
make build
```

## Usage

### Running Interpreters

```bash
# Execute a LOOP program
dune exec interpreters_translators -- loop examples/loop/factorial.loop

# Execute a WHILE program
dune exec interpreters_translators -- while examples/while/fibonacci.while

# Execute a GOTO program
dune exec interpreters_translators -- goto examples/goto/addition.goto

# Enable step-by-step tracing
dune exec interpreters_translators -- loop --trace examples/loop/factorial.loop
```

### Running Translators

```bash
# Translate LOOP to WHILE
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop

# Translate WHILE to GOTO
dune exec interpreters_translators -- translate while-to-goto examples/while/fibonacci.while

# Translate GOTO to WHILE
dune exec interpreters_translators -- translate goto-to-while examples/goto/addition.goto

# Verify translation correctness
dune exec interpreters_translators -- translate --verify loop-to-while examples/loop/factorial.loop
```

## Language Syntax

### LOOP Language

```
x0 := 0;
x1 := 5;
LOOP x1 DO
  x0 := x0 + 1
END
```

**Features:**
- Variable assignment
- Arithmetic operations (+, -, *)
- Bounded LOOP constructs (iteration count fixed at start)
- Sequential composition

### WHILE Language

```
x0 := 0;
x1 := 10;
WHILE x1 != 0 DO
  x0 := x0 + x1;
  x1 := x1 - 1
END
```

**Features:**
- All LOOP features
- Unbounded WHILE loops (condition-based)
- Comparison operators (=, !=, <, >, <=, >=)

### GOTO Language

```
x0 := 0;
x1 := 5;
L1: IF x1 = 0 THEN GOTO L2;
x0 := x0 + 1;
x1 := x1 - 1;
GOTO L1;
L2: HALT
```

**Features:**
- Variable assignment
- Labels and GOTO statements
- Conditional jumps (IF condition THEN GOTO label)
- HALT instruction

## Testing

```bash
# Run all tests
make test

# Run specific test suite
dune exec test/test_loop.exe
dune exec test/test_translators.exe
```

## Theoretical Background

### Computability Classes

| Language | Expressiveness | Termination | Reference (FSK Script) |
|----------|---------------|-------------|------------------------|
| **LOOP** | Primitive recursive functions | Always terminates | §10.1, §11.1.4 |
| **WHILE** | μ-recursive functions | May not terminate | §10.2, §11.2 |
| **GOTO** | Equivalent to WHILE | May not terminate | §10.3, §10.4 |

### Key Theorems

1. **LOOP ⊂ WHILE**: Not every WHILE program can be expressed in LOOP (Ackermann function)
2. **WHILE ≡ GOTO**: WHILE and GOTO have equivalent computational power (§10.4)
3. **Turing-completeness**: Both WHILE and GOTO can simulate Turing machines (§10.5)

## Development

### Building

```bash
make build        # Build the project
make clean        # Clean build artifacts
make test         # Run tests
```

### Project Dependencies

- **menhir**: Parser generator
- **alcotest**: Testing framework
- **qcheck**: Property-based testing (for translation correctness)

## Contributing

This is a bachelor thesis project. Contributions are not currently accepted, but feedback is welcome.

## License

MIT License - see [LICENSE](LICENSE) file

## References

- **FSK Lecture Script**: Chapter 10 (LOOP-, WHILE-, und GOTO-Berechenbarkeit)
- Professor Blanchette, LMU Munich
- Course: Formale Sprachen und Komplexität (Winter Semester 2025/26)

## Author

Your Name  
Bachelor Thesis, Computer Science  
Ludwig-Maximilians-Universität München
