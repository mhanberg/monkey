defmodule Monkey.AstTest do
  use ExUnit.Case, async: true

  alias Monkey.Ast
  alias Monkey.Token

  test "string" do
    program = %Ast.Program{
      statements: [
        %Ast.LetStatement{
          token: %Token{type: Token.tokens(:let), literal: "let"},
          name: %Ast.Identifier{
            token: %Token{type: Token.tokens(:ident), literal: "myVar"},
            value: "myVar"
          },
          value: %Ast.Identifier{
            token: %Token{type: Token.tokens(:ident), literal: "anotherVar"},
            value: "anotherVar"
          }
        }
      ]
    }

    assert "let myVar = anotherVar;" == Ast.Node.string(program)
  end
end
