defmodule Monkey.Evaluator do
  alias Monkey.Ast
  alias Monkey.Object
  alias Monkey.Environment
  alias Monkey.Object.Obj

  @null_object %Object.Null{}
  @true_object %Object.Boolean{value: true}
  @false_object %Object.Boolean{value: false}

  def run(node, %Environment{} = env) do
    case node do
      %Ast.Program{} = program ->
        eval_program(program, env)

      %Ast.LetStatement{name: name, value: value} ->
        {val, env} = run(value, env)

        if error?(val) do
          {val, env}
        else
          {nil, Environment.set(env, name.value, val)}
        end

      %Ast.Identifier{} = identifier ->
        eval_identifier(identifier, env)

      %Ast.FunctionLiteral{parameters: parameters, body: body} ->
        {%Object.Function{parameters: parameters, body: body, env: env}, env}

      %Ast.CallExpression{function: function, arguments: arguments} ->
        {function, env} = run(function, env)

        if error?(function) do
          {function, env}
        else
          {args, env} = eval_expressions(arguments, env)

          if length(args) == 1 && error?(List.first(args)) do
            {List.first(args), env}
          end

          {apply_function(function, args), env}
        end

      %Ast.ExpressionStatement{expression: expression} ->
        run(expression, env)

      %Ast.IntegerLiteral{value: value} ->
        {%Object.Integer{value: value}, env}

      %Ast.Boolean{value: true} ->
        {@true_object, env}

      %Ast.Boolean{value: false} ->
        {@false_object, env}

      %Ast.PrefixExpression{right: right, operator: operator} ->
        {right, env} = run(right, env)

        v =
          if error?(right) do
            right
          else
            eval_prefix_expression(operator, right)
          end

        {v, env}

      %Ast.InfixExpression{left: left, right: right, operator: operator} ->
        with {left, env} <- run(left, env),
             {false, _} <- {error?(left), left},
             {right, env} <- run(right, env),
             {false, _} <- {error?(right), right} do
          {eval_infix_expression(operator, left, right), env}
        else
          {true, error} ->
            {error, env}
        end

      %Ast.BlockStatement{} = block_statement ->
        eval_block_statement(block_statement, env)

      %Ast.IfExpression{} = if_expression ->
        eval_if_expression(if_expression, env)

      %Ast.ReturnStatement{return_value: return_value} ->
        {val, env} = run(return_value, env)

        if error?(val) do
          {val, env}
        else
          {%Object.ReturnValue{value: val}, env}
        end

      _ ->
        {@null_object, env}
    end
  end

  defp eval_program(%Ast.Program{statements: statements}, env) do
    for statement <- statements, reduce: {nil, env} do
      {%Object.ReturnValue{}, _} = result ->
        result

      {%Object.Error{}, _} = result ->
        result

      {_, env} ->
        run(statement, env)
    end
    |> then(fn
      {%Object.ReturnValue{value: value}, env} -> {value, env}
      other -> other
    end)
  end

  defp eval_block_statement(%Ast.BlockStatement{statements: statements}, env) do
    for statement <- statements, reduce: {nil, env} do
      {%Object.ReturnValue{}, _} = result ->
        result

      {%Object.Error{}, _} = result ->
        result

      {_, env} ->
        run(statement, env)
    end
    |> then(fn
      {_, _} = ret -> ret
      ret -> {ret, env}
    end)
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

  defp eval_if_expression(
         %Ast.IfExpression{
           condition: condition,
           consequence: consequence,
           alternative: alternative
         },
         env
       ) do
    {condition, env} = run(condition, env)

    cond do
      error?(condition) ->
        {condition, env}

      truthy?(condition) ->
        run(consequence, env)

      alternative != nil ->
        run(alternative, env)

      true ->
        {@null_object, env}
    end
  end

  defp eval_identifier(%Ast.Identifier{} = identifier, %Environment{} = env) do
    v =
      case Environment.get(env, identifier.value) do
        {:ok, val} ->
          val

        :error ->
          %Object.Error{message: "identifier not found: #{identifier.value}"}
      end

    {v, env}
  end

  defp eval_expressions(expressions, env) do
    for expression <- expressions, reduce: {[], env} do
      {[%Object.Error{} | _rest], _} = result ->
        result

      {evaluated_args, env} ->
        {evalulated, env} = run(expression, env)
        {[evalulated | evaluated_args], env}
    end
    |> then(fn
      {[%Object.Error{} = error | _], env} ->
        {[error], env}

      {args, env} ->
        {Enum.reverse(args), env}
    end)
  end

  defp apply_function(%Object.Function{} = function, args) do
    extended_env = extend_function_env(function, args)

    {evaluated, _env} = run(function.body, extended_env)

    unwrap_return_value(evaluated)
  end

  defp apply_function(function, _args, env) do
    {%Object.Error{message: "not a function: #{Obj.type(function)}"}, env}
  end

  defp extend_function_env(function, args) do
    env = Environment.new_enclosed(function.env)

    for {param, arg} <- Enum.zip(function.parameters, args), reduce: env do
      env ->
        Environment.set(env, param.value, arg)
    end
  end

  defp unwrap_return_value(%Object.ReturnValue{value: value}) do
    value
  end

  defp unwrap_return_value(other), do: other

  defp native_boolean_to_boolean_object(true), do: @true_object
  defp native_boolean_to_boolean_object(false), do: @false_object

  defp truthy?(@null_object), do: false
  defp truthy?(@true_object), do: true
  defp truthy?(@false_object), do: false
  defp truthy?(_), do: true

  defp error?({obj, _env}) do
    error?(obj)
  end

  defp error?(nil) do
    false
  end

  defp error?(obj) do
    Obj.type(obj) == Object.types(:error_obj)
  end
end
