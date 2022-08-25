defmodule Mix.Tasks.Monkey.Run do
  alias Monkey.Lexer
  alias Monkey.Parser
  alias Monkey.Evaluator
  alias Monkey.Environment

  require Logger

  def run([file]) do
    unless File.exists?(file) do
      raise "File not found: #{Path.absname(file)}"
    end

    input = File.read!(file)
    env = Environment.new()

    parser =
      input
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
      {evaluated, _env} = Evaluator.run(program, env)

      if evaluated do
        IO.puts(Monkey.Object.Obj.inspect(evaluated))
      end
    end
  end
end
