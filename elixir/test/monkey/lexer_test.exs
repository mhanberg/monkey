defmodule Monkey.LexerTest do
  use ExUnit.Case, async: true

  alias Monkey.Lexer
  alias Monkey.Token

  import Monkey.Support.Utils

  @tokens Token.tokens()

  describe "next_token" do
    test "random tokens" do
      input = ~M"=+(){},;"

      tests = [
        {@tokens.assign, "="},
        {@tokens.plus, "+"},
        {@tokens.lparen, "("},
        {@tokens.rparen, ")"},
        {@tokens.lbrace, "{"},
        {@tokens.rbrace, "}"},
        {@tokens.comma, ","},
        {@tokens.semicolon, ";"},
        {@tokens.eof, ""}
      ]

      lexer = Lexer.new(input)

      for {expected_type, expected_literal} <- tests, reduce: lexer do
        lexer ->
          {lexer, %Token{} = token} = Lexer.next_token(lexer)

          assert token.type == expected_type
          assert token.literal == expected_literal

          lexer
      end
    end

    test "monkey source code" do
      input = ~M"""
      let five = 5;
      let ten = 10;

      let add = fn(x, y) {
        x + y;
      };

      let result = add(five, ten);
      !-/*5;
      5 < 10 > 5;

      if (5 < 10) {
        return true;
      } else {
        return false;
      }

      10 == 10;
      10 != 9;

      "foobar"
      "foo bar"


      "and then i go to the zoo and take a picture of the lion's tail"
      ""
      [1, 2];
      """

      tests = [
        {@tokens.let, "let"},
        {@tokens.ident, "five"},
        {@tokens.assign, "="},
        {@tokens.int, "5"},
        {@tokens.semicolon, ";"},
        {@tokens.let, "let"},
        {@tokens.ident, "ten"},
        {@tokens.assign, "="},
        {@tokens.int, "10"},
        {@tokens.semicolon, ";"},
        {@tokens.let, "let"},
        {@tokens.ident, "add"},
        {@tokens.assign, "="},
        {@tokens.function, "fn"},
        {@tokens.lparen, "("},
        {@tokens.ident, "x"},
        {@tokens.comma, ","},
        {@tokens.ident, "y"},
        {@tokens.rparen, ")"},
        {@tokens.lbrace, "{"},
        {@tokens.ident, "x"},
        {@tokens.plus, "+"},
        {@tokens.ident, "y"},
        {@tokens.semicolon, ";"},
        {@tokens.rbrace, "}"},
        {@tokens.semicolon, ";"},
        {@tokens.let, "let"},
        {@tokens.ident, "result"},
        {@tokens.assign, "="},
        {@tokens.ident, "add"},
        {@tokens.lparen, "("},
        {@tokens.ident, "five"},
        {@tokens.comma, ","},
        {@tokens.ident, "ten"},
        {@tokens.rparen, ")"},
        {@tokens.semicolon, ";"},
        {@tokens.bang, "!"},
        {@tokens.minus, "-"},
        {@tokens.slash, "/"},
        {@tokens.asterisk, "*"},
        {@tokens.int, "5"},
        {@tokens.semicolon, ";"},
        {@tokens.int, "5"},
        {@tokens.lt, "<"},
        {@tokens.int, "10"},
        {@tokens.gt, ">"},
        {@tokens.int, "5"},
        {@tokens.semicolon, ";"},
        {@tokens.if, "if"},
        {@tokens.lparen, "("},
        {@tokens.int, "5"},
        {@tokens.lt, "<"},
        {@tokens.int, "10"},
        {@tokens.rparen, ")"},
        {@tokens.lbrace, "{"},
        {@tokens.return, "return"},
        {@tokens.true, "true"},
        {@tokens.semicolon, ";"},
        {@tokens.rbrace, "}"},
        {@tokens.else, "else"},
        {@tokens.lbrace, "{"},
        {@tokens.return, "return"},
        {@tokens.false, "false"},
        {@tokens.semicolon, ";"},
        {@tokens.rbrace, "}"},
        {@tokens.int, "10"},
        {@tokens.eq, "=="},
        {@tokens.int, "10"},
        {@tokens.semicolon, ";"},
        {@tokens.int, "10"},
        {@tokens.not_eq, "!="},
        {@tokens.int, "9"},
        {@tokens.semicolon, ";"},
        {@tokens.string, "foobar"},
        {@tokens.string, "foo bar"},
        {@tokens.string, "and then i go to the zoo and take a picture of the lion's tail"},
        {@tokens.string, ""},
        {@tokens.lbracket, "["},
        {@tokens.int, "1"},
        {@tokens.comma, ","},
        {@tokens.int, "2"},
        {@tokens.rbracket, "]"},
        {@tokens.semicolon, ";"},
        {@tokens.eof, ""}
      ]

      lexer = Lexer.new(input)

      for {expected_type, expected_literal} <- tests, reduce: lexer do
        lexer ->
          {lexer, %Token{} = token} = Lexer.next_token(lexer)

          assert token.type == expected_type
          assert token.literal == expected_literal

          lexer
      end
    end
  end
end
