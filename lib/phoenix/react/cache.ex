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

    match_spec = [
      {{:"$1", :_, :"$2"}, [{:<, :"$2", ts}], [:"$1"]}
    ]

    :ets.select(@ets_table_name, match_spec)
    |> Enum.each(fn key -> :ets.delete(@ets_table_name, key) end)

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # Every 60 seconds by default
    gc_time =
      Application.get_env(:phoenix_react_server, Phoenix.React)
      |> Keyword.get(:gc_time, 60_000)

    Process.send_after(self(), :gc, gc_time)
  end

  @doc """
  Get a cached value
  """
  @spec get(Phoenix.React.component(), Phoenix.React.props(), :static_markup | :string) ::
          binary() | nil
  def get(component, props, mod) do
    lookup(component, props, mod)
  end

  @doc """
  Set a cached value
  """
  @spec put(Phoenix.React.component(), Phoenix.React.props(), :static_markup | :string, binary(),
          ttl: integer()
        ) :: true
  def put(component, props, mod, result, opt \\ []) do
    ttl = Keyword.get(opt, :ttl, @default_ttl)
    expiration = :os.system_time(:seconds) + ttl
    record = {[component, props, mod], result, expiration}
    :ets.insert(@ets_table_name, record)
  end

  @doc """
  Remove cached value
  """
  @spec delete_cache(Phoenix.React.component(), Phoenix.React.props(), :static_markup | :string) ::
          true
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
