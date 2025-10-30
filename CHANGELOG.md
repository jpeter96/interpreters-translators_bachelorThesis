# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-10-30

### Fixed
- **Translation Verification:** Verification now correctly compares only the original program variables, ignoring temporary variables introduced by translation (e.g., `loop_0`, `pc_0`, etc.)
  - Before: Verification would fail if temporary variables were present
  - After: Verification succeeds as long as all original variables match
  - Affects: `loop-to-while`, `while-to-goto`, `goto-to-while` translations

### Added
- `State.equal_on_vars`: Helper function to compare states on a specific set of variables
- `State.vars`: Helper function to extract all variable names from a state
- Better verification messages showing which variables were checked

### Technical Details

**Problem:**
```
LOOP  final state: { x0 = 8, x1 = 5, x2 = 3 }
WHILE final state: { loop_0 = 0, x0 = 8, x1 = 5, x2 = 3 }
✗ Translation verification failed: states differ!
```

The states differ because the WHILE translation introduces a temporary variable `loop_0` to count down the loop iterations. However, all original variables (x0, x1, x2) have identical values.

**Solution:**
The verification now:
1. Extracts the variable names from the original program's final state
2. Compares only those variables between source and target states
3. Ignores any temporary variables introduced by the translation

**Result:**
```
LOOP  final state: { x0 = 8, x1 = 5, x2 = 3 }
WHILE final state: { loop_0 = 0, x0 = 8, x1 = 5, x2 = 3 }
✓ Translation verified: all original variables match!
```

### Implementation

**File:** `src/common/state.ml`
```ocaml
(** Check if two states are equal on a subset of variables *)
let equal_on_vars (vars : string list) (state1 : t) (state2 : t) : bool =
  List.for_all (fun var ->
    get state1 var = get state2 var
  ) vars

(** Get all variable names in a state *)
let vars (state : t) : string list =
  List.map fst (to_list state)
```

**File:** `src/main.ml`
```ocaml
(* Compare only variables from original program *)
let original_vars = Common.State.vars state_loop in
let states_match = Common.State.equal_on_vars original_vars state_loop state_while in

if states_match then
  printf "✓ Translation verified: all original variables match!\n"
else (
  printf "✗ Translation verification failed: original variables differ!\n";
  printf "Variables checked: %s\n" (String.concat ", " original_vars)
)
```

---

## [1.0.0] - 2025-10-30

### Initial Release

Complete implementation of LOOP, WHILE, and GOTO interpreters and translators.

#### Features
- ✅ Three complete interpreters (LOOP, WHILE, GOTO)
- ✅ Three complete translators (LOOP→WHILE, WHILE→GOTO, GOTO→WHILE)
- ✅ Step-by-step trace mode
- ✅ Translation verification
- ✅ Comprehensive test suite (17 tests)
- ✅ Professional CLI
- ✅ Complete documentation (6,200+ lines)

#### Languages
- **LOOP:** Primitive recursive functions, bounded iteration
- **WHILE:** μ-recursive functions, unbounded iteration, Turing-complete
- **GOTO:** Label-based control flow, equivalent to WHILE

#### Documentation
- USER_GUIDE.md (60+ pages)
- TECHNICAL_GUIDE.md (80+ pages)
- ARCHITECTURE.md (30+ pages)
- CONTRIBUTING.md (40+ pages)
- SETUP.md (20+ pages)
- QUICKSTART.md (15+ pages)
- DEMO.md (25+ pages)
- README.md (40+ pages)

#### Testing
- 4 LOOP interpreter tests
- 4 WHILE interpreter tests
- 4 GOTO interpreter tests
- 5 translator tests (including round-trip)
- All tests passing

#### Performance
- Build time: ~5 seconds
- Test suite: ~0.01 seconds
- Example programs: Instant execution
- Translation: Real-time

---

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR:** Incompatible API changes
- **MINOR:** Add functionality in a backwards-compatible manner
- **PATCH:** Backwards-compatible bug fixes

---

## Future Enhancements (Planned)

### Version 1.2.0 (Planned)
- [ ] Command-line input for initial variable values
- [ ] Interactive REPL mode
- [ ] Step limit configuration for WHILE/GOTO
- [ ] Performance optimizations (constant folding, dead code elimination)

### Version 2.0.0 (Planned)
- [ ] Subroutines/procedures support
- [ ] Array support
- [ ] I/O operations (READ/WRITE)
- [ ] More detailed execution statistics
- [ ] Graphical execution visualization

### Version 3.0.0 (Planned)
- [ ] Web interface
- [ ] Visual debugger
- [ ] Interactive tutorial mode
- [ ] Program synthesis from examples

---

*For complete details, see the documentation in USER_GUIDE.md and TECHNICAL_GUIDE.md*

