(** Tests for LOOP interpreter *)

open Loop
open Common

let test_addition () =
  let prog = Ast.(
    Seq (
      Assign ("x0", Var "x1"),
      Loop ("x2", Assign ("x0", Add (Var "x0", Const 1)))
    )
  ) in
  let initial = State.of_list [("x1", 5); ("x2", 3)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 8" 8 (State.get result "x0")

let test_multiplication () =
  let prog = Ast.(
    Seq (
      Assign ("x0", Const 0),
      Loop ("x1", 
        Loop ("x2", 
          Assign ("x0", Add (Var "x0", Const 1))
        )
      )
    )
  ) in
  let initial = State.of_list [("x1", 3); ("x2", 4)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 12" 12 (State.get result "x0")

let test_zero_iterations () =
  let prog = Ast.(
    Seq (
      Assign ("x0", Const 10),
      Loop ("x1", Assign ("x0", Const 99))
    )
  ) in
  let initial = State.of_list [("x1", 0)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 10 (loop not executed)" 10 (State.get result "x0")

let test_nested_loops () =
  (* Compute x1^x2 *)
  let prog = Ast.(
    Seq (
      Seq (
        Assign ("x0", Const 1),
        Assign ("x3", Const 0)
      ),
      Loop ("x2",
        Seq (
          Assign ("x3", Const 0),
          Seq (
            Loop ("x1",
              Assign ("x3", Add (Var "x3", Var "x0"))
            ),
            Assign ("x0", Var "x3")
          )
        )
      )
    )
  ) in
  let initial = State.of_list [("x1", 2); ("x2", 3)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 8 (2^3)" 8 (State.get result "x0")

let () =
  Alcotest.run "LOOP Interpreter" [
    "basic", [
      Alcotest.test_case "Addition" `Quick test_addition;
      Alcotest.test_case "Multiplication" `Quick test_multiplication;
      Alcotest.test_case "Zero iterations" `Quick test_zero_iterations;
      Alcotest.test_case "Nested loops" `Quick test_nested_loops;
    ]
  ]

