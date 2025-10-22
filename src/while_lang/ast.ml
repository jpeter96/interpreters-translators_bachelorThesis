(** Abstract Syntax Tree for WHILE language
    Based on FSK script §10.2 *)

(** Comparison operators *)
type comp_op =
  | Eq   (* = *)
  | Neq  (* != *)
  | Lt   (* < *)
  | Gt   (* > *)
  | Leq  (* <= *)
  | Geq  (* >= *)

(** Arithmetic expressions (same as LOOP) *)
type expr =
  | Const of int
  | Var of string
  | Add of expr * expr
  | Sub of expr * expr
  | Mul of expr * expr

(** Boolean conditions *)
type condition =
  | Compare of expr * comp_op * expr
  | And of condition * condition
  | Or of condition * condition
  | Not of condition

(** WHILE programs *)
type program =
  | Skip
  | Assign of string * expr
  | Seq of program * program
  | While of condition * program    (* WHILE c DO P END *)

(** Pretty printing *)
let string_of_comp_op = function
  | Eq -> "="
  | Neq -> "!="
  | Lt -> "<"
  | Gt -> ">"
  | Leq -> "<="
  | Geq -> ">="

let rec string_of_expr = function
  | Const n -> string_of_int n
  | Var x -> x
  | Add (e1, e2) -> Printf.sprintf "(%s + %s)" (string_of_expr e1) (string_of_expr e2)
  | Sub (e1, e2) -> Printf.sprintf "(%s - %s)" (string_of_expr e1) (string_of_expr e2)
  | Mul (e1, e2) -> Printf.sprintf "(%s * %s)" (string_of_expr e1) (string_of_expr e2)

let rec string_of_condition = function
  | Compare (e1, op, e2) ->
      Printf.sprintf "%s %s %s" 
        (string_of_expr e1) 
        (string_of_comp_op op) 
        (string_of_expr e2)
  | And (c1, c2) ->
      Printf.sprintf "(%s AND %s)" (string_of_condition c1) (string_of_condition c2)
  | Or (c1, c2) ->
      Printf.sprintf "(%s OR %s)" (string_of_condition c1) (string_of_condition c2)
  | Not c ->
      Printf.sprintf "NOT %s" (string_of_condition c)

let rec string_of_program ?(indent=0) = function
  | Skip -> String.make (indent * 2) ' ' ^ "SKIP"
  | Assign (x, e) ->
      Printf.sprintf "%s%s := %s" 
        (String.make (indent * 2) ' ') x (string_of_expr e)
  | Seq (p1, p2) ->
      Printf.sprintf "%s;\n%s"
        (string_of_program ~indent p1)
        (string_of_program ~indent p2)
  | While (c, body) ->
      let ind = String.make (indent * 2) ' ' in
      Printf.sprintf "%sWHILE %s DO\n%s\n%sEND"
        ind
        (string_of_condition c)
        (string_of_program ~indent:(indent+1) body)
        ind

