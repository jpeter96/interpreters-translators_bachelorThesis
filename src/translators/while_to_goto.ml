(** Translate WHILE programs to GOTO programs
    
    This demonstrates the equivalence between WHILE and GOTO (FSK §10.4).
    
    Key translations:
    1. Sequential composition is already compatible
    2. WHILE c DO P END becomes:
       L_start: IF NOT c THEN GOTO L_end
       P (translated)
       GOTO L_start
       L_end: SKIP
*)

(** Convert WHILE expression to GOTO expression *)
let rec translate_expr (e : While_lang.Ast.expr) : Goto.Ast.expr =
  match e with
  | While_lang.Ast.Const n -> Goto.Ast.Const n
  | While_lang.Ast.Var x -> Goto.Ast.Var x
  | While_lang.Ast.Add (e1, e2) -> Goto.Ast.Add (translate_expr e1, translate_expr e2)
  | While_lang.Ast.Sub (e1, e2) -> Goto.Ast.Sub (translate_expr e1, translate_expr e2)
  | While_lang.Ast.Mul (e1, e2) -> Goto.Ast.Mul (translate_expr e1, translate_expr e2)

(** Convert comparison operator *)
let translate_comp_op (op : While_lang.Ast.comp_op) : Goto.Ast.comp_op =
  match op with
  | While_lang.Ast.Eq -> Goto.Ast.Eq
  | While_lang.Ast.Neq -> Goto.Ast.Neq
  | While_lang.Ast.Lt -> Goto.Ast.Lt
  | While_lang.Ast.Gt -> Goto.Ast.Gt
  | While_lang.Ast.Leq -> Goto.Ast.Leq
  | While_lang.Ast.Geq -> Goto.Ast.Geq

(** Negate a comparison operator *)
let negate_comp_op (op : Goto.Ast.comp_op) : Goto.Ast.comp_op =
  match op with
  | Goto.Ast.Eq -> Goto.Ast.Neq
  | Goto.Ast.Neq -> Goto.Ast.Eq
  | Goto.Ast.Lt -> Goto.Ast.Geq
  | Goto.Ast.Gt -> Goto.Ast.Leq
  | Goto.Ast.Leq -> Goto.Ast.Gt
  | Goto.Ast.Geq -> Goto.Ast.Lt

(** Translate a condition into a series of GOTO instructions
    that jump to label_true if condition is true, label_false otherwise *)
let rec translate_condition 
    (c : While_lang.Ast.condition) 
    (label_true : string) 
    (label_false : string) : Goto.Ast.labeled_instr list =
  match c with
  | While_lang.Ast.Compare (e1, op, e2) ->
      let e1' = translate_expr e1 in
      let e2' = translate_expr e2 in
      let op' = translate_comp_op op in
      [
        { Goto.Ast.label = None; instr = Goto.Ast.IfGoto (e1', op', e2', label_true) };
        { Goto.Ast.label = None; instr = Goto.Ast.Goto label_false }
      ]
  
  | While_lang.Ast.Not c ->
      (* Swap true and false labels *)
      translate_condition c label_false label_true
  
  | While_lang.Ast.And (c1, c2) ->
      let label_c2 = Common.Utils.fresh_label "and_" in
      (* If c1 is false, jump to label_false; if true, check c2 *)
      (translate_condition c1 label_c2 label_false) @
      [{ Goto.Ast.label = Some label_c2; instr = Goto.Ast.Skip }] @
      (translate_condition c2 label_true label_false)
  
  | While_lang.Ast.Or (c1, c2) ->
      let label_c2 = Common.Utils.fresh_label "or_" in
      (* If c1 is true, jump to label_true; if false, check c2 *)
      (translate_condition c1 label_true label_c2) @
      [{ Goto.Ast.label = Some label_c2; instr = Goto.Ast.Skip }] @
      (translate_condition c2 label_true label_false)

(** Translate WHILE program to GOTO instructions *)
let rec translate (p : While_lang.Ast.program) : Goto.Ast.labeled_instr list =
  match p with
  | While_lang.Ast.Skip ->
      [{ Goto.Ast.label = None; instr = Goto.Ast.Skip }]
  
  | While_lang.Ast.Assign (x, e) ->
      [{ Goto.Ast.label = None; instr = Goto.Ast.Assign (x, translate_expr e) }]
  
  | While_lang.Ast.Seq (p1, p2) ->
      (translate p1) @ (translate p2)
  
  | While_lang.Ast.While (cond, body) ->
      let label_start = Common.Utils.fresh_label "while_start_" in
      let label_body = Common.Utils.fresh_label "while_body_" in
      let label_end = Common.Utils.fresh_label "while_end_" in
      
      (* L_start: check condition *)
      [{ Goto.Ast.label = Some label_start; instr = Goto.Ast.Skip }] @
      (translate_condition cond label_body label_end) @
      (* L_body: execute body *)
      [{ Goto.Ast.label = Some label_body; instr = Goto.Ast.Skip }] @
      (translate body) @
      (* Jump back to start *)
      [{ Goto.Ast.label = None; instr = Goto.Ast.Goto label_start }] @
      (* L_end: exit *)
      [{ Goto.Ast.label = Some label_end; instr = Goto.Ast.Skip }]

(** Translate and add HALT at the end *)
let translate_program (p : While_lang.Ast.program) : Goto.Ast.program =
  Common.Utils.reset_fresh_labels ();
  let instrs = translate p in
  instrs @ [{ Goto.Ast.label = None; instr = Goto.Ast.Halt }]

