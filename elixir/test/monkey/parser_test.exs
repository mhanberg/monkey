defmodule Monkey.ParserTest do
  use ExUnit.Case, async: true

  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Ast

  setup :lex_and_parse

  @tag input: """
       let x = 5;
       let y = 10;
       let foobar = 838383;
       """
  test "let statements", %{parser: parser, program: program} do
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

  @tag input: """
       return 5;
       return 10;
       return 993322;
       """
  test "return statements", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert program
    assert 3 == length(program.statements)

    for statement <- program.statements do
      assert %Ast.ReturnStatement{} = statement
      assert "return" == Ast.Node.token_literal(statement)
    end
  end

  @tag input: "foobar;"
  test "identifier expression", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{expression: %Ast.Identifier{value: "foobar"} = identifier}
           ] = program.statements

    assert "foobar" == Ast.Node.token_literal(identifier)
  end

  @tag input: "5;"
  test "integer literal expression", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{expression: %Ast.IntegerLiteral{value: 5} = identifier}
           ] = program.statements

    assert "5" == Ast.Node.token_literal(identifier)
  end

  test "prefix expression" do
    tests = [
      {"!5;", "!", 5},
      {"-15;", "-", 15}
    ]

    for {input, operator, value} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      program = context[:program]

      assert_parse_errors(parser)

      assert 1 == length(program.statements)

      assert [
               %Ast.ExpressionStatement{
                 expression: %Ast.PrefixExpression{
                   operator: ^operator,
                   right: %Ast.IntegerLiteral{value: ^value} = right
                 }
               }
             ] = program.statements

      assert to_string(value) == Ast.Node.token_literal(right)
    end
  end

  test "infix expression" do
    tests = [
      {"5 + 5;", 5, "+", 5, Ast.IntegerLiteral},
      {"5 - 5;", 5, "-", 5, Ast.IntegerLiteral},
      {"5 * 5;", 5, "*", 5, Ast.IntegerLiteral},
      {"5 / 5;", 5, "/", 5, Ast.IntegerLiteral},
      {"5 > 5;", 5, ">", 5, Ast.IntegerLiteral},
      {"5 < 5;", 5, "<", 5, Ast.IntegerLiteral},
      {"5 == 5;", 5, "==", 5, Ast.IntegerLiteral},
      {"5 != 5;", 5, "!=", 5, Ast.IntegerLiteral},
      {"true == true", true, "==", true, Ast.Boolean},
      {"true != false", true, "!=", false, Ast.Boolean},
      {"false == false", false, "==", false, Ast.Boolean}
    ]

    for {input, left_value, operator, right_value, struct} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      program = context[:program]

      assert_parse_errors(parser)

      assert 1 == length(program.statements)

      assert [
               %Ast.ExpressionStatement{
                 expression: %Ast.InfixExpression{
                   operator: ^operator,
                   left: %^struct{value: ^left_value} = left,
                   right: %^struct{value: ^right_value} = right
                 }
               }
             ] = program.statements

      assert to_string(left_value) == Ast.Node.token_literal(left)
      assert to_string(right_value) == Ast.Node.token_literal(right)
    end
  end

  test "operator precedence parsing" do
    tests = [
      {"-a * b", "((-a) * b)"},
      {"!-a", "(!(-a))"},
      {"a + b + c", "((a + b) + c)"},
      {"a + b - c", "((a + b) - c)"},
      {"a * b * c", "((a * b) * c)"},
      {"a * b / c", "((a * b) / c)"},
      {"a + b / c", "(a + (b / c))"},
      {"a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"},
      {"3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"},
      {"5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"},
      {"5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"},
      {"3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
      {"true", "true"},
      {"false", "false"},
      {"3 > 5 == false", "((3 > 5) == false)"},
      {"3 < 5 == true", "((3 < 5) == true)"},
      {"1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"},
      {"(5 + 5) * 2", "((5 + 5) * 2)"},
      {"2 / (5 + 5)", "(2 / (5 + 5))"},
      {"(5 + 5) * 2 * (5 + 5)", "(((5 + 5) * 2) * (5 + 5))"},
      {"-(5 + 5)", "(-(5 + 5))"},
      {"a + add(b * c) + d", "((a + add((b * c))) + d)"},
      {"add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
       "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"},
      {"add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"}
    ]

    for {input, expected} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      program = context[:program]

      assert_parse_errors(parser)

      assert expected == Ast.Node.string(program)
    end
  end

  @tag input: "if (x < y) { x }"
  test "if experssion", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.IfExpression{
                 condition: %Ast.InfixExpression{
                   operator: "<",
                   left: %Ast.Identifier{value: "x"},
                   right: %Ast.Identifier{value: "y"}
                 },
                 consequence: %Ast.BlockStatement{
                   statements: [
                     %Ast.ExpressionStatement{
                       expression: %Ast.Identifier{
                         value: "x"
                       }
                     }
                   ]
                 },
                 alternative: nil
               }
             }
           ] = program.statements
  end

  @tag input: "if (x < y) { x } else { y }"
  test "if else experssion", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.IfExpression{
                 condition: %Ast.InfixExpression{
                   operator: "<",
                   left: %Ast.Identifier{value: "x"},
                   right: %Ast.Identifier{value: "y"}
                 },
                 consequence: %Ast.BlockStatement{
                   statements: [
                     %Ast.ExpressionStatement{
                       expression: %Ast.Identifier{
                         value: "x"
                       }
                     }
                   ]
                 },
                 alternative: %Ast.BlockStatement{
                   statements: [
                     %Ast.ExpressionStatement{
                       expression: %Ast.Identifier{
                         value: "y"
                       }
                     }
                   ]
                 }
               }
             }
           ] = program.statements
  end

  @tag input: "fn(x, y) { x + y; }"
  test "function literal", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.FunctionLiteral{
                 parameters: [
                   %Ast.Identifier{value: "x"},
                   %Ast.Identifier{value: "y"}
                 ],
                 body: %Ast.BlockStatement{
                   statements: [
                     %Ast.ExpressionStatement{
                       expression: %Ast.InfixExpression{
                         left: %Ast.Identifier{value: "x"},
                         operator: "+",
                         right: %Ast.Identifier{value: "y"}
                       }
                     }
                   ]
                 }
               }
             }
           ] = program.statements
  end

  test "function parameter parsing" do
    tests = [
      {"fn() {};", []},
      {"fn(x) {};", ["x"]},
      {"fn(x, y, z) {};", ["x", "y", "z"]}
    ]

    for {input, expected} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      program = context[:program]

      assert_parse_errors(parser)

      assert [
               %Ast.ExpressionStatement{
                 expression: %Ast.FunctionLiteral{
                   parameters: parameters
                 }
               }
             ] = program.statements

      assert length(expected) == length(parameters)

      for {e, p} <- Enum.zip(expected, parameters) do
        assert e == p.token.literal
      end
    end
  end

  @tag input: "add(1, 2 * 3, 4 + 5);"
  test "parsing call experssions", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.CallExpression{
                 function: %Ast.Identifier{value: "add"},
                 arguments: [
                   %Ast.IntegerLiteral{value: 1},
                   %Ast.InfixExpression{
                     left: %Ast.IntegerLiteral{value: 2},
                     operator: "*",
                     right: %Ast.IntegerLiteral{value: 3}
                   },
                   %Ast.InfixExpression{
                     left: %Ast.IntegerLiteral{value: 4},
                     operator: "+",
                     right: %Ast.IntegerLiteral{value: 5}
                   }
                 ]
               }
             }
           ] = program.statements
  end

  defp assert_parse_errors(parser) do
    assert length(parser.errors) == 0, Enum.join(parser.errors, "\n")
  end

  def lex_and_parse(%{input: input}) do
    assert %Lexer{} = lexer = Lexer.new(input)
    assert %Parser{} = parser = Parser.new(lexer)
    assert {%Parser{} = parser, %Ast.Program{} = program} = Parser.parse_program(parser)

    [lexer: lexer, parser: parser, program: program]
  end

  def lex_and_parse(context) do
    context
  end
end
