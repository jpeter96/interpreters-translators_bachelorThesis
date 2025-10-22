(** Main CLI entry point for LOOP/WHILE/GOTO interpreters and translators *)

open Printf

(** Command-line arguments *)
type command =
  | Interpret of { language: string; file: string; trace: bool }
  | Translate of { source: string; target: string; file: string; output: string option; verify: bool }
  | Help

(** Parse language from file extension *)
let language_from_extension filename =
  if Filename.check_suffix filename ".loop" then "loop"
  else if Filename.check_suffix filename ".while" then "while"
  else if Filename.check_suffix filename ".goto" then "goto"
  else failwith "Unknown file extension (expected .loop, .while, or .goto)"

(** Parse command-line arguments *)
let parse_args () =
  let args = Array.to_list Sys.argv in
  match args with
  | _ :: "help" :: _ | _ :: "--help" :: _ | _ :: "-h" :: _ -> Help
  | [_] -> Help  (* No arguments *)
  
  (* Translate mode *)
  | _ :: "translate" :: translation :: file :: rest ->
      let verify = List.mem "--verify" rest || List.mem "-v" rest in
      let output = 
        try Some (List.nth rest (List.find_index ((=) "--output") rest |> Option.get |> (+) 1))
        with _ ->
          try Some (List.nth rest (List.find_index ((=) "-o") rest |> Option.get |> (+) 1))
          with _ -> None
      in
      let (source, target) = match String.split_on_char '-' translation with
        | [s; "to"; t] -> (s, t)
        | _ -> failwith "Invalid translation format (expected: source-to-target)"
      in
      Translate { source; target; file; output; verify }
  
  (* Interpret mode *)
  | _ :: lang :: file :: rest when List.mem lang ["loop"; "while"; "goto"] ->
      let trace = List.mem "--trace" rest || List.mem "-t" rest in
      Interpret { language = lang; file; trace }
  
  | _ :: file :: rest ->
      let lang = language_from_extension file in
      let trace = List.mem "--trace" rest || List.mem "-t" rest in
      Interpret { language = lang; file; trace }
  
  | _ -> Help

(** Print help message *)
let print_help () =
  print_endline "LOOP/WHILE/GOTO Interpreters and Translators";
  print_endline "Bachelor Thesis Project - LMU Munich";
  print_endline "";
  print_endline "USAGE:";
  print_endline "  Interpret a program:";
  print_endline "    interpreters_translators <language> <file> [--trace|-t]";
  print_endline "    interpreters_translators <file> [--trace|-t]  (language inferred from extension)";
  print_endline "";
  print_endline "  Translate a program:";
  print_endline "    interpreters_translators translate <source-to-target> <file> [options]";
  print_endline "";
  print_endline "LANGUAGES:";
  print_endline "  loop   - LOOP language (primitive recursive)";
  print_endline "  while  - WHILE language (Turing-complete)";
  print_endline "  goto   - GOTO language (equivalent to WHILE)";
  print_endline "";
  print_endline "TRANSLATIONS:";
  print_endline "  loop-to-while   - Translate LOOP to WHILE";
  print_endline "  while-to-goto   - Translate WHILE to GOTO";
  print_endline "  goto-to-while   - Translate GOTO to WHILE";
  print_endline "";
  print_endline "OPTIONS:";
  print_endline "  -t, --trace            Enable step-by-step execution tracing";
  print_endline "  -v, --verify           Verify translation correctness";
  print_endline "  -o, --output <file>    Write translation output to file";
  print_endline "";
  print_endline "EXAMPLES:";
  print_endline "  interpreters_translators loop examples/loop/factorial.loop";
  print_endline "  interpreters_translators examples/while/fibonacci.while --trace";
  print_endline "  interpreters_translators translate loop-to-while examples/loop/factorial.loop";
  print_endline "  interpreters_translators translate while-to-goto examples/while/fib.while -o output.goto";
  ()

(** Parse a LOOP program from file *)
let parse_loop_file filename =
  let content = Common.Utils.read_file filename in
  let lexbuf = Lexing.from_string content in
  try
    Loop.Parser.program Loop.Lexer.token lexbuf
  with
  | Loop.Lexer.Lexical_error msg ->
      eprintf "Lexical error in %s: %s\n" filename msg;
      exit 1
  | Loop.Parser.Error ->
      eprintf "Parse error in %s at position %d\n" 
        filename (Lexing.lexeme_start lexbuf);
      exit 1

(** Parse a WHILE program from file *)
let parse_while_file filename =
  let content = Common.Utils.read_file filename in
  let lexbuf = Lexing.from_string content in
  try
    While_lang.Parser.program While_lang.Lexer.token lexbuf
  with
  | While_lang.Lexer.Lexical_error msg ->
      eprintf "Lexical error in %s: %s\n" filename msg;
      exit 1
  | While_lang.Parser.Error ->
      eprintf "Parse error in %s at position %d\n" 
        filename (Lexing.lexeme_start lexbuf);
      exit 1

(** Parse a GOTO program from file *)
let parse_goto_file filename =
  let content = Common.Utils.read_file filename in
  let lexbuf = Lexing.from_string content in
  try
    Goto.Parser.program Goto.Lexer.token lexbuf
  with
  | Goto.Lexer.Lexical_error msg ->
      eprintf "Lexical error in %s: %s\n" filename msg;
      exit 1
  | Goto.Parser.Error ->
      eprintf "Parse error in %s at position %d\n" 
        filename (Lexing.lexeme_start lexbuf);
      exit 1

(** Interpret command *)
let do_interpret language file trace =
  printf "Interpreting %s program: %s\n" language file;
  if trace then printf "Trace mode enabled\n\n";
  
  let mode = if trace then Loop.Interpreter.Trace else Loop.Interpreter.Normal in
  
  let final_state = match language with
    | "loop" ->
        let prog = parse_loop_file file in
        printf "Program:\n%s\n\n" (Loop.Ast.string_of_program prog);
        Loop.Interpreter.run_empty ~mode prog
    
    | "while" ->
        let prog = parse_while_file file in
        printf "Program:\n%s\n\n" (While_lang.Ast.string_of_program prog);
        let mode' = if trace then While_lang.Interpreter.Trace else While_lang.Interpreter.Normal in
        While_lang.Interpreter.run_empty ~mode:mode' prog
    
    | "goto" ->
        let prog = parse_goto_file file in
        printf "Program:\n%s\n\n" (Goto.Ast.string_of_program prog);
        let mode' = if trace then Goto.Interpreter.Trace else Goto.Interpreter.Normal in
        Goto.Interpreter.run_empty ~mode:mode' prog
    
    | _ ->
        eprintf "Unknown language: %s\n" language;
        exit 1
  in
  
  printf "\n=== Final State ===\n";
  Common.State.print final_state

(** Translate command *)
let do_translate source target file output verify =
  printf "Translating %s to %s: %s\n" source target file;
  
  let result = match (source, target) with
    | ("loop", "while") ->
        let prog = parse_loop_file file in
        printf "\nSource LOOP program:\n%s\n\n" (Loop.Ast.string_of_program prog);
        let translated = Translators.Loop_to_while.translate_fresh prog in
        printf "Translated WHILE program:\n%s\n" (While_lang.Ast.string_of_program translated);
        
        if verify then (
          printf "\n=== Verifying Translation ===\n";
          let state_loop = Loop.Interpreter.run_empty prog in
          let state_while = While_lang.Interpreter.run_empty translated in
          printf "LOOP  final state: %s\n" (Common.State.to_string state_loop);
          printf "WHILE final state: %s\n" (Common.State.to_string state_while);
          if state_loop = state_while then
            printf "✓ Translation verified: states match!\n"
          else
            printf "✗ Translation verification failed: states differ!\n"
        );
        
        While_lang.Ast.string_of_program translated
    
    | ("while", "goto") ->
        let prog = parse_while_file file in
        printf "\nSource WHILE program:\n%s\n\n" (While_lang.Ast.string_of_program prog);
        let translated = Translators.While_to_goto.translate_program prog in
        printf "Translated GOTO program:\n%s\n" (Goto.Ast.string_of_program translated);
        
        if verify then (
          printf "\n=== Verifying Translation ===\n";
          let state_while = While_lang.Interpreter.run_empty prog in
          let state_goto = Goto.Interpreter.run_empty translated in
          printf "WHILE final state: %s\n" (Common.State.to_string state_while);
          printf "GOTO  final state: %s\n" (Common.State.to_string state_goto);
          if state_while = state_goto then
            printf "✓ Translation verified: states match!\n"
          else
            printf "✗ Translation verification failed: states differ!\n"
        );
        
        Goto.Ast.string_of_program translated
    
    | ("goto", "while") ->
        let prog = parse_goto_file file in
        printf "\nSource GOTO program:\n%s\n\n" (Goto.Ast.string_of_program prog);
        let translated = Translators.Goto_to_while.translate_program prog in
        printf "Translated WHILE program:\n%s\n" (While_lang.Ast.string_of_program translated);
        
        if verify then (
          printf "\n=== Verifying Translation ===\n";
          let state_goto = Goto.Interpreter.run_empty prog in
          let state_while = While_lang.Interpreter.run_empty translated in
          printf "GOTO  final state: %s\n" (Common.State.to_string state_goto);
          printf "WHILE final state: %s\n" (Common.State.to_string state_while);
          if state_goto = state_while then
            printf "✓ Translation verified: states match!\n"
          else
            printf "✗ Translation verification failed: states differ!\n"
        );
        
        While_lang.Ast.string_of_program translated
    
    | _ ->
        eprintf "Unsupported translation: %s-to-%s\n" source target;
        eprintf "Supported translations: loop-to-while, while-to-goto, goto-to-while\n";
        exit 1
  in
  
  (* Write output if specified *)
  (match output with
   | Some filename ->
       Common.Utils.write_file filename result;
       printf "\nOutput written to: %s\n" filename
   | None -> ())

(** Main entry point *)
let () =
  try
    match parse_args () with
    | Help -> print_help ()
    | Interpret { language; file; trace } -> do_interpret language file trace
    | Translate { source; target; file; output; verify } -> 
        do_translate source target file output verify
  with
  | Sys_error msg ->
      eprintf "Error: %s\n" msg;
      exit 1
  | Failure msg ->
      eprintf "Error: %s\n" msg;
      exit 1
  | While_lang.Interpreter.InfiniteLoop msg
  | Goto.Interpreter.InfiniteLoop msg ->
      eprintf "Infinite loop detected: %s\n" msg;
      exit 1
  | Goto.Interpreter.UndefinedLabel label ->
      eprintf "Undefined label: %s\n" label;
      exit 1

