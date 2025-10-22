(** Abstract Syntax Tree for GOTO language
    Based on FSK script §10.3 *)

(** Comparison operators *)
type comp_op =
  | Eq   (* = *)
  | Neq  (* != *)
  | Lt   (* < *)
  | Gt   (* > *)
  | Leq  (* <= *)
  | Geq  (* >= *)

(** Arithmetic expressions *)
type expr =
  | Const of int
  | Var of string
  | Add of expr * expr
  | Sub of expr * expr
  | Mul of expr * expr

(** GOTO instructions *)
type instruction =
  | Skip                                  (* No-op *)
  | Assign of string * expr               (* xi := e *)
  | Goto of string                        (* GOTO L *)
  | IfGoto of expr * comp_op * expr * string  (* IF e1 op e2 THEN GOTO L *)
  | Halt                                  (* HALT *)

(** Labeled instruction *)
type labeled_instr = {
  label: string option;   (* Optional label *)
  instr: instruction;     (* The instruction *)
}

(** GOTO program is a sequence of labeled instructions *)
type program = labeled_instr list

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

let string_of_instruction = function
  | Skip -> "SKIP"
  | Assign (x, e) -> Printf.sprintf "%s := %s" x (string_of_expr e)
  | Goto l -> Printf.sprintf "GOTO %s" l
  | IfGoto (e1, op, e2, l) ->
      Printf.sprintf "IF %s %s %s THEN GOTO %s"
        (string_of_expr e1)
        (string_of_comp_op op)
        (string_of_expr e2)
        l
  | Halt -> "HALT"

let string_of_labeled_instr li =
  let label_str = match li.label with
    | Some l -> l ^ ": "
    | None -> "    "
  in
  label_str ^ string_of_instruction li.instr

let string_of_program (prog : program) : string =
  String.concat "\n" (List.map string_of_labeled_instr prog)

