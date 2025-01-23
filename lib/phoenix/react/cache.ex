defmodule Phoenix.React.Cache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """
  use GenServer

  @ets_table_name :react_component_cache

  @default_ttl Application.compile_env(:phoenix_react_server, Phoenix.React)
               |> Keyword.get(:cache_ttl, 3600)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    state = %{}
    ensure_started()
    {:ok, state}
  end

  def ensure_started() do
    case :ets.whereis(@ets_table_name) do
      :undefined -> :ets.new(@ets_table_name, [:set, :public, :named_table])
      ref -> ref
    end
  end

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, @default_ttl)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Remove cached value
  """
  def delete_cache(mod, fun, args) do
    :ets.delete(@ets_table_name, [mod, fun, args])
  end

  defp lookup(mod, fun, args) do
    case :ets.lookup(@ets_table_name, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  defp check_freshness({_mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(@ets_table_name, {[mod, fun, args], result, expiration})
    result
  end
end
