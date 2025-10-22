%{
open Ast
%}

%token <int> NUMBER
%token <string> IDENT
%token ASSIGN COLON SEMICOLON
%token PLUS MINUS TIMES
%token LPAREN RPAREN
%token EQ NEQ LT GT LEQ GEQ
%token IF THEN GOTO HALT SKIP
%token EOF

%left PLUS MINUS
%left TIMES

%start <Ast.program> program

%%

program:
  | instrs = separated_list(SEMICOLON, labeled_instr) EOF { instrs }
  ;

labeled_instr:
  | label = IDENT COLON instr = instruction
      { { label = Some label; instr } }
  | instr = instruction
      { { label = None; instr } }
  ;

instruction:
  | SKIP { Skip }
  | x = IDENT ASSIGN e = expr { Assign (x, e) }
  | GOTO label = IDENT { Goto label }
  | IF e1 = expr op = comp_op e2 = expr THEN GOTO label = IDENT
      { IfGoto (e1, op, e2, label) }
  | HALT { Halt }
  ;

comp_op:
  | EQ { Eq }
  | NEQ { Neq }
  | LT { Lt }
  | GT { Gt }
  | LEQ { Leq }
  | GEQ { Geq }
  ;

expr:
  | n = NUMBER { Const n }
  | x = IDENT { Var x }
  | e1 = expr PLUS e2 = expr { Add (e1, e2) }
  | e1 = expr MINUS e2 = expr { Sub (e1, e2) }
  | e1 = expr TIMES e2 = expr { Mul (e1, e2) }
  | LPAREN e = expr RPAREN { e }
  ;

