defmodule Monkey.Tracing do
  defmacro trace(step, do: block) do
    quote do
      indent_level = :persistent_term.get(:indent_level, 0)
      :persistent_term.put(:indent_level, indent_level + 1)

      if System.get_env("TRACE") == "true" do
        IO.puts(String.duplicate(" ", indent_level * 2) <> "BEGIN #{unquote(step)}")
      end

      ret = unquote(block)

      if System.get_env("TRACE") == "true" do
        IO.puts(String.duplicate(" ", indent_level * 2) <> "END #{unquote(step)}")
      end

      :persistent_term.put(:indent_level, indent_level)

      ret
    end
  end
end
