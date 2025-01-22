defmodule Phoenix.React.ServerTest do
  use ExUnit.Case, async: true

  alias Phoenix.React.Server
  doctest Phoenix.React

  test "render_to_string" do
    file = "test/fixtures/tab_test.js"

    {:ok, html} =
      render_to_string("bun", file, %{
        "tab1" => "Tab 1",
        "tab2" => "Tab 2",
        "content1" => "Content 1",
        "content2" => "Content 2"
      })
  end
end
