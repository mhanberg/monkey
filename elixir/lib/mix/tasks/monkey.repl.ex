defmodule Mix.Tasks.Monkey.Repl do
  @moduledoc "Starts the Monkey REPL"
  @shortdoc "Starts the Monkey REPL"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    {username, 0} = System.cmd("whoami", [])
    Mix.shell().info("Hello #{String.trim(username)}! This is the Monkey programming language!")
    Monkey.Repl.start()
  end
end
