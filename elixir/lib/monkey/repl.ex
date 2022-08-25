defmodule Monkey.Repl do
  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Evaluator
  alias Monkey.Environment

  require Logger

  @prompt ">> "

  def start() do
    read(Environment.new())
  end

  defp read(env) do
    line = IO.gets(@prompt)

    parser =
      line
      |> Lexer.new()
      |> Parser.new()

    {_parser, program} = Parser.parse_program(parser)

    env =
      if length(parser.errors) > 0 do
        message = """
        Parsing errors:

        #{Enum.join(parser.errors, "\n")}
        """

        Logger.error(message)
        env
      else
        {evaluated, env} = Evaluator.run(program, env)

        if evaluated do
          IO.puts(Monkey.Object.Obj.inspect(evaluated))
        end

        env
      end

    read(env)
  end
end
