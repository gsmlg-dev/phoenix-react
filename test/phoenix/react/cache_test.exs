defmodule Phoenix.React.CacheTest do
  use ExUnit.Case, async: true

  alias Phoenix.React.Cache

  setup_all do
    on_exit(fn ->
      nil
    end)
  end

  test "set / get / delete cache" do
    assert true == Cache.put("tab", %{}, :static_markup, ~s[<div class="tab"></div>])
    assert ~s[<div class="tab"></div>] == Cache.get("tab", %{}, :static_markup)
    assert true == Cache.delete_cache("tab", %{}, :static_markup)
    assert nil == Cache.get("tab", %{}, :static_markup)
  end

  test "cache ttl" do
    assert true == Cache.put("tab", %{}, :static_markup, ~s[<div class="tab"></div>], ttl: 1)
    assert ~s[<div class="tab"></div>] == Cache.get("tab", %{}, :static_markup)
    Process.sleep(2_000)
    assert nil == Cache.get("tab", %{}, :static_markup)
  end

  test "gc" do
    assert true == Cache.put("tab", %{}, :static_markup, ~s[<div class="tab"></div>], ttl: 1)
    Process.send(Phoenix.React.Cache, :gc, [:noconnect])
    Process.sleep(2_000)
    assert nil == Cache.get("tab", %{}, :static_markup)
  end
end
