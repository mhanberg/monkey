defmodule Monkey.Evaluator do
  alias Monkey.Ast
  alias Monkey.Object
  alias Monkey.Object.Obj

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

      %Ast.PrefixExpression{right: right, operator: operator} ->
        right = run(right)
        eval_prefix_expression(operator, right)

      %Ast.InfixExpression{left: left, right: right, operator: operator} ->
        left = run(left)
        right = run(right)
        eval_infix_expression(operator, left, right)

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

  defp eval_prefix_expression(operator, right) do
    case operator do
      "!" ->
        eval_bang_operator(right)

      "-" ->
        eval_minus_prefix_operator(right)

      _ ->
        @null_object
    end
  end

  defp eval_infix_expression(operator, left, right) do
    cond do
      Obj.type(left) == Object.types(:integer_obj) &&
          Obj.type(right) == Object.types(:integer_obj) ->
        eval_integer_infix_expression(operator, left, right)

      operator == "==" ->
        native_boolean_to_boolean_object(left == right)

      operator == "!=" ->
        native_boolean_to_boolean_object(left != right)

      true ->
        @null_object
    end
  end

  defp eval_bang_operator(right) do
    case right do
      @true_object ->
        @false_object

      @false_object ->
        @true_object

      @null_object ->
        @true_object

      _ ->
        @false_object
    end
  end

  defp eval_minus_prefix_operator(right) do
    if Obj.type(right) != Object.types(:integer_obj) do
      @null_object
    else
      %Object.Integer{value: -right.value}
    end
  end

  defp eval_integer_infix_expression(operator, left, right) do
    left_val = left.value
    right_val = right.value

    case operator do
      "+" ->
        %Object.Integer{value: left_val + right_val}

      "-" ->
        %Object.Integer{value: left_val - right_val}

      "*" ->
        %Object.Integer{value: left_val * right_val}

      "/" ->
        %Object.Integer{value: div(left_val, right_val)}

      ">" ->
        native_boolean_to_boolean_object(left_val > right_val)

      "<" ->
        native_boolean_to_boolean_object(left_val < right_val)

      "==" ->
        native_boolean_to_boolean_object(left_val == right_val)

      "!=" ->
        native_boolean_to_boolean_object(left_val != right_val)

      _ ->
        @null_object
    end
  end

  defp native_boolean_to_boolean_object(true), do: @true_object
  defp native_boolean_to_boolean_object(false), do: @false_object
end
