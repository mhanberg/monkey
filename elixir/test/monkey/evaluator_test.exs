defmodule Monkey.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Monkey.Evaluator
  alias Monkey.Lexer
  alias Monkey.Object
  alias Monkey.Parser

  test "eval integer expression" do
    tests = [
      {"5", 5},
      {"10", 10}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_integer_object(evaluated, expected)
    end
  end

  test "boolean expressions" do
    tests = [
      {"true", true},
      {"false", false}
    ]

    for {input, expected} <- tests do
      evaluated = test_eval(input)
      test_boolean_object(evaluated, expected)
    end
  end

  defp test_integer_object(evaluted, expected) do
    assert %Object.Integer{value: ^expected} = evaluted
  end

  defp test_boolean_object(evaluted, expected) do
    assert %Object.Boolean{value: ^expected} = evaluted
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
