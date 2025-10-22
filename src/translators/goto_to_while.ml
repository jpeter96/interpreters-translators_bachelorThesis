(** Translate GOTO programs to WHILE programs
    
    This demonstrates the equivalence between GOTO and WHILE (FSK §10.4).
    
    The translation simulates a program counter using a variable (pc).
    Each labeled instruction is assigned a unique number, and we use
    a large IF-THEN-ELSE chain inside a WHILE loop to dispatch to the
    appropriate instruction.
    
    WHILE pc != -1 DO
      IF pc = 0 THEN ...execute instruction 0...; pc := next
      ELSE IF pc = 1 THEN ...execute instruction 1...; pc := next
      ...
      END
    END
*)

(** Convert GOTO expression to WHILE expression *)
let rec translate_expr (e : Goto.Ast.expr) : While_lang.Ast.expr =
  match e with
  | Goto.Ast.Const n -> While_lang.Ast.Const n
  | Goto.Ast.Var x -> While_lang.Ast.Var x
  | Goto.Ast.Add (e1, e2) -> While_lang.Ast.Add (translate_expr e1, translate_expr e2)
  | Goto.Ast.Sub (e1, e2) -> While_lang.Ast.Sub (translate_expr e1, translate_expr e2)
  | Goto.Ast.Mul (e1, e2) -> While_lang.Ast.Mul (translate_expr e1, translate_expr e2)

(** Convert comparison operator *)
let translate_comp_op (op : Goto.Ast.comp_op) : While_lang.Ast.comp_op =
  match op with
  | Goto.Ast.Eq -> While_lang.Ast.Eq
  | Goto.Ast.Neq -> While_lang.Ast.Neq
  | Goto.Ast.Lt -> While_lang.Ast.Lt
  | Goto.Ast.Gt -> While_lang.Ast.Gt
  | Goto.Ast.Leq -> While_lang.Ast.Leq
  | Goto.Ast.Geq -> While_lang.Ast.Geq

(** Build label-to-index mapping *)
let build_label_map (prog : Goto.Ast.program) : (string, int) Hashtbl.t =
  let tbl = Hashtbl.create 16 in
  List.iteri (fun idx (li : Goto.Ast.labeled_instr) ->
    match li.Goto.Ast.label with
    | Some label -> Hashtbl.add tbl label idx
    | None -> ()
  ) prog;
  tbl

(** Translate a single GOTO instruction to WHILE code *)
let translate_instruction 
    (instr : Goto.Ast.instruction) 
    (pc_var : string)
    (next_pc : int)
    (labels : (string, int) Hashtbl.t) : While_lang.Ast.program =
  match instr with
  | Goto.Ast.Skip ->
      (* Just move to next instruction *)
      While_lang.Ast.Assign (pc_var, While_lang.Ast.Const next_pc)
  
  | Goto.Ast.Assign (x, e) ->
      (* Execute assignment, then move to next instruction *)
      While_lang.Ast.Seq (
        While_lang.Ast.Assign (x, translate_expr e),
        While_lang.Ast.Assign (pc_var, While_lang.Ast.Const next_pc)
      )
  
  | Goto.Ast.Goto label ->
      (* Jump to label *)
      let target_pc = Hashtbl.find labels label in
      While_lang.Ast.Assign (pc_var, While_lang.Ast.Const target_pc)
  
  | Goto.Ast.IfGoto (e1, op, e2, label) ->
      (* Conditional jump *)
      let target_pc = Hashtbl.find labels label in
      let cond = While_lang.Ast.Compare (
        translate_expr e1,
        translate_comp_op op,
        translate_expr e2
      ) in
      (* Simulate IF-THEN-ELSE using WHILE with single iteration *)
      let tmp = Common.Utils.fresh_var "cond_" in
      While_lang.Ast.Seq (
        While_lang.Ast.Assign (tmp, While_lang.Ast.Const 0),
        While_lang.Ast.Seq (
          While_lang.Ast.While (
            cond,
            While_lang.Ast.Seq (
              While_lang.Ast.Assign (pc_var, While_lang.Ast.Const target_pc),
              While_lang.Ast.Seq (
                While_lang.Ast.Assign (tmp, While_lang.Ast.Const 1),
                While_lang.Ast.Assign (tmp, While_lang.Ast.Const 0)  (* Break *)
              )
            )
          ),
          While_lang.Ast.While (
            While_lang.Ast.Compare (While_lang.Ast.Var tmp, While_lang.Ast.Eq, While_lang.Ast.Const 0),
            While_lang.Ast.Seq (
              While_lang.Ast.Assign (pc_var, While_lang.Ast.Const next_pc),
              While_lang.Ast.Assign (tmp, While_lang.Ast.Const 1)
            )
          )
        )
      )
  
  | Goto.Ast.Halt ->
      (* Set pc to -1 to exit *)
      While_lang.Ast.Assign (pc_var, While_lang.Ast.Const (-1))

(** Build the dispatch for a single instruction *)
let build_dispatch
    (_idx : int)
    (li : Goto.Ast.labeled_instr)
    (pc_var : string)
    (next_pc : int)
    (labels : (string, int) Hashtbl.t) : While_lang.Ast.program =
  let instruction_code = translate_instruction li.Goto.Ast.instr pc_var next_pc labels in
  instruction_code

(** Translate GOTO program to WHILE program *)
let translate_program (prog : Goto.Ast.program) : While_lang.Ast.program =
  Common.Utils.reset_fresh_vars ();
  
  if List.length prog = 0 then
    While_lang.Ast.Skip
  else
    let labels = build_label_map prog in
    let pc_var = Common.Utils.fresh_var "pc_" in
    
    (* Initialize pc to 0 *)
    let init_pc = While_lang.Ast.Assign (pc_var, While_lang.Ast.Const 0) in
    
    (* Build the dispatch chain *)
    let rec build_chain idx instrs =
      match instrs with
      | [] -> While_lang.Ast.Skip
      | [li] ->
          let next_pc = idx + 1 in
          (* IF pc = idx THEN ... *)
          let tmp = Common.Utils.fresh_var "dispatch_" in
          While_lang.Ast.Seq (
            While_lang.Ast.Assign (tmp, While_lang.Ast.Const 0),
            While_lang.Ast.While (
              While_lang.Ast.Compare (
                While_lang.Ast.Var pc_var,
                While_lang.Ast.Eq,
                While_lang.Ast.Const idx
              ),
              While_lang.Ast.Seq (
                build_dispatch idx li pc_var next_pc labels,
                While_lang.Ast.Assign (tmp, While_lang.Ast.Const 1)
              )
            )
          )
      | li :: rest ->
          let next_pc = idx + 1 in
          let tmp = Common.Utils.fresh_var "dispatch_" in
          While_lang.Ast.Seq (
            While_lang.Ast.Assign (tmp, While_lang.Ast.Const 0),
            While_lang.Ast.Seq (
              While_lang.Ast.While (
                While_lang.Ast.Compare (
                  While_lang.Ast.Var pc_var,
                  While_lang.Ast.Eq,
                  While_lang.Ast.Const idx
                ),
                While_lang.Ast.Seq (
                  build_dispatch idx li pc_var next_pc labels,
                  While_lang.Ast.Assign (tmp, While_lang.Ast.Const 1)
                )
              ),
              build_chain next_pc rest
            )
          )
    in
    
    let dispatch = build_chain 0 prog in
    
    (* Main loop: WHILE pc != -1 DO dispatch END *)
    While_lang.Ast.Seq (
      init_pc,
      While_lang.Ast.While (
        While_lang.Ast.Compare (
          While_lang.Ast.Var pc_var,
          While_lang.Ast.Neq,
          While_lang.Ast.Const (-1)
        ),
        dispatch
      )
    )

