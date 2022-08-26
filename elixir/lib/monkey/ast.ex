defmodule Monkey.Ast do
  import Monkey.Tracing

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
        trace "string/1 Program" do
          for s <- statements, into: "" do
            Monkey.Ast.Node.string(s)
          end
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
        trace "string/1 LetStatement" do
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
        trace "string/1 ReturnStatement" do
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
        trace "string/1 ExpressionStatement" do
          if expression_statement.expression != nil do
            Monkey.Ast.Node.string(expression_statement.expression)
          else
            ""
          end
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
        trace "string/1 Identifier" do
          identifier.value
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule ArrayLiteral do
    defstruct [:token, :values]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 IntegerLiteral" do
          "[" <> Enum.map_join(node.values, ", ", &Monkey.Ast.Node.string/1) <> "]"
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule IndexExpression do
    defstruct [:token, :left, :index]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 IndexExpression" do
          "(" <>
            Monkey.Ast.Node.string(node.left) <>
            "[" <>
            Monkey.Ast.Node.string(node.index) <>
            "])"
        end
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
        trace "string/1 IntegerLiteral" do
          node.token.literal
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule StringLiteral do
    defstruct [:token, :value]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 StringLiteral" do
          node.token.literal
        end
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
        trace "string/1 PrefixExpression" do
          "(#{node.operator}#{Monkey.Ast.Node.string(node.right)})"
        end
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
        trace "string/1 InfixExpression" do
          "(#{Monkey.Ast.Node.string(node.left)} #{node.operator} #{Monkey.Ast.Node.string(node.right)})"
        end
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
        trace "string/1 Boolean" do
          node.token.literal
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule IfExpression do
    defstruct [:token, :condition, :consequence, :alternative]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 IfExpression" do
          string =
            "if#{Monkey.Ast.Node.string(node.condition)} #{Monkey.Ast.Node.string(node.consequence)}"

          if node.alternative do
            string <> "else #{Monkey.Ast.Node.string(node.alternative)}"
          else
            string
          end
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule BlockStatement do
    defstruct [:token, :statements]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 BlockStatement" do
          for s <- node.statements, into: "" do
            Monkey.Ast.Node.string(s)
          end
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule FunctionLiteral do
    defstruct [:token, :parameters, :body]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 FunctionLiteral" do
          parameters =
            Enum.join(
              for p <- node.parameters do
                Monkey.Ast.Node.string(p)
              end,
              ", "
            )

          "#{node.token.literal}(#{parameters}) { #{Monkey.Ast.Node.string(node.body)} }"
        end
      end
    end

    defimpl Monkey.Ast.Expression do
      def expression_node(_expression) do
        nil
      end
    end
  end

  defmodule CallExpression do
    defstruct [:token, :function, arguments: []]

    defimpl Monkey.Ast.Node do
      def token_literal(node) do
        node.token.literal
      end

      def string(node) do
        trace "string/1 CallExpression" do
          arguments =
            Enum.join(
              for p <- node.arguments do
                Monkey.Ast.Node.string(p)
              end,
              ", "
            )

          "#{Monkey.Ast.Node.string(node.function)}(#{arguments})"
        end
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
      trace "string/1 Atom" do
        ""
      end
    end
  end
end
