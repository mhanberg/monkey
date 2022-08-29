defmodule Monkey.Object do
  @type object_type :: String.t()

  @types %{
    function_obj: "FUNCTION",
    integer_obj: "INTEGER",
    boolean_obj: "BOOLEAN",
    null_obj: "NULL",
    return_value_obj: "RETURN_VALUE",
    error_obj: "ERROR",
    string_obj: "STRING",
    array_obj: "ARRAY",
    builtin_obj: "BUILTIN",
    hash_obj: "HASH"
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
    def hash_key(object)
  end

  defprotocol Hashable do
    @fallback_to_any true
    def hash_key(object)
  end

  defimpl __MODULE__.Hashable, for: Any do
    def hash_key(_) do
      false
    end
  end

  defmodule HashKey do
    defstruct [:type, :key]
  end

  defmodule HashPair do
    defstruct [:key, :value]
  end

  defmodule Hash do
    defstruct [:pairs]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:hash_obj)
      end

      def inspect(object) do
        "{" <>
          Enum.map_join(object.pairs, ", ", fn {_k,
                                                %Monkey.Object.HashPair{key: key, value: value}} ->
            ~s|#{Monkey.Object.Obj.inspect(key)}: #{Monkey.Object.Obj.inspect(value)}|
          end) <> "}"
      end

      def hash_key(object) do
        %Monkey.Object.HashKey{type: Monkey.Object.Obj.type(object), key: object.value}
      end
    end
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

      def hash_key(object) do
        %Monkey.Object.HashKey{type: Monkey.Object.Obj.type(object), key: object.value}
      end
    end

    defimpl Hashable do
      def hash_key(_) do
        true
      end
    end
  end

  defmodule String do
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:string_obj)
      end

      def inspect(object) do
        ~s|"#{object.value}"|
      end

      def hash_key(object) do
        %Monkey.Object.HashKey{
          type: Monkey.Object.Obj.type(object),
          key: :crypto.hash(:sha256, object.value)
        }
      end
    end

    defimpl Hashable do
      def hash_key(_) do
        true
      end
    end
  end

  defmodule Array do
    defstruct [:elements]

    defimpl Obj do
      import Kernel, except: [inspect: 1]

      def type(_) do
        Monkey.Object.types(:array_obj)
      end

      def inspect(object) do
        "[" <> Enum.map_join(object.elements, ", ", &Obj.inspect/1) <> "]"
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
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

      def hash_key(object) do
        key = if object.value, do: 1, else: 0

        %Monkey.Object.HashKey{
          type: Monkey.Object.Obj.type(object),
          key: key
        }
      end
    end

    defimpl Hashable do
      def hash_key(_) do
        true
      end
    end
  end

  defmodule Null do
    import Kernel, except: [inspect: 1]
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:null_obj)
      end

      def inspect(_) do
        "null"
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
      end
    end
  end

  defmodule ReturnValue do
    import Kernel, except: [inspect: 1]
    defstruct [:value]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:return_value_obj)
      end

      def inspect(object) do
        Monkey.Object.Obj.inspect(object.value)
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
      end
    end
  end

  defmodule Function do
    import Kernel, except: [inspect: 1]
    defstruct [:body, parameters: %{}, env: Monkey.Environment.new()]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:function_obj)
      end

      def inspect(object) do
        parameters =
          Enum.join(
            for p <- object.parameters do
              Monkey.Ast.Node.string(p)
            end,
            ", "
          )

        "fn(#{parameters}) {\n#{Monkey.Ast.Node.string(object.body)}\n}"
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
      end
    end
  end

  defmodule BuiltinFunction do
    import Kernel, except: [inspect: 1]
    defstruct [:func]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:builtin_obj)
      end

      def inspect(_object) do
        "builtin function"
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
      end
    end
  end

  defmodule Error do
    import Kernel, except: [inspect: 1]
    defstruct [:message]

    defimpl Obj do
      def type(_) do
        Monkey.Object.types(:error_obj)
      end

      def inspect(object) do
        "ERROR: #{object.message}"
      end

      def hash_key(%module{}) do
        raise "#{inspect(__MODULE__)}.hash_key/1 not supported for #{Kernel.inspect(module)}"
      end
    end
  end
end
