defmodule Monkey.Object do
  @type object_type :: String.t()

  @types %{
    integer_obj: "INTEGER",
    boolean_ojb: "BOOLEAN",
    null_obj: "NULL"
  }

  def types() do
    @types
  end

  def types(key) do
    @types[key]
  end

  defprotocol Obj do
    def type(object)
    def inspect(object)
  end

  defmodule Integer do
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:integer_obj)
      end

      def inspect(object) do
        Elixir.Integer.to_string(object.value)
      end
    end
  end

  defmodule Boolean do
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:boolean_obj)
      end

      def inspect(object) do
        Atom.to_string(object.value)
      end
    end
  end

  defmodule Null do
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:null_obj)
      end

      def inspect(_) do
        "null"
      end
    end
  end
end
