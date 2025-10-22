# Contributing Guide

While this is a bachelor thesis project and not accepting external contributions, this document serves as a guide for extending and modifying the codebase.

## Development Setup

See [SETUP.md](SETUP.md) for initial setup instructions.

## Code Style

### OCaml Style Guidelines

1. **Indentation**: 2 spaces (no tabs)
2. **Line Length**: Maximum 100 characters
3. **Naming Conventions**:
   - Types: `snake_case`
   - Functions: `snake_case`
   - Modules: `PascalCase`
   - Constructors: `PascalCase`

4. **Pattern Matching**:
```ocaml
match expr with
| Constructor1 -> result1
| Constructor2 arg -> 
    let x = process arg in
    result2 x
| _ -> default
```

5. **Function Documentation**:
```ocaml
(** Brief description.
    
    @param name Description of parameter
    @return Description of return value
    @raise Exception When this exception is raised *)
let my_function name = ...
```

## Project Structure

```
src/
├── common/          # Shared utilities
│   ├── state.ml     # Variable state management
│   └── utils.ml     # Helper functions
├── loop/            # LOOP language
│   ├── ast.ml       # Abstract syntax tree
│   ├── lexer.mll    # Lexical analyzer
│   ├── parser.mly   # Parser grammar
│   └── interpreter.ml
├── while_lang/      # WHILE language
├── goto/            # GOTO language
├── translators/     # Language translators
└── main.ml          # CLI entry point

test/                # Test suites
examples/            # Example programs
```

## Adding a New Language Feature

### Example: Adding Boolean Variables

1. **Extend AST** (`src/*/ast.ml`):
```ocaml
type expr =
  | ...
  | Bool of bool
  | If of condition * expr * expr
```

2. **Update Lexer** (`src/*/lexer.mll`):
```ocaml
| "true"   { TRUE }
| "false"  { FALSE }
| "if"     { IF }
```

3. **Update Parser** (`src/*/parser.mly`):
```ocaml
%token TRUE FALSE IF

expr:
  | ...
  | TRUE { Bool true }
  | FALSE { Bool false }
  | IF c = condition THEN e1 = expr ELSE e2 = expr 
    { If (c, e1, e2) }
```

4. **Update Interpreter**:
```ocaml
let rec eval_expr (e : expr) (state : State.t) : int =
  match e with
  | ...
  | Bool b -> if b then 1 else 0
  | If (c, e1, e2) ->
      if eval_condition c state 
      then eval_expr e1 state
      else eval_expr e2 state
```

5. **Add Tests** (`test/test_*.ml`):
```ocaml
let test_boolean_if () =
  let prog = ... in
  let result = Interpreter.run_empty prog in
  Alcotest.(check int) "result" expected (State.get result "x0")
```

6. **Update Translators**: Ensure new features translate correctly.

## Adding a New Translator

### Example: Direct LOOP → GOTO Translation

1. **Create File**: `src/translators/loop_to_goto.ml`

2. **Implement Translation**:
```ocaml
(** Translate LOOP programs directly to GOTO *)

let rec translate (p : Loop.Ast.program) : Goto.Ast.program =
  match p with
  | Loop.Ast.Skip -> [{ label = None; instr = Goto.Ast.Skip }]
  | Loop.Ast.Assign (x, e) -> ...
  | Loop.Ast.Seq (p1, p2) -> (translate p1) @ (translate p2)
  | Loop.Ast.Loop (x, body) ->
      (* Generate GOTO code for bounded loop *)
      ...
```

3. **Add to dune**: `src/translators/dune`
```ocaml
(library
 (name translators)
 (modules loop_to_while while_to_goto goto_to_while loop_to_goto)
 (libraries common loop while_lang goto))
```

4. **Add CLI Support**: `src/main.ml`
```ocaml
| ("loop", "goto") ->
    let prog = parse_loop_file file in
    let translated = Translators.Loop_to_goto.translate prog in
    ...
```

5. **Add Tests**: `test/test_translators.ml`

## Writing Tests

### Unit Test Structure

```ocaml
open Alcotest

let test_feature () =
  (* Setup *)
  let input = ... in
  
  (* Execute *)
  let result = execute input in
  
  (* Assert *)
  Alcotest.(check int) "description" expected result

let () =
  run "Test Suite Name" [
    "category", [
      test_case "Feature name" `Quick test_feature;
      test_case "Edge case" `Quick test_edge_case;
    ]
  ]
```

### Running Specific Tests

```bash
# Run all tests
dune runtest

# Run specific test file
dune exec test/test_loop.exe

# Run with verbose output
dune runtest --verbose
```

## Building and Testing Workflow

```bash
# 1. Make changes to source files

# 2. Build (shows compilation errors)
dune build

# 3. Run tests
dune runtest

# 4. Test manually
dune exec interpreters_translators -- loop examples/loop/test.loop

# 5. Format code (if ocamlformat installed)
dune build @fmt --auto-promote

# 6. Clean build artifacts
dune clean
```

## Debugging Tips

### 1. Enable Trace Mode
```bash
dune exec interpreters_translators -- loop file.loop --trace
```

### 2. Print Intermediate ASTs
```ocaml
Printf.printf "AST: %s\n" (Ast.string_of_program prog)
```

### 3. Use OCaml Debugger
```bash
dune exec --profile dev -- ocamldebug _build/default/src/main.exe
```

### 4. Add Debug Output
```ocaml
let () = Printf.printf "Debug: x = %d\n" x
```

## Common Issues

### Parser Conflicts

If Menhir reports shift/reduce conflicts:

1. Check operator precedence in `parser.mly`
2. Use `menhir --explain` for detailed conflict explanation:
```bash
menhir --explain src/loop/parser.mly
cat src/loop/parser.conflicts
```

### Lexer Errors

For ambiguous token patterns:
1. Order rules from most specific to most general
2. Use `--trace` to see token stream

### Type Errors

OCaml's type errors can be cryptic. Tips:
1. Read error from bottom to top
2. Check function signatures
3. Use type annotations to narrow down issues:
```ocaml
let result : int = my_function arg
```

## Documentation

### Generating Documentation

```bash
dune build @doc
open _build/default/_doc/_html/index.html
```

### Documentation Comments

Use odoc format:
```ocaml
(** Module description. *)

(** Function description.
    
    Example:
    {[
      let result = my_function 42 "test"
    ]}
    
    @param x First parameter
    @param y Second parameter
    @return Computed result
    @raise Invalid_argument If x is negative *)
val my_function : int -> string -> result
```

## Performance Profiling

### Time Profiling

```bash
# Compile with profiling
dune build --profile release

# Run with timing
time dune exec interpreters_translators -- loop examples/loop/large.loop
```

### Memory Profiling

```bash
# Use OCaml's memory profiler
OCAMLRUNPARAM=h dune exec interpreters_translators -- ...
```

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and commit
git add .
git commit -m "Add feature X"

# Keep branch up to date
git fetch origin
git rebase origin/main

# Push changes
git push origin feature/my-feature
```

## Release Checklist

- [ ] All tests pass (`dune runtest`)
- [ ] Code builds without warnings (`dune build`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Example programs work
- [ ] README.md reflects current features

## Resources

- **OCaml Manual**: https://ocaml.org/manual/
- **Real World OCaml**: https://dev.realworldocaml.org/
- **Dune Documentation**: https://dune.readthedocs.io/
- **Menhir Manual**: http://gallium.inria.fr/~fpottier/menhir/
- **FSK Script**: Chapter 10 (provided by course)

## Questions?

For questions about this thesis project, contact the author or refer to the thesis documentation.

