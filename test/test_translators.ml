(** Tests for translators *)

open Common

let test_loop_to_while_addition () =
  let loop_prog = Loop.Ast.(
    Seq (
      Assign ("x0", Var "x1"),
      Loop ("x2", Assign ("x0", Add (Var "x0", Const 1)))
    )
  ) in
  let while_prog = Translators.Loop_to_while.translate_fresh loop_prog in
  
  let initial = State.of_list [("x1", 5); ("x2", 3)] in
  let loop_result = Loop.Interpreter.run loop_prog initial in
  let while_result = While_lang.Interpreter.run while_prog initial in
  
  Alcotest.(check int) "Results should match" 
    (State.get loop_result "x0") 
    (State.get while_result "x0")

let test_loop_to_while_multiplication () =
  let loop_prog = Loop.Ast.(
    Seq (
      Assign ("x0", Const 0),
      Loop ("x1", 
        Loop ("x2", 
          Assign ("x0", Add (Var "x0", Const 1))
        )
      )
    )
  ) in
  let while_prog = Translators.Loop_to_while.translate_fresh loop_prog in
  
  let initial = State.of_list [("x1", 4); ("x2", 3)] in
  let _loop_result = Loop.Interpreter.run loop_prog initial in
  let while_result = While_lang.Interpreter.run while_prog initial in
  
  Alcotest.(check int) "Results should match (12)" 
    12
    (State.get while_result "x0")

let test_while_to_goto_countdown () =
  let while_prog = While_lang.Ast.(
    Seq (
      Assign ("x0", Const 0),
      While (
        Compare (Var "x1", Neq, Const 0),
        Seq (
          Assign ("x0", Add (Var "x0", Const 1)),
          Assign ("x1", Sub (Var "x1", Const 1))
        )
      )
    )
  ) in
  let goto_prog = Translators.While_to_goto.translate_program while_prog in
  
  let initial = State.of_list [("x1", 5)] in
  let while_result = While_lang.Interpreter.run while_prog initial in
  let goto_result = Goto.Interpreter.run goto_prog initial in
  
  Alcotest.(check int) "Results should match" 
    (State.get while_result "x0") 
    (State.get goto_result "x0")

let test_goto_to_while_max () =
  let open Goto.Ast in
  let goto_prog = [
    { label = None; instr = IfGoto (Var "x1", Geq, Var "x2", "FIRST") };
    { label = None; instr = Assign ("x0", Var "x2") };
    { label = None; instr = Goto "END" };
    { label = Some "FIRST"; instr = Assign ("x0", Var "x1") };
    { label = Some "END"; instr = Halt };
  ] in
  let while_prog = Translators.Goto_to_while.translate_program goto_prog in
  
  let initial = State.of_list [("x1", 7); ("x2", 10)] in
  let _goto_result = Goto.Interpreter.run goto_prog initial in
  let while_result = While_lang.Interpreter.run while_prog initial in
  
  Alcotest.(check int) "Results should match (max=10)" 
    10
    (State.get while_result "x0")

let test_round_trip_loop_while_goto () =
  (* LOOP -> WHILE -> GOTO and verify equivalence *)
  let loop_prog = Loop.Ast.(
    Seq (
      Assign ("x0", Const 1),
      Loop ("x1", Assign ("x0", Mul (Var "x0", Const 2)))
    )
  ) in
  
  let while_prog = Translators.Loop_to_while.translate_fresh loop_prog in
  let goto_prog = Translators.While_to_goto.translate_program while_prog in
  
  let initial = State.of_list [("x1", 3)] in
  let loop_result = Loop.Interpreter.run loop_prog initial in
  let goto_result = Goto.Interpreter.run goto_prog initial in
  
  Alcotest.(check int) "Round-trip LOOP->WHILE->GOTO should match" 
    (State.get loop_result "x0") 
    (State.get goto_result "x0")

let () =
  Alcotest.run "Translators" [
    "loop_to_while", [
      Alcotest.test_case "Addition" `Quick test_loop_to_while_addition;
      Alcotest.test_case "Multiplication" `Quick test_loop_to_while_multiplication;
    ];
    "while_to_goto", [
      Alcotest.test_case "Countdown" `Quick test_while_to_goto_countdown;
    ];
    "goto_to_while", [
      Alcotest.test_case "Max" `Quick test_goto_to_while_max;
    ];
    "round_trip", [
      Alcotest.test_case "LOOP->WHILE->GOTO" `Quick test_round_trip_loop_while_goto;
    ];
  ]

