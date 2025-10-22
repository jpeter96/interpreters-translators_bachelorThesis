(** Translate LOOP programs to WHILE programs
    
    This translation is always possible since LOOP is a subset of WHILE.
    The key translation is: LOOP x DO P END becomes:
    
    tmp := x;
    WHILE tmp != 0 DO
      P;
      tmp := tmp - 1
    END
*)

(** Convert LOOP expression to WHILE expression *)
let rec translate_expr (e : Loop.Ast.expr) : While_lang.Ast.expr =
  match e with
  | Loop.Ast.Const n -> While_lang.Ast.Const n
  | Loop.Ast.Var x -> While_lang.Ast.Var x
  | Loop.Ast.Add (e1, e2) -> While_lang.Ast.Add (translate_expr e1, translate_expr e2)
  | Loop.Ast.Sub (e1, e2) -> While_lang.Ast.Sub (translate_expr e1, translate_expr e2)
  | Loop.Ast.Mul (e1, e2) -> While_lang.Ast.Mul (translate_expr e1, translate_expr e2)

(** Translate LOOP program to WHILE program *)
let rec translate (p : Loop.Ast.program) : While_lang.Ast.program =
  match p with
  | Loop.Ast.Skip -> While_lang.Ast.Skip
  
  | Loop.Ast.Assign (x, e) ->
      While_lang.Ast.Assign (x, translate_expr e)
  
  | Loop.Ast.Seq (p1, p2) ->
      While_lang.Ast.Seq (translate p1, translate p2)
  
  | Loop.Ast.Loop (x, body) ->
      (* Generate a fresh temporary variable to count down *)
      let tmp = Common.Utils.fresh_var "loop_" in
      let body_while = translate body in
      (* tmp := x; WHILE tmp != 0 DO body; tmp := tmp - 1 END *)
      While_lang.Ast.Seq (
        While_lang.Ast.Assign (tmp, While_lang.Ast.Var x),
        While_lang.Ast.While (
          While_lang.Ast.Compare (While_lang.Ast.Var tmp, While_lang.Ast.Neq, While_lang.Ast.Const 0),
          While_lang.Ast.Seq (
            body_while,
            While_lang.Ast.Assign (tmp, While_lang.Ast.Sub (While_lang.Ast.Var tmp, While_lang.Ast.Const 1))
          )
        )
      )

(** Translate and reset fresh variable counter *)
let translate_fresh (p : Loop.Ast.program) : While_lang.Ast.program =
  Common.Utils.reset_fresh_vars ();
  translate p

