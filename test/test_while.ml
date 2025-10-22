(** Tests for WHILE interpreter *)

open While_lang
open Common

let test_countdown () =
  let prog = Ast.(
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
  let initial = State.of_list [("x1", 5)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 5" 5 (State.get result "x0");
  Alcotest.(check int) "x1 should be 0" 0 (State.get result "x1")

let test_while_condition_false () =
  let prog = Ast.(
    Seq (
      Assign ("x0", Const 10),
      While (
        Compare (Var "x1", Neq, Const 0),
        Assign ("x0", Const 99)
      )
    )
  ) in
  let initial = State.of_list [("x1", 0)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 10 (loop not executed)" 10 (State.get result "x0")

let test_fibonacci () =
  let prog = Ast.(
    Seq (
      Seq (
        Seq (
          Assign ("x0", Const 0),
          Assign ("x2", Const 1)
        ),
        Assign ("x3", Const 0)
      ),
      While (
        Compare (Var "x1", Neq, Const 0),
        Seq (
          Seq (
            Seq (
              Assign ("x3", Add (Var "x0", Var "x2")),
              Assign ("x0", Var "x2")
            ),
            Assign ("x2", Var "x3")
          ),
          Assign ("x1", Sub (Var "x1", Const 1))
        )
      )
    )
  ) in
  let initial = State.of_list [("x1", 7)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "fib(7) should be 13" 13 (State.get result "x0")

let test_comparison_operators () =
  let prog = Ast.(
    Seq (
      Assign ("x0", Const 0),
      Seq (
        While (Compare (Var "x1", Lt, Const 5), 
          Seq (
            Assign ("x0", Const 1),
            Assign ("x1", Add (Var "x1", Const 1))
          )
        ),
        Seq (
          While (Compare (Var "x2", Geq, Const 10),
            Seq (
              Assign ("x0", Const 2),
              Assign ("x2", Sub (Var "x2", Const 1))
            )
          ),
          While (Compare (Var "x3", Eq, Const 7),
            Seq (
              Assign ("x0", Const 3),
              Assign ("x3", Const 0)
            )
          )
        )
      )
    )
  ) in
  let initial = State.of_list [("x1", 3); ("x2", 15); ("x3", 7)] in
  let result = Interpreter.run prog initial in
  Alcotest.(check int) "x0 should be 3" 3 (State.get result "x0")

let () =
  Alcotest.run "WHILE Interpreter" [
    "basic", [
      Alcotest.test_case "Countdown" `Quick test_countdown;
      Alcotest.test_case "Condition false" `Quick test_while_condition_false;
      Alcotest.test_case "Fibonacci" `Quick test_fibonacci;
      Alcotest.test_case "Comparison operators" `Quick test_comparison_operators;
    ]
  ]

