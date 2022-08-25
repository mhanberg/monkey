defmodule Monkey.Environment do
  defstruct store: %{}

  def new() do
    %__MODULE__{store: %{}}
  end

  def get(%__MODULE__{store: store}, name) do
    Map.fetch(store, name)
  end

  def set(%__MODULE__{store: store} = env, name, value) do
    %{env | store: Map.put(store, name, value)}
  end
end
