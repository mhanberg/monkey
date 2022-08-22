defmodule MonkeyTest do
  use ExUnit.Case
  doctest Monkey

  test "greets the world" do
    assert Monkey.hello() == :world
  end
end
