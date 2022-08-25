defmodule Monkey.Object do
  @type object_type :: String.t()

  @types %{
    integer_obj: "INTEGER",
    boolean_obj: "BOOLEAN",
    null_obj: "NULL",
    return_value_obj: "RETURN_VALUE",
    error_obj: "ERROR"
  }

  def types() do
    @types
  end

  def types(key) do
    Map.fetch!(@types, key)
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

  defmodule ReturnValue do
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:return_value_obj)
      end

      def inspect(object) do
        Monkey.Object.Obj.inspect(object.value)
      end
    end
  end

  defmodule Error do
    defstruct [:message]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:error_obj)
      end

      def inspect(object) do
        "ERROR: #{object.message}"
      end
    end
  end
end
