defmodule Monkey.Repl do
  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Evaluator

  require Logger

  @prompt ">> "

  def start() do
    read()
  end

  defp read() do
    line = IO.gets(@prompt)

    parser =
      line
      |> Lexer.new()
      |> Parser.new()

    {_parser, program} = Parser.parse_program(parser)

    if length(parser.errors) > 0 do
      message = """
      Parsing errors:

      #{Enum.join(parser.errors, "\n")}
      """

      Logger.error(message)
    else
      evaluated = Evaluator.run(program)

      if evaluated do
        IO.puts(Monkey.Object.Object.inspect(evaluated))
      end
    end

    read()
  end
end
