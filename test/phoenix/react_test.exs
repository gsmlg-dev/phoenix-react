defmodule Phoenix.ReactTest do
  use ExUnit.Case, async: true

  alias Phoenix.React

  setup_all do
    on_exit(fn ->
      nil
      # Caddy.stop()
    end)
  end

  test "render_to_string" do
    out = React.render_to_string("tab", %{})
    IO.inspect(out)
    assert {:ok, "<div class=\"tab\"></div>"} = out
  end

  test "render_to_static_markup" do
    out = React.render_to_static_markup("tab", %{})
    IO.inspect(out)
    assert {:ok, "<div class=\"tab\"></div>"} = out
  end
end
