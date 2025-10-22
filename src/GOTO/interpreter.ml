(** GOTO language interpreter
    Based on FSK script §10.3 *)

open Ast

type mode = 
  | Normal
  | Trace

let max_steps = 100000

exception UndefinedLabel of string
exception InfiniteLoop of string

(** Build label-to-index map for efficient lookup *)
let build_label_map (prog : program) : (string, int) Hashtbl.t =
  let tbl = Hashtbl.create 16 in
  List.iteri (fun idx li ->
    match li.label with
    | Some label -> Hashtbl.add tbl label idx
    | None -> ()
  ) prog;
  tbl

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

(** Execute a GOTO program *)
let exec (mode : mode) (prog : program) (initial_state : Common.State.t) : Common.State.t =
  let labels = build_label_map prog in
  let prog_array = Array.of_list prog in
  let prog_len = Array.length prog_array in
  
  let rec step (pc : int) (state : Common.State.t) (step_count : int) : Common.State.t =
    if step_count > max_steps then
      raise (InfiniteLoop "Maximum step count exceeded")
    else if pc >= prog_len then
      state  (* Program ends when PC goes beyond last instruction *)
    else
      let li = prog_array.(pc) in
      
      if mode = Trace then (
        Printf.printf "\n[PC=%d] %s\n" pc (string_of_labeled_instr li);
        Printf.printf "State: %s\n" (Common.State.to_string state)
      );
      
      match li.instr with
      | Skip ->
          step (pc + 1) state (step_count + 1)
      
      | Assign (x, e) ->
          let value = eval_expr e state in
          let state' = Common.State.set state x value in
          step (pc + 1) state' (step_count + 1)
      
      | Goto label ->
          (match Hashtbl.find_opt labels label with
           | Some target_pc -> step target_pc state (step_count + 1)
           | None -> raise (UndefinedLabel label))
      
      | IfGoto (e1, op, e2, label) ->
          if eval_comp e1 op e2 state then
            (match Hashtbl.find_opt labels label with
             | Some target_pc -> step target_pc state (step_count + 1)
             | None -> raise (UndefinedLabel label))
          else
            step (pc + 1) state (step_count + 1)
      
      | Halt ->
          state
  in
  
  step 0 initial_state 0

(** Run a GOTO program with initial state *)
let run ?(mode=Normal) (prog : program) (initial : Common.State.t) : Common.State.t =
  exec mode prog initial

(** Run a GOTO program with empty initial state *)
let run_empty ?(mode=Normal) (prog : program) : Common.State.t =
  run ~mode prog Common.State.empty

