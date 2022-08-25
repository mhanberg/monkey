defmodule Monkey.Evaluator do
  alias Monkey.Ast
  alias Monkey.Object

  def run(node) do
    case node do
      %Ast.Program{statements: statements} ->
        eval_statements(statements)

      %Ast.ExpressionStatement{expression: expression} ->
        run(expression)

      %Ast.IntegerLiteral{value: value} ->
        %Object.Integer{value: value}

      _ ->
        nil
    end
  end

  defp eval_statements(statements) do
    for statement <- statements, reduce: nil do
      _result ->
        run(statement)
    end
  end
end
