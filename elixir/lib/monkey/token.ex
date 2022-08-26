defmodule Monkey.Token do
  defstruct [:type, :literal]

  @type token_type :: String.t()

  @type t :: %__MODULE__{
          type: token_type(),
          literal: String.t()
        }

  @tokens %{
    illegal: "ILLEGAL",
    eof: "EOF",

    # identifiers
    ident: "IDENT",
    int: "INT",

    # operators
    assign: "=",
    plus: "+",
    minus: "-",
    bang: "!",
    asterisk: "*",
    slash: "/",
    lt: "<",
    gt: ">",
    eq: "==",
    not_eq: "!=",

    # delimiters
    comma: ",",
    semicolon: ";",
    lparen: "(",
    rparen: ")",
    lbrace: "{",
    rbrace: "}",

    # keywords
    function: "FUNCTION",
    let: "LET",
    true: "TRUE",
    false: "FALSE",
    if: "IF",
    else: "ELSE",
    return: "RETURN",
    string: "STRING"
  }

  @keywords %{
    "fn" => @tokens.function,
    "let" => @tokens.let,
    "true" => @tokens.true,
    "false" => @tokens.false,
    "if" => @tokens.if,
    "else" => @tokens.else,
    "return" => @tokens.return
  }

  def new(token_type, char \\ nil) do
    %__MODULE__{
      type: token_type,
      literal: char
    }
  end

  def tokens() do
    @tokens
  end

  def tokens(key) do
    @tokens[key]
  end

  def lookup_identifier(identifier) do
    Map.get(@keywords, identifier, @tokens.ident)
  end
end
