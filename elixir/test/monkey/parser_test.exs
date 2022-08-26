defmodule Monkey.ParserTest do
  use ExUnit.Case, async: true

  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Ast

  import Monkey.Support.Utils

  setup :lex_and_parse

  test "let statements" do
    tests = [
      {~M"let x = 5;", "x", 5},
      {~M"let y = true;", "y", true},
      {~M"let foobar = y;", "foobar", "y"}
    ]

    for {input, expected_identifier, expected_value} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      %Ast.Program{statements: statements} = context[:program]

      assert_parse_errors(parser)

      assert [statement] = statements

      assert %Ast.LetStatement{
               name: %Ast.Identifier{value: ^expected_identifier},
               value: value
             } = statement

      assert expected_value == value.value
    end
  end

  test "return statements" do
    tests = [
      {~M"return 5;", 5},
      {~M"return true;", true},
      {~M"return foobar;", "foobar"}
    ]

    for {input, expected_value} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      %Ast.Program{statements: statements} = context[:program]

      assert_parse_errors(parser)

      assert [statement] = statements

      assert %Ast.ReturnStatement{
               return_value: return_value
             } = statement

      assert return_value.value == expected_value

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
      {~M"!5;", "!", 5},
      {~M"-15;", "-", 15}
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
      {~M"5 + 5;", 5, "+", 5, Ast.IntegerLiteral},
      {~M"5 - 5;", 5, "-", 5, Ast.IntegerLiteral},
      {~M"5 * 5;", 5, "*", 5, Ast.IntegerLiteral},
      {~M"5 / 5;", 5, "/", 5, Ast.IntegerLiteral},
      {~M"5 > 5;", 5, ">", 5, Ast.IntegerLiteral},
      {~M"5 < 5;", 5, "<", 5, Ast.IntegerLiteral},
      {~M"5 == 5;", 5, "==", 5, Ast.IntegerLiteral},
      {~M"5 != 5;", 5, "!=", 5, Ast.IntegerLiteral},
      {~M"true == true", true, "==", true, Ast.Boolean},
      {~M"true != false", true, "!=", false, Ast.Boolean},
      {~M"false == false", false, "==", false, Ast.Boolean}
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
      {~M"-a * b", ~M"((-a) * b)"},
      {~M"!-a", ~M"(!(-a))"},
      {~M"a + b + c", ~M"((a + b) + c)"},
      {~M"a + b - c", ~M"((a + b) - c)"},
      {~M"a * b * c", ~M"((a * b) * c)"},
      {~M"a * b / c", ~M"((a * b) / c)"},
      {~M"a + b / c", ~M"(a + (b / c))"},
      {~M"a + b * c + d / e - f", ~M"(((a + (b * c)) + (d / e)) - f)"},
      {~M"3 + 4; -5 * 5", ~M"(3 + 4)((-5) * 5)"},
      {~M"5 > 4 == 3 < 4", ~M"((5 > 4) == (3 < 4))"},
      {~M"5 < 4 != 3 > 4", ~M"((5 < 4) != (3 > 4))"},
      {~M"3 + 4 * 5 == 3 * 1 + 4 * 5", ~M"((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
      {~M"true", ~M"true"},
      {~M"false", ~M"false"},
      {~M"3 > 5 == false", ~M"((3 > 5) == false)"},
      {~M"3 < 5 == true", ~M"((3 < 5) == true)"},
      {~M"1 + (2 + 3) + 4", ~M"((1 + (2 + 3)) + 4)"},
      {~M"(5 + 5) * 2", ~M"((5 + 5) * 2)"},
      {~M"2 / (5 + 5)", ~M"(2 / (5 + 5))"},
      {~M"(5 + 5) * 2 * (5 + 5)", ~M"(((5 + 5) * 2) * (5 + 5))"},
      {~M"-(5 + 5)", ~M"(-(5 + 5))"},
      {~M"a + add(b * c) + d", ~M"((a + add((b * c))) + d)"},
      {~M"add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
       ~M"add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"},
      {~M"add(a + b + c * d / f + g)", ~M"add((((a + b) + ((c * d) / f)) + g))"},
      {~M"a * [1, 2, 3, 4][b * c] * d", ~M"((a * ([1, 2, 3, 4][(b * c)])) * d)"},
      {
        ~M"add(a * b[2], b[1], 2 * [1, 2][1])",
        ~M"add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
      }
    ]

    for {input, expected} <- tests do
      context = lex_and_parse(%{input: input})
      parser = context[:parser]
      program = context[:program]

      assert_parse_errors(parser)

      assert expected == Ast.Node.string(program)
    end
  end

  @tag input: ~M"if (x < y) { x }"
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

  @tag input: ~M"if (x < y) { x } else { y }"
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

  @tag input: ~M"fn(x, y) { x + y; }"
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
      {~M"fn() {};", []},
      {~M"fn(x) {};", ["x"]},
      {~M"fn(x, y, z) {};", ["x", "y", "z"]}
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

  @tag input: ~M"add(1, 2 * 3, 4 + 5);"
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

  @tag input: ~M|"hello world";|
  test "string literals", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.StringLiteral{
                 value: "hello world"
               }
             }
           ] = program.statements
  end

  @tag input: ~M|[hello, "world"];|
  test "array literals", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.ArrayLiteral{
                 values: [
                   %Ast.Identifier{value: "hello"},
                   %Ast.StringLiteral{value: "world"}
                 ]
               }
             }
           ] = program.statements
  end

  @tag input: ~M|myArray[1 + 1];|
  test "index expressions", %{parser: parser, program: program} do
    assert_parse_errors(parser)

    assert 1 == length(program.statements)

    assert [
             %Ast.ExpressionStatement{
               expression: %Ast.IndexExpression{
                 left: %Ast.Identifier{value: "myArray"},
                 index: %Ast.InfixExpression{
                   operator: "+",
                   left: %Ast.IntegerLiteral{value: 1},
                   right: %Ast.IntegerLiteral{value: 1}
                 }
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
