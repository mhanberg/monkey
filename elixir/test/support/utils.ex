defmodule Monkey.Support.Utils do
  defmacro sigil_M(string, _) do
    quote do
      unquote(string)
    end
  end
end
