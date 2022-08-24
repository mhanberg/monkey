defmodule Monkey.Ast do
  defprotocol Node do
    def token_literal(node)
    def string(node)
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

      def string(%Monkey.Ast.Program{statements: statements}) do
        for s <- statements, into: "" do
          Monkey.Ast.Node.string(s)
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

      def string(%Monkey.Ast.LetStatement{} = ls) do
        str = "#{Monkey.Ast.Node.token_literal(ls)} #{Monkey.Ast.Node.string(ls.name)} = "

        str =
          if ls.value != nil do
            str <> Monkey.Ast.Node.string(ls.value)
          else
            str
          end

        str <> ";"
      end
    end

    defimpl Monkey.Ast.Statement do
      def statement_node(_let_statement) do
        nil
      end
    end
  end

  defmodule ReturnStatement do
    defstruct [:token, :return_value]

    defimpl Monkey.Ast.Node do
      def token_literal(return_statement) do
        return_statement.token.literal
      end

      def string(%Monkey.Ast.ReturnStatement{} = rs) do
        str = "#{Monkey.Ast.Node.token_literal(rs)} "

        str =
          if rs.return_value != nil do
            str <> Monkey.Ast.Node.string(rs.return_value)
          else
            str
          end

        str <> ";"
      end
    end

    defimpl Monkey.Ast.Statement do
      def statement_node(_return_statement) do
        nil
      end
    end
  end

  defmodule ExpressionStatement do
    defstruct [:token, :expression]

    defimpl Monkey.Ast.Node do
      def token_literal(expression_statement) do
        expression_statement.token.literal
      end

      def string(%Monkey.Ast.ExpressionStatement{} = expression_statement) do
        if expression_statement.expression != nil do
          Monkey.Ast.Node.string(expression_statement.expression)
        else
          ""
        end
      end
    end

    defimpl Monkey.Ast.Statement do
      def statement_node(_expression_statement) do
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

      def string(identifier) do
        identifier.value
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule IntegerLiteral do
    defstruct [:token, :value]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        node.token.literal
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule PrefixExpression do
    defstruct [:token, :operator, :right]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        "(#{node.operator}#{Monkey.Ast.Node.string(node.right)})"
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule InfixExpression do
    defstruct [:token, :operator, :left, :right]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        "(#{Monkey.Ast.Node.string(node.left)} #{node.operator} #{Monkey.Ast.Node.string(node.right)})"
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule Boolean do
    defstruct [:token, :value]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        node.token.literal
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defimpl Monkey.Ast.Node, for: Atom do
    def token_literal(_node) do
      ""
    end

    def string(_node) do
      ""
    end
  end
end
