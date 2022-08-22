defmodule Monkey.Ast do
  defprotocol Node do
    def token_literal(node)
  end

  defprotocol Statement do
    def statement_node(statement)
  end

  defprotocol Expression do
    def expression_node(expression)
  end

  defmodule Program do
    defstruct statements: []

    defimpl Monkey.Ast.Node do
      def token_literal(%Monkey.Ast.Program{statements: statements}) do
        if length(statements) > 0 do
          statements
          |> List.first()
          |> Node.token_literal()
        else
          ""
        end
      end
    end
  end

  defmodule LetStatement do
    defstruct [:token, :name, :value]

    defimpl Monkey.Ast.Node do
      def token_literal(let_statement) do
        let_statement.token.literal
      end
    end

    defimpl Monkey.Ast.Statement do
      def statement_node(_let_statement) do
        nil
      end
    end
  end

  defmodule Identifier do
    defstruct [:token, :value]

    defimpl Monkey.Ast.Node do
      def token_literal(identifier) do
        identifier.token.literal
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_let_statement) do
        nil
      end
    end
  end
end
