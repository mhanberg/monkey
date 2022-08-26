defmodule Monkey.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Monkey.Evaluator
  alias Monkey.Lexer
  alias Monkey.Object
  alias Monkey.Parser
  alias Monkey.Environment

  import Monkey.Support.Utils

  test "eval integer expression" do
    tests = [
      {~M"5", 5},
      {~M"10", 10},
      {~M"-5", -5},
      {~M"-10", -10},
      {~M"5 + 5 + 5 + 5 - 10", 10},
      {~M"2 * 2 * 2 * 2 * 2", 32},
      {~M"-50 + 100 + -50", 0},
      {~M"5 * 2 + 10", 20},
      {~M"5 + 2 * 10", 25},
      {~M"20 + 2 * -10", 0},
      {~M"50 / 2 * 2 + 10", 60},
      {~M"2 * (5 + 10)", 30},
      {~M"3 * 3 * 3 + 10", 37},
      {~M"3 * (3 * 3) + 10", 37},
      {~M"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_integer_object(evaluated, expected)
    end
  end

  test "boolean expressions" do
    tests = [
      {~M"true", true},
      {~M"false", false},
      {~M"1 < 2", true},
      {~M"1 > 2", false},
      {~M"1 < 1", false},
      {~M"1 > 1", false},
      {~M"1 == 1", true},
      {~M"1 != 1", false},
      {~M"1 == 2", false},
      {~M"1 != 2", true},
      {~M"true == true", true},
      {~M"false == false", true},
      {~M"true == false", false},
      {~M"true != false", true},
      {~M"false != true", true},
      {~M"(1 < 2) == true", true},
      {~M"(1 < 2) == false", false},
      {~M"(1 > 2) == true", false},
      {~M"(1 > 2) == false", true}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_boolean_object(evaluated, expected)
    end
  end

  test "bang operator" do
    tests = [
      {~M"!true", false},
      {~M"!false", true},
      {~M"!5", false},
      {~M"!!true", true},
      {~M"!!false", false},
      {~M"!!5", true}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_boolean_object(evaluated, expected)
    end
  end

  test "if else expressions" do
    tests = [
      {~M"if (true) { 10 }", 10},
      {~M"if (false) { 10 }", nil},
      {~M"if (1) { 10 }", 10},
      {~M"if (1 < 2) { 10 }", 10},
      {~M"if (1 > 2) { 10 }", nil},
      {~M"if (1 > 2) { 10 } else { 20 }", 20},
      {~M"if (1 < 2) { 10 } else { 20 }", 10}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)

      if is_integer(expected) do
        test_integer_object(evaluated, expected)
      else
        test_null_object(evaluated)
      end
    end
  end

  test "return statement" do
    tests = [
      {~M"return 10;", 10},
      {~M"return 10; 9;", 10},
      {~M"return 2 * 5; 9;", 10},
      {~M"9; return 2 * 5; 9;", 10},
      {
        ~M"if (10 > 1) { return 10; }",
        10
      },
      {
        ~M"""
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }

          return 1;
        }
        """,
        10
      }
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_integer_object(evaluated, expected)
    end
  end

  test "error handling" do
    tests = [
      {~M"5 + true;", "type mismatch: INTEGER + BOOLEAN"},
      {~M"5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"},
      {~M"-true", "unknown operator: -BOOLEAN"},
      {~M"true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
      {~M"true + false + true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
      {~M"5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"},
      {~M"if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"},
      {
        ~M"""
        if (10 > 1) {
          if (10 > 1) {
            return true + false;
          }

          return 1;
        }
        """,
        "unknown operator: BOOLEAN + BOOLEAN"
      },
      {~M"foobar", "identifier not found: foobar"}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      assert %Object.Error{message: message} = evaluated
      assert expected == message
    end
  end

  test "let statement" do
    tests = [
      {~M"let a = 5; a;", 5},
      {~M"let a = 5 * 5; a;", 25},
      {~M"let a = 5; let b = a; b;", 5},
      {~M"let a = 5; let b = a; let c = a + b + 5; c;", 15}
    ]

    for {input, expected} <- tests do
      input |> test_eval() |> test_integer_object(expected)
    end
  end

  test "function statement" do
    input = ~M"fn(x) { x + 2; };"

    assert %Object.Function{
             parameters: [
               parameter
             ],
             body: body
           } = test_eval(input)

    assert ~M"x" == Monkey.Ast.Node.string(parameter)
    assert ~M"(x + 2)" == Monkey.Ast.Node.string(body)
  end

  test "function application" do
    tests = [
      {~M"let identity = fn(x) { x; }; identity(5);", 5},
      {~M"let identity = fn(x) { return x; }; identity(5);", 5},
      {~M"let double = fn(x) { x * 2; }; double(5);", 10},
      {~M"let add = fn(x, y) { x + y; }; add(5, 5);", 10},
      {
        ~M"let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));",
        20
      },
      {~M"fn(x) { x; }(5)", 5}
    ]

    for {input, expected} <- tests do
      input |> test_eval() |> test_integer_object(expected)
    end
  end

  test "closures" do
    input = ~M"""
    let newAdder = fn(x) {
      fn(y) { x + y };
    };

    let addTwo = newAdder(2);
    addTwo(2);
    """

    test_integer_object(test_eval(input), 4)
  end

  defp test_integer_object(evaluated, expected) do
    assert %Object.Integer{value: ^expected} = evaluated
  end

  defp test_boolean_object(evaluated, expected) do
    assert %Object.Boolean{value: ^expected} = evaluated
  end

  defp test_null_object(evaluated) do
    assert %Object.Null{} = evaluated
  end

  defp test_eval(input) do
    input
    |> Lexer.new()
    |> Parser.new()
    |> Parser.parse_program()
    |> elem(1)
    |> Evaluator.run(Environment.new())
    |> elem(0)
  end
end
