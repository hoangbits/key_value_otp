defmodule KV.Bucket do
  def start_link(_content) do
    Agent.start_link fn -> %{} end
  end

  def get(agent, key) do
    Agent.get(agent, fn map -> Map.get(map, key) end)
  end

  def put(agent, key , value) do
    Agent.update(agent, fn map -> Map.put(map, key, value) end)
  end
end
