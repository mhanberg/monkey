defmodule Monkey.Repl do
  alias Monkey.Lexer
  alias Monkey.Token

  @prompt ">> "

  def start() do
    read()
  end

  defp read() do
    IO.puts("starting to read")
    line = IO.gets(@prompt)

    lexer = Lexer.new(line)

    Enum.reduce_while(stream_tokens(lexer), nil, fn token, _ ->
      if token.type == Token.tokens().eof do
        {:halt, nil}
      else
        IO.inspect(token)
        {:cont, nil}
      end
    end)

    read()
  end

  defp stream_tokens(lexer) do
    Stream.resource(
      fn ->
        lexer
      end,
      fn lexer ->
        {lexer, token} = Lexer.next_token(lexer)
        {[token], lexer}
      end,
      fn lexer -> lexer end
    )
  end
end
