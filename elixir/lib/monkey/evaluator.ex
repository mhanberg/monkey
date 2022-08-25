defmodule Monkey.Evaluator do
  alias Monkey.Ast
  alias Monkey.Object

  @null_object %Object.Null{}
  @true_object %Object.Boolean{value: true}
  @false_object %Object.Boolean{value: false}

  def run(node) do
    case node do
      %Ast.Program{statements: statements} ->
        eval_statements(statements)

      %Ast.ExpressionStatement{expression: expression} ->
        run(expression)

      %Ast.IntegerLiteral{value: value} ->
        %Object.Integer{value: value}

      %Ast.Boolean{value: true} ->
        @true_object

      %Ast.Boolean{value: false} ->
        @false_object

      _ ->
        @null_object
    end
  end

  defp eval_statements(statements) do
    for statement <- statements, reduce: nil do
      _result ->
        run(statement)
    end
  end
end
