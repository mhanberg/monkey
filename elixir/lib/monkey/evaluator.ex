defmodule Monkey.Evaluator do
  alias Monkey.Ast
  alias Monkey.Object
  alias Monkey.Object.Obj

  @null_object %Object.Null{}
  @true_object %Object.Boolean{value: true}
  @false_object %Object.Boolean{value: false}

  def run(node) do
    case node do
      %Ast.Program{} = program ->
        eval_program(program)

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

        if error?(right) do
          right
        else
          eval_prefix_expression(operator, right)
        end

      %Ast.InfixExpression{left: left, right: right, operator: operator} ->
        with left <- run(left),
             {false, _} <- {error?(left), left},
             right <- run(right),
             {false, _} <- {error?(right), right} do
          eval_infix_expression(operator, left, right)
        else
          {true, error} ->
            error
        end

      %Ast.BlockStatement{} = block_statement ->
        eval_block_statement(block_statement)

      %Ast.IfExpression{} = if_expression ->
        eval_if_expression(if_expression)

      %Ast.ReturnStatement{return_value: return_value} ->
        val = run(return_value)

        if error?(val) do
          val
        else
          %Object.ReturnValue{value: val}
        end

      _ ->
        @null_object
    end
  end

  defp eval_program(%Ast.Program{statements: statements}) do
    for statement <- statements, reduce: nil do
      %Object.ReturnValue{} = result ->
        result

      %Object.Error{} = result ->
        result

      _ ->
        run(statement)
    end
    |> then(fn
      %Object.ReturnValue{value: value} -> value
      other -> other
    end)
  end

  defp eval_block_statement(%Ast.BlockStatement{statements: statements}) do
    for statement <- statements, reduce: nil do
      %Object.ReturnValue{} = result ->
        result

      %Object.Error{} = result ->
        result

      _ ->
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
        %Object.Error{message: "unknown operator: #{operator}#{Obj.type(right)}"}
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

      Obj.type(left) != Obj.type(right) ->
        %Object.Error{message: "type mismatch: #{Obj.type(left)} #{operator} #{Obj.type(right)}"}

      true ->
        %Object.Error{
          message: "unknown operator: #{Obj.type(left)} #{operator} #{Obj.type(right)}"
        }
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
      %Object.Error{message: "unknown operator: -#{Obj.type(right)}"}
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
        %Object.Error{
          message: "unknown operator: #{Obj.type(left)} #{operator}#{Obj.type(right)}"
        }
    end
  end

  defp eval_if_expression(%Ast.IfExpression{
         condition: condition,
         consequence: consequence,
         alternative: alternative
       }) do
    condition = run(condition)

    cond do
      error?(condition) ->
        condition

      truthy?(condition) ->
        run(consequence)

      alternative != nil ->
        run(alternative)

      true ->
        @null_object
    end
  end

  defp native_boolean_to_boolean_object(true), do: @true_object
  defp native_boolean_to_boolean_object(false), do: @false_object

  defp truthy?(@null_object), do: false
  defp truthy?(@true_object), do: true
  defp truthy?(@false_object), do: false
  defp truthy?(_), do: true

  defp error?(nil) do
    false
  end

  defp error?(obj) do
    Obj.type(obj) == Object.types(:error_obj)
  end
end
