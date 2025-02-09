defmodule Phoenix.React.Cache do
  @moduledoc """
  Cache for React Component rendering

  Cache key is a tuple of component, props and static flag

  Remove expired cache every 60 seconds
  """
  use GenServer

  @ets_table_name :react_component_cache

  @default_ttl Application.compile_env(:phoenix_react_server, Phoenix.React)
               |> Keyword.get(:cache_ttl, 3600)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, %{}}
  def init(_) do
    state = %{}
    ensure_started()
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:gc, state) do
    ts = :os.system_time(:seconds)
    fun = :ets.fun2ms(fn {key, _, expiration} when ts > expiration -> key end)

    :ets.lookup(@ets_table_name, fun)
    |> Enum.each(&:ets.delete(@ets_table_name, &1))

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # Every 60 seconds
    Process.send_after(self(), :gc, 60_000)
  end

  @doc """
  Get a cached value
  """
  def get(component, props, mod) do
    lookup(component, props, mod)
  end

  @doc """
  Set a cached value
  """
  def put(component, props, mod, result, opt \\ []) do
    ttl = Keyword.get(opt, :ttl, @default_ttl)
    expiration = :os.system_time(:seconds) + ttl
    record = {[component, props, mod], result, expiration}
    :ets.insert(@ets_table_name, record)
  end

  @doc """
  Remove cached value
  """
  def delete_cache(component, props, mod) do
    :ets.delete(@ets_table_name, [component, props, mod])
  end

  defp lookup(component, props, mod) do
    case :ets.lookup(@ets_table_name, [component, props, mod]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  defp check_freshness({[component, props, mod], result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) ->
        result

      :else ->
        delete_cache(component, props, mod)
        nil
    end
  end

  defp ensure_started() do
    case :ets.whereis(@ets_table_name) do
      :undefined -> :ets.new(@ets_table_name, [:set, :public, :named_table])
      ref -> ref
    end
  end
end
