{
open Parser

exception Lexical_error of string
}

let whitespace = [' ' '\t' '\r' '\n']+
let digit = ['0'-'9']
let number = digit+
let letter = ['a'-'z' 'A'-'Z']
let identifier = letter (letter | digit | '_')*

rule token = parse
  | whitespace      { token lexbuf }
  | "(*"            { comment lexbuf }
  | ":="            { ASSIGN }
  | ";"             { SEMICOLON }
  | "+"             { PLUS }
  | "-"             { MINUS }
  | "*"             { TIMES }
  | "("             { LPAREN }
  | ")"             { RPAREN }
  | "="             { EQ }
  | "!="            { NEQ }
  | "<="            { LEQ }
  | ">="            { GEQ }
  | "<"             { LT }
  | ">"             { GT }
  | "WHILE"         { WHILE }
  | "DO"            { DO }
  | "END"           { END }
  | "SKIP"          { SKIP }
  | "AND"           { AND }
  | "OR"            { OR }
  | "NOT"           { NOT }
  | number as n     { NUMBER (int_of_string n) }
  | identifier as s { IDENT s }
  | eof             { EOF }
  | _ as c          { raise (Lexical_error (Printf.sprintf "Unexpected character: %c" c)) }

and comment = parse
  | "*)"            { token lexbuf }
  | eof             { raise (Lexical_error "Unterminated comment") }
  | _               { comment lexbuf }

