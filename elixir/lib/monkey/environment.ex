defmodule Monkey.Environment do
  defstruct [:outer, store: %{}]

  def new() do
    %__MODULE__{store: %{}}
  end

  def new_enclosed(%__MODULE__{} = env) do
    %__MODULE__{store: %{}, outer: env}
  end

  def get(%__MODULE__{store: store, outer: outer}, name) do
    case Map.fetch(store, name) do
      :error when outer != nil ->
        get(outer, name)

      result ->
        result
    end
  end

  def set(%__MODULE__{store: store} = env, name, value) do
    %{env | store: Map.put(store, name, value)}
  end
end
