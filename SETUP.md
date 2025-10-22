# Setup Guide

## Prerequisites

This project requires OCaml and the opam package manager. Follow the steps below to set up your development environment.

### 1. Install opam (OCaml Package Manager)

#### macOS
```bash
brew install opam
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install opam
```

#### Other Systems
Visit: https://opam.ocaml.org/doc/Install.html

### 2. Initialize opam

```bash
opam init
eval $(opam env)
```

If you already have opam installed, make sure it's up to date:
```bash
opam update
opam upgrade
```

### 3. Install OCaml Compiler

Install OCaml 4.14 or newer:
```bash
opam switch create 4.14.0
eval $(opam env)
```

Or use an existing switch:
```bash
opam switch 4.14.0
eval $(opam env)
```

### 4. Install Project Dependencies

From the project root directory:

```bash
opam install dune menhir alcotest qcheck --yes
```

Or use the Makefile:
```bash
make install
```

## Building the Project

### Build Everything

```bash
dune build
```

Or:
```bash
make build
```

### Build and Install Executable

```bash
dune build @install
dune install
```

After installation, you can run:
```bash
interpreters_translators help
```

## Running Tests

```bash
dune runtest
```

Or:
```bash
make test
```

## Development Workflow

### 1. Build After Changes
```bash
dune build
```

### 2. Run Interpreter (without installation)
```bash
# LOOP
dune exec interpreters_translators -- loop examples/loop/factorial.loop

# WHILE
dune exec interpreters_translators -- while examples/while/fibonacci.while

# GOTO
dune exec interpreters_translators -- goto examples/goto/addition.goto
```

### 3. Run with Trace Mode
```bash
dune exec interpreters_translators -- loop examples/loop/factorial.loop --trace
```

### 4. Run Translators
```bash
# LOOP to WHILE
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop

# WHILE to GOTO
dune exec interpreters_translators -- translate while-to-goto examples/while/fibonacci.while

# GOTO to WHILE
dune exec interpreters_translators -- translate goto-to-while examples/goto/addition.goto
```

### 5. Verify Translation
```bash
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop --verify
```

## IDE Setup

### Visual Studio Code

1. Install the "OCaml Platform" extension
2. Open the project folder
3. The extension will automatically detect the project structure

### Emacs

Install `tuareg-mode` and `merlin`:
```bash
opam install merlin tuareg
```

### Vim/Neovim

Install `merlin` for OCaml:
```bash
opam install merlin
```

## Troubleshooting

### "command not found: dune"

Make sure you've run:
```bash
eval $(opam env)
```

### "Error: Unbound module X"

Try cleaning and rebuilding:
```bash
dune clean
dune build
```

### Parser/Lexer Changes Not Reflected

Menhir and ocamllex files need to be regenerated:
```bash
dune clean
dune build
```

### Missing Dependencies

```bash
opam install . --deps-only --with-test
```

## Project Structure Quick Reference

```
src/
├── common/          # Shared state and utilities
├── loop/            # LOOP language (AST, lexer, parser, interpreter)
├── while_lang/      # WHILE language
├── goto/            # GOTO language
├── translators/     # Language translators
└── main.ml          # CLI entry point

test/                # Test suites
examples/            # Example programs
```

## Next Steps

1. Read the main [README.md](README.md) for usage examples
2. Explore example programs in `examples/`
3. Run the test suite: `make test`
4. Try interpreting and translating programs
5. Extend the languages with new features (see thesis documentation)

## Common Commands Cheat Sheet

```bash
# Build
make build

# Run tests
make test

# Clean
make clean

# Interpret a LOOP program
dune exec interpreters_translators -- examples/loop/factorial.loop

# Translate with verification
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop --verify

# Help
dune exec interpreters_translators -- help
```

