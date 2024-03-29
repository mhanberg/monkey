defmodule Monkey.Builtins do
  alias Monkey.Object
  alias Monkey.Object.Obj

  def funcs(key) do
    %{
      "len" => %Object.BuiltinFunction{
        func: fn args -> ensure_arg_count(&len/1, args, 1) end
      },
      "puts" => %Object.BuiltinFunction{
        func: fn args -> puts(args) end
      }
    }[key]
  end

  defp ensure_arg_count(func, args, count) when length(args) == count do
    apply(func, args)
  end

  defp ensure_arg_count(_func, args, count) do
    %Object.Error{message: "wrong number of arguments. got=#{length(args)}, want=#{count}"}
  end

  defp len(%Object.String{value: string}) do
    %Object.Integer{value: String.length(string)}
  end

  defp len(%Object.Array{elements: elements}) do
    %Object.Integer{value: length(elements)}
  end

  defp len(other) do
    %Object.Error{message: "argument to `len` not supported, got #{Obj.type(other)}"}
  end

  defp puts(args) do
    for arg <- args do
      IO.puts(Obj.inspect(arg))
    end

    %Object.Null{}
  end
end
