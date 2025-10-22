(** WHILE language interpreter
    Based on FSK script §10.2 *)

open Ast

type mode = 
  | Normal
  | Trace

(** Maximum number of iterations to prevent infinite loops in trace mode *)
let max_iterations = 100000

exception InfiniteLoop of string

(** Evaluate an arithmetic expression *)
let rec eval_expr (e : expr) (state : Common.State.t) : int =
  match e with
  | Const n -> n
  | Var x -> Common.State.get state x
  | Add (e1, e2) -> eval_expr e1 state + eval_expr e2 state
  | Sub (e1, e2) -> Common.Utils.nat_sub (eval_expr e1 state) (eval_expr e2 state)
  | Mul (e1, e2) -> eval_expr e1 state * eval_expr e2 state

(** Evaluate a comparison *)
let eval_comp (e1 : expr) (op : comp_op) (e2 : expr) (state : Common.State.t) : bool =
  let v1 = eval_expr e1 state in
  let v2 = eval_expr e2 state in
  match op with
  | Eq -> v1 = v2
  | Neq -> v1 <> v2
  | Lt -> v1 < v2
  | Gt -> v1 > v2
  | Leq -> v1 <= v2
  | Geq -> v1 >= v2

(** Evaluate a boolean condition *)
let rec eval_condition (c : condition) (state : Common.State.t) : bool =
  match c with
  | Compare (e1, op, e2) -> eval_comp e1 op e2 state
  | And (c1, c2) -> eval_condition c1 state && eval_condition c2 state
  | Or (c1, c2) -> eval_condition c1 state || eval_condition c2 state
  | Not c -> not (eval_condition c state)

(** Execute a WHILE program *)
let rec exec (mode : mode) (p : program) (state : Common.State.t) : Common.State.t =
  match mode with
  | Trace ->
      Printf.printf "\nExecuting: %s\n" (string_of_program p);
      Printf.printf "State before: %s\n" (Common.State.to_string state);
      let result = exec_impl 0 p state in
      Printf.printf "State after: %s\n" (Common.State.to_string result);
      result
  | Normal -> exec_impl 0 p state

and exec_impl (iter_count : int) (p : program) (state : Common.State.t) : Common.State.t =
  if iter_count > max_iterations then
    raise (InfiniteLoop "Maximum iteration count exceeded")
  else
    match p with
    | Skip -> state
    
    | Assign (x, e) ->
        let value = eval_expr e state in
        Common.State.set state x value
    
    | Seq (p1, p2) ->
        let state' = exec_impl iter_count p1 state in
        exec_impl iter_count p2 state'
    
    | While (cond, body) ->
        (* Key difference from LOOP: condition checked at each iteration *)
        if eval_condition cond state then
          let state' = exec_impl (iter_count + 1) body state in
          exec_impl (iter_count + 1) (While (cond, body)) state'
        else
          state

(** Run a WHILE program with initial state *)
let run ?(mode=Normal) (p : program) (initial : Common.State.t) : Common.State.t =
  exec mode p initial

(** Run a WHILE program with empty initial state *)
let run_empty ?(mode=Normal) (p : program) : Common.State.t =
  run ~mode p Common.State.empty

