(** Abstract Syntax Tree for LOOP language
    Based on FSK script §10.1 *)

(** Arithmetic expressions *)
type expr =
  | Const of int                    (* Constants: 0, 1, 2, ... *)
  | Var of string                   (* Variables: x0, x1, x2, ... *)
  | Add of expr * expr              (* Addition: e1 + e2 *)
  | Sub of expr * expr              (* Subtraction: e1 - e2 (natural number subtraction) *)
  | Mul of expr * expr              (* Multiplication: e1 * e2 *)

(** LOOP programs *)
type program =
  | Skip                            (* Empty statement *)
  | Assign of string * expr         (* Assignment: xi := e *)
  | Seq of program * program        (* Sequential composition: P1; P2 *)
  | Loop of string * program        (* Loop: LOOP xi DO P END *)

(** Pretty printing *)
let rec string_of_expr (e : expr) : string =
  match e with
  | Const n -> string_of_int n
  | Var x -> x
  | Add (e1, e2) -> Printf.sprintf "(%s + %s)" (string_of_expr e1) (string_of_expr e2)
  | Sub (e1, e2) -> Printf.sprintf "(%s - %s)" (string_of_expr e1) (string_of_expr e2)
  | Mul (e1, e2) -> Printf.sprintf "(%s * %s)" (string_of_expr e1) (string_of_expr e2)

let rec string_of_program ?(indent=0) (p : program) : string =
  let ind = String.make (indent * 2) ' ' in
  match p with
  | Skip -> ind ^ "SKIP"
  | Assign (x, e) -> Printf.sprintf "%s%s := %s" ind x (string_of_expr e)
  | Seq (p1, p2) ->
      Printf.sprintf "%s;\n%s" 
        (string_of_program ~indent p1) 
        (string_of_program ~indent p2)
  | Loop (x, body) ->
      Printf.sprintf "%sLOOP %s DO\n%s\n%sEND"
        ind x
        (string_of_program ~indent:(indent+1) body)
        ind

