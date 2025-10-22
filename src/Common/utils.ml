(** Common utility functions *)

(** Read entire file contents *)
let read_file (filename : string) : string =
  let ic = open_in filename in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

(** Write string to file *)
let write_file (filename : string) (content : string) : unit =
  let oc = open_out filename in
  output_string oc content;
  close_out oc

(** Safe subtraction for natural numbers (returns 0 if result would be negative) *)
let nat_sub (a : int) (b : int) : int =
  max 0 (a - b)

(** Repeat a function n times *)
let rec repeat (n : int) (f : 'a -> 'a) (x : 'a) : 'a =
  if n <= 0 then x
  else repeat (n - 1) f (f x)

(** Generate fresh variable name (for translations) *)
let fresh_var_counter = ref 0

let fresh_var (prefix : string) : string =
  let id = !fresh_var_counter in
  incr fresh_var_counter;
  Printf.sprintf "%s%d" prefix id

let reset_fresh_vars () : unit =
  fresh_var_counter := 0

(** Generate fresh label name (for GOTO translations) *)
let fresh_label_counter = ref 0

let fresh_label (prefix : string) : string =
  let id = !fresh_label_counter in
  incr fresh_label_counter;
  Printf.sprintf "%s%d" prefix id

let reset_fresh_labels () : unit =
  fresh_label_counter := 0

