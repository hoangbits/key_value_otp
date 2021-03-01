defmodule KV do
  @moduledoc """
  Documentation for `KV`.
  """
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    # using same name for is useful for debugging
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
