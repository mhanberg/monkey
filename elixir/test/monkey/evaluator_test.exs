defmodule Monkey.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Monkey.Evaluator
  alias Monkey.Lexer
  alias Monkey.Object
  alias Monkey.Parser

  test "eval integer expression" do
    tests = [
      {"5", 5},
      {"10", 10},
      {"-5", -5},
      {"-10", -10},
      {"5 + 5 + 5 + 5 - 10", 10},
      {"2 * 2 * 2 * 2 * 2", 32},
      {"-50 + 100 + -50", 0},
      {"5 * 2 + 10", 20},
      {"5 + 2 * 10", 25},
      {"20 + 2 * -10", 0},
      {"50 / 2 * 2 + 10", 60},
      {"2 * (5 + 10)", 30},
      {"3 * 3 * 3 + 10", 37},
      {"3 * (3 * 3) + 10", 37},
      {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_integer_object(evaluated, expected)
    end
  end

  test "boolean expressions" do
    tests = [
      {"true", true},
      {"false", false},
      {"1 < 2", true},
      {"1 > 2", false},
      {"1 < 1", false},
      {"1 > 1", false},
      {"1 == 1", true},
      {"1 != 1", false},
      {"1 == 2", false},
      {"1 != 2", true},
      {"true == true", true},
      {"false == false", true},
      {"true == false", false},
      {"true != false", true},
      {"false != true", true},
      {"(1 < 2) == true", true},
      {"(1 < 2) == false", false},
      {"(1 > 2) == true", false},
      {"(1 > 2) == false", true}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_boolean_object(evaluated, expected)
    end
  end

  test "bang operator" do
    tests = [
      {"!true", false},
      {"!false", true},
      {"!5", false},
      {"!!true", true},
      {"!!false", false},
      {"!!5", true}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_boolean_object(evaluated, expected)
    end
  end

  test "if else expressions" do
    tests = [
      {"if (true) { 10 }", 10},
      {"if (false) { 10 }", nil},
      {"if (1) { 10 }", 10},
      {"if (1 < 2) { 10 }", 10},
      {"if (1 > 2) { 10 }", nil},
      {"if (1 > 2) { 10 } else { 20 }", 20},
      {"if (1 < 2) { 10 } else { 20 }", 10}
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
      {"return 10;", 10},
      {"return 10; 9;", 10},
      {"return 2 * 5; 9;", 10},
      {"9; return 2 * 5; 9;", 10},
      {"if (10 > 1) { return 10; }", 10},
      {
        """
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
      {"5 + true;", "type mismatch: INTEGER + BOOLEAN"},
      {"5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"},
      {"-true", "unknown operator: -BOOLEAN"},
      {"true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
      {"true + false + true + false;", "unknown operator: BOOLEAN + BOOLEAN"},
      {"5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"},
      {"if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"},
      {
        """
        if (10 > 1) {
          if (10 > 1) {
            return true + false;
          }

          return 1;
        }
        """,
        "unknown operator: BOOLEAN + BOOLEAN"
      }
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      assert %Object.Error{message: message} = evaluated
      assert expected == message
    end
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
    |> Evaluator.run()
  end
end
