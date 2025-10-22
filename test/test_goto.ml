(** Tests for GOTO interpreter *)

open Goto
open Common

let test_simple_goto () =
  let open Ast in
  let prog = [
    { label = None; instr = Assign ("x0", Const 1) };
    { label = None; instr = Goto "END" };
    { label = None; instr = Assign ("x0", Const 99) };  (* Should be skipped *)
    { label = Some "END"; instr = Halt };
  ] in
  let result = Interpreter.run_empty prog in
  Alcotest.(check int) "x0 should be 1" 1 (State.get result "x0")

let test_conditional_goto () =
  let open Ast in
  let prog = [
    { label = None; instr = Assign ("x0", Const 0) };
    { label = None; instr = IfGoto (Var "x1", Eq, Const 5, "MATCH") };
    { label = None; instr = Assign ("x0", Const 1) };
    { label = None; instr = Goto "END" };
    { label = Some "MATCH"; instr = Assign ("x0", Const 2) };
    { label = Some "END"; instr = Halt };
  ] in
  let initial = State.of_list [("x1", 5)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 2 (condition true)" 2 (State.get result "x0")

let test_loop_with_goto () =
  (* Count from x1 down to 0 *)
  let open Ast in
  let prog = [
    { label = None; instr = Assign ("x0", Const 0) };
    { label = Some "LOOP"; instr = IfGoto (Var "x1", Eq, Const 0, "END") };
    { label = None; instr = Assign ("x0", Add (Var "x0", Const 1)) };
    { label = None; instr = Assign ("x1", Sub (Var "x1", Const 1)) };
    { label = None; instr = Goto "LOOP" };
    { label = Some "END"; instr = Halt };
  ] in
  let initial = State.of_list [("x1", 5)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 5" 5 (State.get result "x0");
  Alcotest.(check int) "x1 should be 0" 0 (State.get result "x1")

let test_max () =
  let open Ast in
  let prog = [
    { label = None; instr = IfGoto (Var "x1", Geq, Var "x2", "FIRST") };
    { label = None; instr = Assign ("x0", Var "x2") };
    { label = None; instr = Goto "END" };
    { label = Some "FIRST"; instr = Assign ("x0", Var "x1") };
    { label = Some "END"; instr = Halt };
  ] in
  let initial = State.of_list [("x1", 7); ("x2", 10)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 10 (max)" 10 (State.get result "x0")

let () =
  Alcotest.run "GOTO Interpreter" [
    "basic", [
      Alcotest.test_case "Simple GOTO" `Quick test_simple_goto;
      Alcotest.test_case "Conditional GOTO" `Quick test_conditional_goto;
      Alcotest.test_case "Loop with GOTO" `Quick test_loop_with_goto;
      Alcotest.test_case "Max of two numbers" `Quick test_max;
    ]
  ]

