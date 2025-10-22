# Quick Start Guide

Get up and running with the LOOP/WHILE/GOTO interpreters in 5 minutes!

## Prerequisites Check

```bash
# Check if you have OCaml/opam
ocaml --version
opam --version
```

If not installed, see [SETUP.md](SETUP.md) for installation instructions.

## Fast Setup (5 steps)

### 1. Install Dependencies

```bash
# Make sure opam is initialized
eval $(opam env)

# Install dependencies
opam install dune menhir alcotest --yes
```

### 2. Build the Project

```bash
dune build
```

### 3. Run Your First Program

```bash
# Try a LOOP program (factorial)
dune exec interpreters_translators -- examples/loop/factorial.loop

# Try a WHILE program (Fibonacci)
dune exec interpreters_translators -- examples/while/fibonacci.while

# Try a GOTO program (addition)
dune exec interpreters_translators -- examples/goto/addition.goto
```

### 4. Try Translation

```bash
# Translate LOOP to WHILE
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop

# Verify the translation is correct
dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop --verify
```

### 5. Run Tests

```bash
dune runtest
```

## Example Session

```bash
$ cd interpreters-translators_bachelorThesis
$ dune build
$ dune exec interpreters_translators -- examples/loop/factorial.loop

Interpreting loop program: examples/loop/factorial.loop
Program:
x0 := 1;
x2 := 1;
LOOP x1 DO
  x0 := (x0 * x2);
  x2 := (x2 + 1)
END

=== Final State ===
{ x0 = 120, x1 = 5, x2 = 6 }
```

## Common Commands

```bash
# Interpret with trace mode (step-by-step)
dune exec interpreters_translators -- loop examples/loop/addition.loop --trace

# Translate and save output
dune exec interpreters_translators -- translate while-to-goto examples/while/fibonacci.while -o output.goto

# Show help
dune exec interpreters_translators -- help

# Run all tests
dune runtest

# Clean build
dune clean
```

## Creating Your Own Program

### LOOP Example (`my_program.loop`)

```ocaml
(* Compute x0 = x1 + x2 *)
x0 := x1;
LOOP x2 DO
  x0 := x0 + 1
END
```

Run it:
```bash
dune exec interpreters_translators -- my_program.loop
```

### WHILE Example (`my_program.while`)

```ocaml
(* Compute x0 = x1 * x2 *)
x0 := 0;
WHILE x2 != 0 DO
  x0 := x0 + x1;
  x2 := x2 - 1
END
```

Run it:
```bash
dune exec interpreters_translators -- my_program.while
```

### GOTO Example (`my_program.goto`)

```ocaml
(* Compute x0 = max(x1, x2) *)
IF x1 >= x2 THEN GOTO FIRST;
x0 := x2;
GOTO END;

FIRST: x0 := x1;

END: HALT
```

Run it:
```bash
dune exec interpreters_translators -- my_program.goto
```

## Setting Initial Variables

Currently, variables default to 0. To test with specific values, modify the example files or extend the interpreter to accept initial state from command line.

**Future enhancement:**
```bash
dune exec interpreters_translators -- loop program.loop --set x1=5 --set x2=3
```

## Troubleshooting

### "Command not found: dune"

```bash
eval $(opam env)
```

### "Unbound module X"

```bash
dune clean
dune build
```

### Build Errors

Check that you have all dependencies:
```bash
opam install . --deps-only --with-test
```

## Next Steps

- ✅ Read the full [README.md](README.md) for comprehensive documentation
- ✅ Explore example programs in `examples/`
- ✅ Check out [ARCHITECTURE.md](ARCHITECTURE.md) to understand the implementation
- ✅ See [CONTRIBUTING.md](CONTRIBUTING.md) for extending the project
- ✅ Review test cases in `test/` for more usage examples

## Learning Resources

### LOOP Language
- Variables: `x0`, `x1`, `x2`, ...
- Assignment: `x0 := expr`
- Sequential: `P1; P2`
- Loop: `LOOP xi DO P END` (bounded iteration)
- Expressions: `+`, `-`, `*`, constants

### WHILE Language
- All LOOP features plus:
- Conditions: `x1 = 0`, `x1 != 0`, `x1 < x2`, etc.
- While loop: `WHILE condition DO P END` (unbounded)
- Boolean: `AND`, `OR`, `NOT`

### GOTO Language
- Instructions: `SKIP`, `xi := expr`, `GOTO label`, `HALT`
- Conditional jump: `IF condition THEN GOTO label`
- Labels: `LABEL: instruction`

## Example Workflows

### Test a LOOP program idea

```bash
# 1. Create file
cat > test.loop << 'EOF'
x0 := 0;
LOOP x1 DO
  x0 := x0 + 2
END
EOF

# 2. Run it
dune exec interpreters_translators -- test.loop

# 3. Translate to WHILE
dune exec interpreters_translators -- translate loop-to-while test.loop

# 4. Verify
dune exec interpreters_translators -- translate loop-to-while test.loop --verify
```

### Compare WHILE and GOTO

```bash
# Create WHILE program
cat > countdown.while << 'EOF'
x0 := 0;
WHILE x1 != 0 DO
  x0 := x0 + 1;
  x1 := x1 - 1
END
EOF

# Translate to GOTO
dune exec interpreters_translators -- translate while-to-goto countdown.while -o countdown.goto

# Run both
dune exec interpreters_translators -- countdown.while
dune exec interpreters_translators -- countdown.goto
```

## Getting Help

```bash
# Show all options
dune exec interpreters_translators -- --help

# Show specific examples
make help
```

Happy computing! 🚀

