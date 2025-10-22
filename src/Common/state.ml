(** Variable state management for all three languages.
    Variables in LOOP/WHILE/GOTO are typically named x0, x1, x2, ...
    and can only hold non-negative integers (natural numbers). *)

module VarMap = Map.Make(String)

type t = int VarMap.t

(** Create an empty state *)
let empty : t = VarMap.empty

(** Get variable value, returns 0 if undefined (as per FSK semantics) *)
let get (state : t) (var : string) : int =
  match VarMap.find_opt var state with
  | Some v -> v
  | None -> 0

(** Set variable value *)
let set (state : t) (var : string) (value : int) : t =
  VarMap.add var value state

(** Create state from association list *)
let of_list (bindings : (string * int) list) : t =
  List.fold_left
    (fun acc (var, value) -> set acc var value)
    empty
    bindings

(** Convert state to association list (sorted by variable name) *)
let to_list (state : t) : (string * int) list =
  VarMap.bindings state

(** Pretty print state *)
let to_string (state : t) : string =
  let bindings = to_list state in
  if List.length bindings = 0 then
    "{ (empty state) }"
  else
    let entries = List.map (fun (var, value) -> 
      Printf.sprintf "%s = %d" var value
    ) bindings in
    "{ " ^ String.concat ", " entries ^ " }"

(** Print state to stdout *)
let print (state : t) : unit =
  print_endline (to_string state)

