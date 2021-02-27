defmodule KV.Bucket do
  use Agent
  @doc """
    Starts a new bucket.
  """
  def start_link(_) do
    Agent.start_link fn -> %{} end
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(agent, key) do
    Agent.get(agent, &Map.get(&1, key))
  end

  @doc """
  Puts the value for the given `key` in the `bucket`
  """
  def put(agent, key , value) do
    Agent.update(agent, &Map.put(&1, key, value))
  end
end
