defmodule Phoenix.ReactTest do
  use ExUnit.Case, async: true

  alias Phoenix.React
  doctest Phoenix.React

  test "render_to_string" do
    file = Path.expand("../fixtures/tab_test.js", __DIR__)

    {:ok, html} =
      React.render_to_string(file, %{
        "tab1" => "Tab 1",
        "tab2" => "Tab 2",
        "content1" => "Content 1",
        "content2" => "Content 2"
      })

    assert html =~ "Tab 1"
    assert html =~ "Tab 2"
    assert html =~ "Content 1"
    # assert html =~ "Content 2"
  end


  test "render_to_static_markup" do
    file = Path.expand("../fixtures/tab_test.js", __DIR__)

    {:ok, html} =
      React.render_to_static_markup(file, %{
        "tab1" => "Tab 1",
        "tab2" => "Tab 2",
        "content1" => "Content 1",
        "content2" => "Content 2"
      })

    assert html =~ "Tab 1"
    assert html =~ "Tab 2"
    assert html =~ "Content 1"
    # assert html =~ "Content 2"
  end
end
