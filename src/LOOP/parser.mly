%{
open Ast
%}

%token <int> NUMBER
%token <string> IDENT
%token ASSIGN SEMICOLON
%token PLUS MINUS TIMES
%token LPAREN RPAREN
%token LOOP DO END SKIP
%token EOF

%left PLUS MINUS
%left TIMES

%start <Ast.program> program

%%

program:
  | p = stmt EOF { p }
  ;

stmt:
  | SKIP { Skip }
  | IDENT ASSIGN e = expr { Assign ($1, e) }
  | p1 = stmt SEMICOLON p2 = stmt { Seq (p1, p2) }
  | LOOP x = IDENT DO p = stmt END { Loop (x, p) }
  | LPAREN p = stmt RPAREN { p }
  ;

expr:
  | n = NUMBER { Const n }
  | x = IDENT { Var x }
  | e1 = expr PLUS e2 = expr { Add (e1, e2) }
  | e1 = expr MINUS e2 = expr { Sub (e1, e2) }
  | e1 = expr TIMES e2 = expr { Mul (e1, e2) }
  | LPAREN e = expr RPAREN { e }
  ;

