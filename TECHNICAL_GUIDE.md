# Technical Implementation Guide

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Data Structures](#data-structures)
3. [Parser Implementation](#parser-implementation)
4. [Interpreter Implementation](#interpreter-implementation)
5. [Translator Implementation](#translator-implementation)
6. [Theoretical Foundations](#theoretical-foundations)
7. [Performance Analysis](#performance-analysis)
8. [Extension Points](#extension-points)

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                          CLI Layer                          │
│                         (main.ml)                           │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   Interpret         Translate
        │                 │
        │                 │
┌───────▼────────┐  ┌─────▼──────┐
│   Parsers      │  │ Translators│
│  ┌──────────┐  │  │            │
│  │ Lexer    │  │  └─────┬──────┘
│  │ (*.mll)  │  │        │
│  └────┬─────┘  │        │
│       │        │        │
│  ┌────▼─────┐  │        │
│  │ Parser   │  │        │
│  │ (*.mly)  │  │        │
│  └────┬─────┘  │        │
│       │        │        │
│  ┌────▼─────┐  │  ┌─────▼──────┐
│  │   AST    │──┼─▶│  AST → AST │
│  └──────────┘  │  │ Transform  │
└────────────────┘  └─────┬──────┘
                          │
                    ┌─────▼──────┐
                    │Interpreters│
                    │            │
                    │  Execute   │
                    │   AST      │
                    └────────────┘
```

### Module Hierarchy

```
interpreters_translators/
│
├── Common (shared utilities)
│   ├── State: Variable state management
│   └── Utils: Helper functions
│
├── LOOP (primitive recursive)
│   ├── Ast: Type definitions
│   ├── Lexer: Tokenization
│   ├── Parser: Grammar rules
│   └── Interpreter: Execution engine
│
├── WHILE (Turing-complete)
│   ├── Ast: Type definitions (extends LOOP)
│   ├── Lexer: Tokenization
│   ├── Parser: Grammar rules
│   └── Interpreter: Execution engine
│
├── GOTO (label-based)
│   ├── Ast: Type definitions
│   ├── Lexer: Tokenization
│   ├── Parser: Grammar rules
│   └── Interpreter: PC-based execution
│
├── Translators
│   ├── Loop_to_while: Bounded → unbounded
│   ├── While_to_goto: Structured → labels
│   └── Goto_to_while: Labels → PC simulation
│
└── Main: CLI interface
```

---

## Data Structures

### 1. State Management (`src/common/state.ml`)

**Purpose:** Store variable values during execution

**Implementation:**
```ocaml
module VarMap = Map.Make(String)
type t = int VarMap.t
```

**Why this design?**
- Immutable functional map (no side effects)
- O(log n) lookup/update
- Persistent data structure (old states preserved)
- Perfect for functional interpreters

**Key operations:**
```ocaml
val empty : t
(* Creates empty state. O(1) *)

val get : t -> string -> int
(* Returns variable value, 0 if undefined. O(log n) *)

val set : t -> string -> int -> t
(* Returns NEW state with updated variable. O(log n) *)
(* Original state unchanged! *)

val of_list : (string * int) list -> t
(* Batch initialization. O(n log n) *)
```

**Example usage:**
```ocaml
let state = State.empty
let state' = State.set state "x0" 5
let state'' = State.set state' "x1" 3
(* state is still empty! Immutability! *)

let x0 = State.get state'' "x0"  (* Returns 5 *)
let x2 = State.get state'' "x2"  (* Returns 0 (undefined) *)
```

**Theoretical justification:**
- FSK script: "Alle Variablen haben zu Beginn den Wert 0"
- Natural number semantics: ℕ = {0, 1, 2, ...}
- Undefined variables ≡ 0 by convention

---

### 2. LOOP AST (`src/loop/ast.ml`)

**Arithmetic Expressions:**
```ocaml
type expr =
  | Const of int                    (* 0, 1, 2, ... *)
  | Var of string                   (* x0, x1, x2, ... *)
  | Add of expr * expr              (* e1 + e2 *)
  | Sub of expr * expr              (* e1 ∸ e2 (monus) *)
  | Mul of expr * expr              (* e1 * e2 *)
```

**Programs:**
```ocaml
type program =
  | Skip                            (* No-op *)
  | Assign of string * expr         (* xi := e *)
  | Seq of program * program        (* P1 ; P2 *)
  | Loop of string * program        (* LOOP xi DO P END *)
```

**Why these constructors?**

1. **Skip:** Identity element for sequential composition
   ```ocaml
   Seq(P, Skip) ≡ Seq(Skip, P) ≡ P
   ```

2. **Assign:** Basic state transformation
   ```ocaml
   σ[xi ↦ ⟦e⟧σ]  (* State σ updated with new value *)
   ```

3. **Seq:** Sequential composition (monoid structure)
   ```ocaml
   Associative: Seq(Seq(P1, P2), P3) ≡ Seq(P1, Seq(P2, P3))
   Identity: Seq(P, Skip) ≡ P
   ```

4. **Loop:** Bounded iteration (key LOOP property!)
   ```ocaml
   (* Iteration count n = ⟦xi⟧σ fixed at entry *)
   LOOP xi DO P END ≡ P; P; ...; P  (n times)
   ```

**Example AST construction:**
```ocaml
(* x0 := 5; LOOP x1 DO x0 := x0 + 1 END *)
let prog = Seq (
  Assign ("x0", Const 5),
  Loop ("x1", 
    Assign ("x0", Add (Var "x0", Const 1))
  )
)
```

---

### 3. WHILE AST (`src/while_lang/ast.ml`)

**Extends LOOP with conditions:**

```ocaml
type comp_op = Eq | Neq | Lt | Gt | Leq | Geq

type condition =
  | Compare of expr * comp_op * expr    (* e1 op e2 *)
  | And of condition * condition        (* c1 ∧ c2 *)
  | Or of condition * condition         (* c1 ∨ c2 *)
  | Not of condition                    (* ¬c *)

type program =
  | Skip
  | Assign of string * expr
  | Seq of program * program
  | While of condition * program        (* WHILE c DO P END *)
```

**Key difference from LOOP:**
```ocaml
(* LOOP: iteration count fixed *)
Loop of string * program
  (* n = value of variable at loop entry *)
  (* Execute body exactly n times *)

(* WHILE: iteration count dynamic *)
While of condition * program
  (* Re-evaluate condition each iteration *)
  (* May execute 0, 1, 2, ..., or ∞ times *)
```

**Condition evaluation:**
```ocaml
⟦Compare(e1, op, e2)⟧σ = ⟦e1⟧σ op ⟦e2⟧σ
⟦And(c1, c2)⟧σ = ⟦c1⟧σ ∧ ⟦c2⟧σ
⟦Or(c1, c2)⟧σ = ⟦c1⟧σ ∨ ⟦c2⟧σ
⟦Not(c)⟧σ = ¬⟦c⟧σ
```

---

### 4. GOTO AST (`src/goto/ast.ml`)

**Sequential model:**

```ocaml
type instruction =
  | Skip                                (* No-op *)
  | Assign of string * expr             (* xi := e *)
  | Goto of string                      (* GOTO L *)
  | IfGoto of expr * comp_op * expr * string  (* IF e1 op e2 THEN GOTO L *)
  | Halt                                (* HALT *)

type labeled_instr = {
  label: string option;    (* Optional label *)
  instr: instruction;      (* The instruction *)
}

type program = labeled_instr list
```

**Why list-based?**
- GOTO programs are inherently sequential
- Program counter (PC) = index in list
- Natural representation for label resolution

**Label resolution:**
```ocaml
(* Build hash table: label → PC *)
let build_label_map (prog : program) : (string, int) Hashtbl.t =
  let tbl = Hashtbl.create 16 in
  List.iteri (fun idx li ->
    match li.label with
    | Some label -> Hashtbl.add tbl label idx
    | None -> ()
  ) prog;
  tbl
```

---

## Parser Implementation

### Two-Phase Approach

**Phase 1: Lexical Analysis (`.mll` files)**
```
Source text → Token stream
```

**Phase 2: Syntactic Analysis (`.mly` files)**
```
Token stream → AST
```

---

### Lexer (OCamllex)

**Example: `src/loop/lexer.mll`**

```ocaml
{
open Parser  (* Access to token types *)

exception Lexical_error of string
}

(* Regular expression definitions *)
let whitespace = [' ' '\t' '\r' '\n']+
let digit = ['0'-'9']
let number = digit+
let letter = ['a'-'z' 'A'-'Z']
let identifier = letter (letter | digit | '_')*

rule token = parse
  | whitespace      { token lexbuf }           (* Skip *)
  | "(*"            { comment lexbuf }         (* Nested comments *)
  | ":="            { ASSIGN }                 (* Operators *)
  | ";"             { SEMICOLON }
  | "+"             { PLUS }
  | "LOOP"          { LOOP }                   (* Keywords *)
  | "DO"            { DO }
  | "END"           { END }
  | number as n     { NUMBER (int_of_string n) }  (* Literals *)
  | identifier as s { IDENT s }                   (* Identifiers *)
  | eof             { EOF }
  | _ as c          { raise (Lexical_error (...)) }

and comment = parse
  | "*)"            { token lexbuf }           (* Exit comment *)
  | eof             { raise (Lexical_error "Unterminated comment") }
  | _               { comment lexbuf }         (* Continue *)
```

**How it works:**

1. **Regular expressions** define token patterns
2. **Rules** match patterns and return tokens
3. **Lexbuf** tracks position in input
4. **Recursion** handles nested structures (comments)

**Example tokenization:**
```
Input:  "x0 := x1 + 1"
Output: [IDENT "x0"; ASSIGN; IDENT "x1"; PLUS; NUMBER 1; EOF]
```

---

### Parser (Menhir)

**Example: `src/loop/parser.mly`**

```ocaml
%{
open Ast
%}

/* Token declarations */
%token <int> NUMBER
%token <string> IDENT
%token ASSIGN SEMICOLON PLUS MINUS TIMES
%token LPAREN RPAREN
%token LOOP DO END SKIP
%token EOF

/* Precedence (lowest to highest) */
%left PLUS MINUS
%left TIMES

/* Entry point */
%start <Ast.program> program

%%

/* Grammar rules */
program:
  | p = stmt EOF { p }
  ;

stmt:
  | SKIP { Skip }
  | IDENT ASSIGN e = expr { Assign ($1, e) }
  | p1 = stmt SEMICOLON p2 = stmt { Seq (p1, p2) }
  | LOOP x = IDENT DO p = stmt END { Loop (x, p) }
  | LPAREN p = stmt RPAREN { p }
  ;

expr:
  | n = NUMBER { Const n }
  | x = IDENT { Var x }
  | e1 = expr PLUS e2 = expr { Add (e1, e2) }
  | e1 = expr MINUS e2 = expr { Sub (e1, e2) }
  | e1 = expr TIMES e2 = expr { Mul (e1, e2) }
  | LPAREN e = expr RPAREN { e }
  ;
```

**How it works:**

1. **Token declarations** (`%token`) define terminal symbols
2. **Precedence** (`%left`, `%right`) resolves ambiguity
3. **Production rules** define grammar
4. **Semantic actions** (`{ ... }`) build AST

**Example parse:**
```
Input:  [IDENT "x0"; ASSIGN; NUMBER 5; EOF]
Rule:   stmt → IDENT ASSIGN expr
Action: Assign ("x0", Const 5)
Result: AST node
```

**Precedence handling:**
```
Input: "2 + 3 * 4"

Without precedence:
  Could parse as: (2 + 3) * 4 = 20  OR  2 + (3 * 4) = 14

With %left PLUS MINUS and %left TIMES:
  TIMES has higher precedence
  Result: Add(Const 2, Mul(Const 3, Const 4))
  Evaluates to: 2 + (3 * 4) = 14 ✓
```

---

## Interpreter Implementation

### 1. LOOP Interpreter (`src/loop/interpreter.ml`)

**Core evaluation functions:**

```ocaml
(** Evaluate arithmetic expression *)
let rec eval_expr (e : expr) (state : State.t) : int =
  match e with
  | Const n -> n
  | Var x -> State.get state x        (* 0 if undefined *)
  | Add (e1, e2) -> 
      eval_expr e1 state + eval_expr e2 state
  | Sub (e1, e2) -> 
      Utils.nat_sub (eval_expr e1 state) (eval_expr e2 state)
  | Mul (e1, e2) -> 
      eval_expr e1 state * eval_expr e2 state
```

**Why `Utils.nat_sub`?**
```ocaml
(* Natural number subtraction (monus) *)
let nat_sub (a : int) (b : int) : int =
  max 0 (a - b)

(* Examples *)
nat_sub 5 3  (* = 2 *)
nat_sub 3 5  (* = 0, NOT -2! *)
```

**Program execution:**

```ocaml
let rec exec (mode : mode) (p : program) (state : State.t) : State.t =
  match p with
  | Skip -> 
      state  (* Identity *)
  
  | Assign (x, e) ->
      let value = eval_expr e state in
      State.set state x value  (* New state! *)
  
  | Seq (p1, p2) ->
      let state' = exec mode p1 state in  (* Execute p1 *)
      exec mode p2 state'                  (* Execute p2 with new state *)
  
  | Loop (x, body) ->
      (* KEY INSIGHT: Iteration count fixed at loop entry! *)
      let n = State.get state x in
      
      (* Execute body n times *)
      let rec loop_n times s =
        if times <= 0 then s
        else loop_n (times - 1) (exec mode body s)
      in
      loop_n n state
```

**Correctness proof sketch:**

*Theorem:* LOOP interpreter terminates for all programs.

*Proof:* By structural induction on program P.

**Base cases:**
- `Skip`: Returns immediately. ✓
- `Assign`: Evaluates expression (terminates), updates state. ✓

**Inductive cases:**
- `Seq(P1, P2)`: By IH, P1 terminates. By IH, P2 terminates. ✓
- `Loop(x, P)`: 
  - Let n = value of x
  - By IH, P terminates
  - Execute P exactly n times (finite!)
  - Therefore Loop terminates. ✓

**Complexity:** O(program size × iterations)

---

### 2. WHILE Interpreter (`src/while_lang/interpreter.ml`)

**Condition evaluation:**

```ocaml
let eval_comp (e1 : expr) (op : comp_op) (e2 : expr) (state : State.t) : bool =
  let v1 = eval_expr e1 state in
  let v2 = eval_expr e2 state in
  match op with
  | Eq -> v1 = v2
  | Neq -> v1 <> v2
  | Lt -> v1 < v2
  | Gt -> v1 > v2
  | Leq -> v1 <= v2
  | Geq -> v1 >= v2

let rec eval_condition (c : condition) (state : State.t) : bool =
  match c with
  | Compare (e1, op, e2) -> eval_comp e1 op e2 state
  | And (c1, c2) -> eval_condition c1 state && eval_condition c2 state
  | Or (c1, c2) -> eval_condition c1 state || eval_condition c2 state
  | Not c -> not (eval_condition c state)
```

**WHILE loop execution:**

```ocaml
let rec exec_impl (iter_count : int) (p : program) (state : State.t) : State.t =
  (* Safety check: prevent infinite loops in testing *)
  if iter_count > max_iterations then
    raise (InfiniteLoop "Maximum iteration count exceeded")
  else
    match p with
    | Skip -> state
    | Assign (x, e) -> (* Same as LOOP *)
    | Seq (p1, p2) -> (* Same as LOOP *)
    
    | While (cond, body) ->
        (* KEY DIFFERENCE: Condition re-evaluated each iteration! *)
        if eval_condition cond state then
          let state' = exec_impl (iter_count + 1) body state in
          exec_impl (iter_count + 1) (While (cond, body)) state'
        else
          state  (* Condition false, exit loop *)
```

**Key insight: WHILE vs LOOP**

```ocaml
(* LOOP: Iteration count fixed *)
let n = State.get state x in  (* Evaluated ONCE *)
loop_n n state                (* Execute exactly n times *)

(* WHILE: Condition dynamic *)
if eval_condition cond state then  (* Evaluated EACH iteration *)
  ... recursive call ...
else
  state  (* Exit when condition becomes false *)
```

**Why may not terminate?**

Consider:
```ocaml
WHILE x0 = 0 DO
  x0 := 0  (* Condition always true! *)
END
```

**Iteration limit:**
```ocaml
let max_iterations = 100000  (* Safety net for testing *)
```

---

### 3. GOTO Interpreter (`src/goto/interpreter.ml`)

**Program Counter (PC) model:**

```ocaml
let exec (mode : mode) (prog : program) (initial_state : State.t) : State.t =
  let labels = build_label_map prog in      (* label → PC *)
  let prog_array = Array.of_list prog in    (* Fast indexed access *)
  let prog_len = Array.length prog_array in
  
  let rec step (pc : int) (state : State.t) (step_count : int) : State.t =
    (* Safety checks *)
    if step_count > max_steps then
      raise (InfiniteLoop "Maximum step count exceeded")
    else if pc >= prog_len then
      state  (* Program ends when PC exceeds length *)
    else
      let li = prog_array.(pc) in  (* Fetch instruction *)
      
      match li.instr with
      | Skip ->
          step (pc + 1) state (step_count + 1)  (* PC++ *)
      
      | Assign (x, e) ->
          let value = eval_expr e state in
          let state' = State.set state x value in
          step (pc + 1) state' (step_count + 1)  (* PC++ *)
      
      | Goto label ->
          let target_pc = Hashtbl.find labels label in  (* Lookup *)
          step target_pc state (step_count + 1)  (* PC := target *)
      
      | IfGoto (e1, op, e2, label) ->
          if eval_comp e1 op e2 state then
            let target_pc = Hashtbl.find labels label in
            step target_pc state (step_count + 1)  (* PC := target *)
          else
            step (pc + 1) state (step_count + 1)  (* PC++ *)
      
      | Halt ->
          state  (* Stop *)
  in
  
  step 0 initial_state 0  (* Start at PC=0 *)
```

**Execution model:**

```
Fetch-Decode-Execute cycle:
1. Fetch instruction at PC
2. Decode instruction type
3. Execute (may change PC)
4. Repeat until HALT or PC exceeds program
```

**Label resolution:**
```ocaml
(* Example program *)
    x0 := 1;           (* PC = 0 *)
LOOP: IF x0 = 0 THEN GOTO END;  (* PC = 1, label LOOP *)
    x0 := x0 + 1;      (* PC = 2 *)
    GOTO LOOP;         (* PC = 3 *)
END: HALT              (* PC = 4, label END *)

(* Label map *)
{ "LOOP" → 1, "END" → 4 }

(* Execution trace *)
PC=0: x0 := 1          → state = {x0=1}, PC := 1
PC=1: IF x0=0 GOTO END → false, PC := 2
PC=2: x0 := x0 + 1     → state = {x0=2}, PC := 3
PC=3: GOTO LOOP        → PC := 1
PC=1: IF x0=0 GOTO END → false, PC := 2
... (infinite loop!)
```

---

## Translator Implementation

### 1. LOOP → WHILE (`src/translators/loop_to_while.ml`)

**Theorem:** LOOP ⊂ WHILE (every LOOP program can be simulated in WHILE)

**Translation strategy:**

```ocaml
(* LOOP construct *)
LOOP xi DO P END

(* Translates to *)
tmp := xi;
WHILE tmp != 0 DO
  P;
  tmp := tmp - 1
END
```

**Implementation:**

```ocaml
let rec translate (p : Loop.Ast.program) : While_lang.Ast.program =
  match p with
  | Loop.Ast.Skip -> While_lang.Ast.Skip
  
  | Loop.Ast.Assign (x, e) ->
      While_lang.Ast.Assign (x, translate_expr e)
  
  | Loop.Ast.Seq (p1, p2) ->
      While_lang.Ast.Seq (translate p1, translate p2)
  
  | Loop.Ast.Loop (x, body) ->
      (* Generate fresh temporary variable *)
      let tmp = Common.Utils.fresh_var "loop_" in
      let body_while = translate body in
      
      (* tmp := x; WHILE tmp != 0 DO body; tmp := tmp - 1 END *)
      While_lang.Ast.Seq (
        While_lang.Ast.Assign (tmp, While_lang.Ast.Var x),
        While_lang.Ast.While (
          While_lang.Ast.Compare (
            While_lang.Ast.Var tmp, 
            While_lang.Ast.Neq, 
            While_lang.Ast.Const 0
          ),
          While_lang.Ast.Seq (
            body_while,
            While_lang.Ast.Assign (
              tmp, 
              While_lang.Ast.Sub (While_lang.Ast.Var tmp, While_lang.Ast.Const 1)
            )
          )
        )
      )
```

**Why this works:**

1. **Bounded → Unbounded:** LOOP's fixed iteration becomes countdown
2. **Temporary variable:** Preserves original variable value
3. **Countdown:** Ensures termination (mirrors LOOP semantics)

**Correctness proof:**

*Theorem:* For all LOOP programs P and states σ,
```
⟦P⟧ₗₒₒₚ σ = ⟦translate(P)⟧ᵥᵥₕᵢₗₑ σ
```

*Proof sketch:*
- By structural induction on P
- Key case: `Loop(x, body)`
  - Let n = σ(x)
  - LOOP executes body n times
  - WHILE: tmp := n; countdown from n
  - Both execute body exactly n times
  - QED

---

### 2. WHILE → GOTO (`src/translators/while_to_goto.ml`)

**Theorem:** WHILE and GOTO are equivalent (§10.4 FSK)

**Translation strategy:**

```ocaml
(* WHILE construct *)
WHILE c DO P END

(* Translates to *)
L_start: IF NOT c THEN GOTO L_end
         P (translated)
         GOTO L_start
L_end:   SKIP
```

**Condition decomposition:**

```ocaml
let rec translate_condition 
    (c : While_lang.Ast.condition) 
    (label_true : string)   (* Jump here if true *)
    (label_false : string)  (* Jump here if false *)
    : Goto.Ast.labeled_instr list =
  
  match c with
  | While_lang.Ast.Compare (e1, op, e2) ->
      (* Simple comparison: single IfGoto *)
      [
        { label = None; instr = IfGoto (e1', op', e2', label_true) };
        { label = None; instr = Goto label_false }
      ]
  
  | While_lang.Ast.Not c ->
      (* Swap target labels *)
      translate_condition c label_false label_true
  
  | While_lang.Ast.And (c1, c2) ->
      (* Short-circuit: if c1 false, skip c2 *)
      let label_c2 = fresh_label "and_" in
      (translate_condition c1 label_c2 label_false) @  (* Check c1 *)
      [{ label = Some label_c2; instr = Skip }] @
      (translate_condition c2 label_true label_false)  (* Check c2 *)
  
  | While_lang.Ast.Or (c1, c2) ->
      (* Short-circuit: if c1 true, skip c2 *)
      let label_c2 = fresh_label "or_" in
      (translate_condition c1 label_true label_c2) @  (* Check c1 *)
      [{ label = Some label_c2; instr = Skip }] @
      (translate_condition c2 label_true label_false)  (* Check c2 *)
```

**Example:**

```ocaml
(* Source WHILE *)
WHILE x0 < 5 AND x1 != 0 DO
  x0 := x0 + 1
END

(* Translated GOTO *)
while_start_0: SKIP
    IF x0 < 5 THEN GOTO and_1
    GOTO while_end_2
and_1: SKIP
    IF x1 != 0 THEN GOTO while_body_3
    GOTO while_end_2
while_body_3: SKIP
    x0 := (x0 + 1)
    GOTO while_start_0
while_end_2: SKIP
    HALT
```

**Why this works:**
- Structured control (WHILE) → unstructured control (GOTO)
- Condition evaluation → label jumps
- Loop repetition → explicit GOTO to start
- Short-circuit evaluation preserved

---

### 3. GOTO → WHILE (`src/translators/goto_to_while.ml`)

**Theorem:** GOTO can be simulated in WHILE (equivalence)

**Translation strategy:** **Program Counter Simulation**

```ocaml
(* GOTO program *)
L1: instruction_1
L2: instruction_2
...
Ln: instruction_n

(* Translates to WHILE *)
pc := 0;
WHILE pc != -1 DO
  IF pc = 0 THEN ...execute instruction_0...; pc := next
  ELSE IF pc = 1 THEN ...execute instruction_1...; pc := next
  ...
  ELSE IF pc = n THEN ...execute instruction_n...; pc := next
END
```

**Implementation:**

```ocaml
let translate_instruction 
    (instr : Goto.Ast.instruction) 
    (pc_var : string)
    (next_pc : int)
    (labels : (string, int) Hashtbl.t) 
    : While_lang.Ast.program =
  
  match instr with
  | Goto.Ast.Skip ->
      Assign (pc_var, Const next_pc)
  
  | Goto.Ast.Assign (x, e) ->
      Seq (
        Assign (x, translate_expr e),
        Assign (pc_var, Const next_pc)
      )
  
  | Goto.Ast.Goto label ->
      let target_pc = Hashtbl.find labels label in
      Assign (pc_var, Const target_pc)
  
  | Goto.Ast.IfGoto (e1, op, e2, label) ->
      (* Simulate IF-THEN using WHILE *)
      let target_pc = Hashtbl.find labels label in
      let tmp = fresh_var "cond_" in
      
      Seq (
        Assign (tmp, Const 0),
        Seq (
          (* If condition true, set pc to target *)
          While (
            Compare (e1', op', e2'),
            Seq (
              Assign (pc_var, Const target_pc),
              Seq (
                Assign (tmp, Const 1),
                Assign (tmp, Const 0)  (* Break out *)
              )
            )
          ),
          (* If condition false, set pc to next *)
          While (
            Compare (Var tmp, Eq, Const 0),
            Seq (
              Assign (pc_var, Const next_pc),
              Assign (tmp, Const 1)
            )
          )
        )
      )
  
  | Goto.Ast.Halt ->
      Assign (pc_var, Const (-1))  (* -1 signals termination *)
```

**Dispatch loop:**

```ocaml
(* Build dispatch for each instruction *)
let rec build_chain idx instrs =
  match instrs with
  | [] -> Skip
  | li :: rest ->
      let next_pc = idx + 1 in
      let tmp = fresh_var "dispatch_" in
      
      Seq (
        Assign (tmp, Const 0),
        Seq (
          (* If pc = idx, execute this instruction *)
          While (
            Compare (Var pc_var, Eq, Const idx),
            Seq (
              build_dispatch idx li pc_var next_pc labels,
              Assign (tmp, Const 1)  (* Mark as executed *)
            )
          ),
          build_chain next_pc rest  (* Check next instruction *)
        )
      )
```

**Complete translation:**

```ocaml
let translate_program (prog : Goto.Ast.program) : While_lang.Ast.program =
  let labels = build_label_map prog in
  let pc_var = fresh_var "pc_" in
  
  let init_pc = Assign (pc_var, Const 0) in
  let dispatch = build_chain 0 prog in
  
  (* Main loop *)
  Seq (
    init_pc,
    While (
      Compare (Var pc_var, Neq, Const (-1)),
      dispatch
    )
  )
```

**Why this works:**
- Each GOTO instruction mapped to PC value
- WHILE loop dispatches to correct instruction
- Label jumps become PC assignments
- HALT sets PC to -1 (exit condition)

**Example:**

```ocaml
(* GOTO program *)
    x0 := 0;         (* PC = 0 *)
LOOP: IF x1 = 0 THEN GOTO END;  (* PC = 1 *)
    x0 := x0 + 1;    (* PC = 2 *)
    GOTO LOOP;       (* PC = 3 *)
END: HALT            (* PC = 4 *)

(* Translated WHILE *)
pc_0 := 0;
WHILE pc_0 != -1 DO
  dispatch_1 := 0;
  WHILE pc_0 = 0 DO
    x0 := 0;
    pc_0 := 1;
    dispatch_1 := 1
  END;
  
  dispatch_2 := 0;
  WHILE pc_0 = 1 DO
    cond_3 := 0;
    WHILE x1 = 0 DO
      pc_0 := 4;
      cond_3 := 1;
      cond_3 := 0
    END;
    WHILE cond_3 = 0 DO
      pc_0 := 2;
      cond_3 := 1
    END;
    dispatch_2 := 1
  END;
  
  (* ... PC = 2, 3, 4 ... *)
END
```

---

## Theoretical Foundations

### Computability Hierarchy

```
┌─────────────────────────────────────────┐
│         Turing-Complete                 │
│    (Halting Problem Undecidable)        │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │       WHILE ≡ GOTO                │  │
│  │  (μ-recursive functions)          │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │         LOOP                │  │  │
│  │  │  (Primitive recursive)      │  │  │
│  │  │  (Always terminates)        │  │  │
│  │  └─────────────────────────────┘  │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### Key Theorems

**Theorem 1:** LOOP ⊂ WHILE
- **Proof:** LOOP → WHILE translation exists ✓
- **Converse false:** Ackermann function (WHILE) not in LOOP

**Theorem 2:** WHILE ≡ GOTO
- **Proof:** 
  - WHILE → GOTO translation exists ✓
  - GOTO → WHILE translation exists ✓
  - Both preserve semantics ✓

**Theorem 3:** LOOP ⊊ WHILE (strict subset)
- **Proof:** 
  - LOOP → WHILE exists (Theorem 1) ✓
  - Ackermann not primitive recursive
  - Therefore LOOP ≠ WHILE ✓

---

## Performance Analysis

### Time Complexity

**Interpreters:**
- LOOP: O(program_size × total_iterations)
- WHILE: O(program_size × total_iterations) [may not terminate]
- GOTO: O(program_size × steps)

**Translators:**
- LOOP → WHILE: O(program_size)
- WHILE → GOTO: O(program_size × condition_complexity)
- GOTO → WHILE: O(program_size²) [generates dispatch]

### Space Complexity

**Interpreters:**
- State: O(number_of_variables)
- Call stack: O(nesting_depth)

**Translators:**
- O(program_size) for output

### Optimization Opportunities

1. **Constant folding:**
   ```ocaml
   Add(Const 2, Const 3) → Const 5
   ```

2. **Dead code elimination:**
   ```ocaml
   IF false THEN ... END → eliminated
   ```

3. **Tail-call optimization:**
   ```ocaml
   (* Already done by OCaml compiler! *)
   let rec loop n f x =
     if n <= 0 then x
     else loop (n - 1) f (f x)  (* Tail call *)
   ```

---

## Extension Points

### Adding New Features

#### 1. Arrays

**AST extension:**
```ocaml
type expr =
  | ...
  | ArrayAccess of string * expr  (* a[i] *)

type program =
  | ...
  | ArrayAssign of string * expr * expr  (* a[i] := e *)
```

**State extension:**
```ocaml
type value =
  | Int of int
  | Array of int array

type t = value VarMap.t
```

#### 2. Subroutines

**AST extension:**
```ocaml
type program =
  | ...
  | Call of string * expr list       (* CALL f(e1, e2, ...) *)
  | Return of expr                   (* RETURN e *)

type procedure = {
  name: string;
  params: string list;
  body: program;
}

type program_with_procs = {
  procedures: procedure list;
  main: program;
}
```

#### 3. I/O Operations

**AST extension:**
```ocaml
type program =
  | ...
  | Read of string      (* READ xi *)
  | Write of expr       (* WRITE e *)
```

**Interpreter extension:**
```ocaml
let exec_io (p : program) (state : State.t) (input : int list ref) : State.t =
  match p with
  | Read x ->
      (match !input with
       | v :: rest -> input := rest; State.set state x v
       | [] -> failwith "No input available")
  | Write e ->
      Printf.printf "%d\n" (eval_expr e state);
      state
```

---

## Conclusion

This implementation demonstrates:

1. ✅ **Theoretical correctness** - Implements FSK semantics precisely
2. ✅ **Type safety** - OCaml's type system prevents many bugs
3. ✅ **Functional purity** - Immutable state, no side effects
4. ✅ **Modularity** - Clean separation of concerns
5. ✅ **Extensibility** - Easy to add new features
6. ✅ **Testability** - Comprehensive test coverage

The code serves as both a practical tool and a formal specification of the three computability models from the FSK lecture.

---

*For usage instructions, see USER_GUIDE.md*
*For architectural overview, see ARCHITECTURE.md*

