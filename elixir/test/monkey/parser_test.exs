defmodule Monkey.ParserTest do
  use ExUnit.Case, async: true

  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Ast

  test "let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    lexer = Lexer.new(input)

    parser = Parser.new(lexer)

    {parser, program} = Parser.parse_program(parser)

    assert_parse_errors(parser)

    assert program
    assert 3 == length(program.statements)

    tests = [
      {"x"},
      {"y"},
      {"foobar"}
    ]

    for {{expected_identifier}, idx} <- Enum.with_index(tests) do
      statement = Enum.at(program.statements, idx)

      assert Ast.Node.token_literal(statement) == "let"
      assert %Ast.LetStatement{} = statement
      assert statement.name.value == expected_identifier
      assert Ast.Node.token_literal(statement.name) == expected_identifier
    end
  end

  test "return statements" do
    input = """
    return 5;
    return 10;
    return 993322;
    """

    lexer = Lexer.new(input)

    parser = Parser.new(lexer)

    {parser, program} = Parser.parse_program(parser)

    assert_parse_errors(parser)

    assert program
    assert 3 == length(program.statements)

    for statement <- program.statements do
      assert %Ast.ReturnStatement{} = statement
      assert "return" == Ast.Node.token_literal(statement)
    end
  end

  defp assert_parse_errors(parser) do
    assert length(parser.errors) == 0, Enum.join(parser.errors, "\n")
  end
end
