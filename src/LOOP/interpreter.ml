(** LOOP language interpreter
    Based on FSK script §10.1 *)

open Ast

(** Evaluation mode *)
type mode = 
  | Normal         (* Normal execution *)
  | Trace          (* Step-by-step tracing *)

(** Evaluate an arithmetic expression *)
let rec eval_expr (e : expr) (state : Common.State.t) : int =
  match e with
  | Const n -> n
  | Var x -> Common.State.get state x
  | Add (e1, e2) -> eval_expr e1 state + eval_expr e2 state
  | Sub (e1, e2) -> Common.Utils.nat_sub (eval_expr e1 state) (eval_expr e2 state)
  | Mul (e1, e2) -> eval_expr e1 state * eval_expr e2 state

(** Execute a LOOP program *)
let rec exec (mode : mode) (p : program) (state : Common.State.t) : Common.State.t =
  match mode with
  | Trace ->
      Printf.printf "\nExecuting: %s\n" (string_of_program p);
      Printf.printf "State before: %s\n" (Common.State.to_string state);
      let result = exec_impl p state in
      Printf.printf "State after: %s\n" (Common.State.to_string result);
      result
  | Normal -> exec_impl p state

and exec_impl (p : program) (state : Common.State.t) : Common.State.t =
  match p with
  | Skip -> state
  
  | Assign (x, e) ->
      let value = eval_expr e state in
      Common.State.set state x value
  
  | Seq (p1, p2) ->
      let state' = exec_impl p1 state in
      exec_impl p2 state'
  
  | Loop (x, body) ->
      let n = Common.State.get state x in
      (* Execute body n times - this is the key property of LOOP:
         the number of iterations is fixed at the start *)
      let rec loop_n times s =
        if times <= 0 then s
        else loop_n (times - 1) (exec_impl body s)
      in
      loop_n n state

(** Run a LOOP program with initial state *)
let run ?(mode=Normal) (p : program) (initial : Common.State.t) : Common.State.t =
  exec mode p initial

(** Run a LOOP program with empty initial state *)
let run_empty ?(mode=Normal) (p : program) : Common.State.t =
  run ~mode p Common.State.empty

