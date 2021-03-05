defmodule KV.Registry do
  @moduledoc """
  Storing bucket pid inside ETS table which handle concurrent read better than current KV.Redistry GenServer
  """
  use GenServer
  ## Client API, do later

  @doc """
  Starts the registry with the given options.

  `:name` is always required.
  """
  def start_link(opts) do
    # 1. Pass the name to GenServer's init
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    # 2. Lookup is now done directly in ETS, without accessing the Server
    # lookup bucket pid via name
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end

    # GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## GenServer callbacks

  @doc """
  table: ETS server name receive from GenServer.start_link
  GenServer.start_link(__MODULE__, server, opts)
  table === server above
  """
  @impl true
  def init(table) do
    # contains name -> pid of bucket
    # names = %{}
    # 3. Now we replaced the names map by the ETS table
    names = :ets.new(table, [:named_table, read_concurrency: true])
    # contains ref -> name
    refs = %{}
    {:ok, {names, refs}}
  end

  # 4. The previous hand_call callback for lookup was removed
  # @impl true
  # def handle_call({:lookup, name}, _from, state) do
  #   {names, _} = state
  #   {:reply, Map.fetch(names, name), state}
  # end

  # for didactic purposes when using handle_cast, it should be handle_call
  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    # 5. Read and write to the ETS table instead of the map
    case lookup(names, name) do
      # when bucket pid already exist
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      :error ->
        # otherwise
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # get name of ref
    {name, refs} = Map.pop(refs, ref)
    # delete name inside registry
    # names = Map.delete(names, name)
    # 6. Delete from ETS table instead of the map
    :ets.delete(names, name)
    # return state
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
