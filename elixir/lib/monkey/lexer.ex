defmodule Monkey.Lexer do
  alias Monkey.Token

  @tokens Token.tokens()
  defstruct [:input, :position, :char, read_position: 0]

  @type t :: %__MODULE__{
          input: String.t(),
          position: non_neg_integer(),
          read_position: non_neg_integer(),
          char: String.t()
        }

  @spec new(String.t()) :: t()
  def new(input) do
    %__MODULE__{input: input}
    |> read_char()
  end

  defmacrop lowercase_letters() do
    list =
      ?a..?z
      |> Enum.to_list()
      |> Enum.map(fn x -> to_string([x]) end)

    quote do
      unquote(list)
    end
  end

  defmacrop uppercase_letters() do
    list =
      ?A..?Z
      |> Enum.to_list()
      |> Enum.map(fn x -> to_string([x]) end)

    quote do
      unquote(list)
    end
  end

  defguardp is_letter(char)
            when char in lowercase_letters() or char in uppercase_letters() or char == "_"

  defguardp is_digit(char) when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  @spec next_token(t()) :: {t(), Token.t()}
  def next_token(%__MODULE__{} = lexer) do
    lexer = skip_whitespace(lexer)

    case lexer.char do
      "=" ->
        if peek_char(lexer) == "=" do
          char = lexer.char
          lexer = read_char(lexer)
          literal = char <> lexer.char
          {lexer, Token.new(@tokens.eq, literal), :read_next}
        else
          Token.new(@tokens.assign, lexer.char)
        end

      "+" ->
        Token.new(@tokens.plus, lexer.char)

      "-" ->
        Token.new(@tokens.minus, lexer.char)

      "!" ->
        if peek_char(lexer) == "=" do
          char = lexer.char
          lexer = read_char(lexer)
          literal = char <> lexer.char
          {lexer, Token.new(@tokens.not_eq, literal), :read_next}
        else
          Token.new(@tokens.bang, lexer.char)
        end

      "/" ->
        Token.new(@tokens.slash, lexer.char)

      "*" ->
        Token.new(@tokens.asterisk, lexer.char)

      "<" ->
        Token.new(@tokens.lt, lexer.char)

      ">" ->
        Token.new(@tokens.gt, lexer.char)

      ";" ->
        Token.new(@tokens.semicolon, lexer.char)

      "," ->
        Token.new(@tokens.comma, lexer.char)

      "(" ->
        Token.new(@tokens.lparen, lexer.char)

      ")" ->
        Token.new(@tokens.rparen, lexer.char)

      "{" ->
        Token.new(@tokens.lbrace, lexer.char)

      "}" ->
        Token.new(@tokens.rbrace, lexer.char)

      ~s|"| ->
        {lexer, literal} = read_string(lexer)
        {lexer, Token.new(@tokens.string, literal), :read_next}

      0 ->
        Token.new(@tokens.eof, "")

      _ ->
        cond do
          is_letter(lexer.char) ->
            {lexer, identifier} = read_identifier(lexer)
            type = Token.lookup_identifier(identifier)
            {lexer, Token.new(type, identifier)}

          is_digit(lexer.char) ->
            {lexer, number} = read_number(lexer)
            {lexer, Token.new(@tokens.int, number)}

          true ->
            Token.new(@tokens.illegal, lexer.char)
        end
    end
    |> then(fn
      {%__MODULE__{} = lexer, %Token{} = token, :read_next} ->
        lexer = read_char(lexer)

        {lexer, token}

      {%__MODULE__{} = lexer, %Token{} = token} ->
        {lexer, token}

      %Token{} = token ->
        lexer = read_char(lexer)

        {lexer, token}
    end)
  end

  defp skip_whitespace(%__MODULE__{char: char} = lexer) when char in [" ", "\t", "\n", "\r"] do
    lexer
    |> read_char()
    |> skip_whitespace()
  end

  defp skip_whitespace(lexer), do: lexer

  defp read_char(%__MODULE__{} = lexer) do
    char =
      if lexer.read_position >= String.length(lexer.input) do
        0
      else
        lexer.input |> String.at(lexer.read_position)
      end

    %{
      lexer
      | char: char,
        position: lexer.read_position,
        read_position: lexer.read_position + 1
    }
  end

  defp peek_char(%__MODULE__{} = lexer) do
    if lexer.read_position >= String.length(lexer.input) do
      0
    else
      String.at(lexer.input, lexer.read_position)
    end
  end

  defp read_identifier(%__MODULE__{} = lexer) do
    position = lexer.position

    lexer = read_letters(lexer)

    {lexer, String.slice(lexer.input, position..(lexer.position - 1))}
  end

  def read_string(%__MODULE__{} = lexer) do
    position = lexer.position + 1

    lexer = eat_until_quote_or_eof(lexer)

    {lexer, String.slice(lexer.input, position..(lexer.position - 1))}
  end

  defp eat_until_quote_or_eof(%__MODULE__{} = lexer) do
    lexer = read_char(lexer)

    if lexer.char == ~s|"| || lexer.char == 0 do
      lexer
    else
      eat_until_quote_or_eof(lexer)
    end
  end

  defp read_letters(%__MODULE__{char: char} = lexer) when is_letter(char) do
    lexer
    |> read_char()
    |> read_letters()
  end

  defp read_letters(lexer), do: lexer

  defp read_number(%__MODULE__{} = lexer) do
    position = lexer.position

    lexer = read_digits(lexer)

    {lexer, String.slice(lexer.input, position..(lexer.position - 1))}
  end

  defp read_digits(%__MODULE__{char: char} = lexer) when is_digit(char) do
    lexer
    |> read_char()
    |> read_digits()
  end

  defp read_digits(lexer), do: lexer
end
