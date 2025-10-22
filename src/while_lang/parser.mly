%{
open Ast
%}

%token <int> NUMBER
%token <string> IDENT
%token ASSIGN SEMICOLON
%token PLUS MINUS TIMES
%token LPAREN RPAREN
%token EQ NEQ LT GT LEQ GEQ
%token WHILE DO END SKIP
%token AND OR NOT
%token EOF

%left OR
%left AND
%nonassoc NOT
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
  | WHILE c = condition DO p = stmt END { While (c, p) }
  | LPAREN p = stmt RPAREN { p }
  ;

condition:
  | e1 = expr EQ e2 = expr { Compare (e1, Eq, e2) }
  | e1 = expr NEQ e2 = expr { Compare (e1, Neq, e2) }
  | e1 = expr LT e2 = expr { Compare (e1, Lt, e2) }
  | e1 = expr GT e2 = expr { Compare (e1, Gt, e2) }
  | e1 = expr LEQ e2 = expr { Compare (e1, Leq, e2) }
  | e1 = expr GEQ e2 = expr { Compare (e1, Geq, e2) }
  | c1 = condition AND c2 = condition { And (c1, c2) }
  | c1 = condition OR c2 = condition { Or (c1, c2) }
  | NOT c = condition { Not c }
  | LPAREN c = condition RPAREN { c }
  ;

expr:
  | n = NUMBER { Const n }
  | x = IDENT { Var x }
  | e1 = expr PLUS e2 = expr { Add (e1, e2) }
  | e1 = expr MINUS e2 = expr { Sub (e1, e2) }
  | e1 = expr TIMES e2 = expr { Mul (e1, e2) }
  | LPAREN e = expr RPAREN { e }
  ;

