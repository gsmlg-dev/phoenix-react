defmodule ReactDemoWeb.FormLiveTest do
  use ReactDemoWeb.ConnCase

  import Phoenix.LiveViewTest
  import ReactDemo.ReactFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_form(_) do
    form = form_fixture()
    %{form: form}
  end

  describe "Index" do
    setup [:create_form]

    test "lists all form", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/form")

      assert html =~ "Listing Form"
    end

    test "saves new form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/form")

      assert index_live |> element("a", "New Form") |> render_click() =~
               "New Form"

      assert_patch(index_live, ~p"/form/new")

      assert index_live
             |> form("#form-form", form: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#form-form", form: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/form")

      html = render(index_live)
      assert html =~ "Form created successfully"
    end

    test "updates form in listing", %{conn: conn, form: form} do
      {:ok, index_live, _html} = live(conn, ~p"/form")

      assert index_live |> element("#form-#{form.id} a", "Edit") |> render_click() =~
               "Edit Form"

      assert_patch(index_live, ~p"/form/#{form}/edit")

      assert index_live
             |> form("#form-form", form: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#form-form", form: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/form")

      html = render(index_live)
      assert html =~ "Form updated successfully"
    end

    test "deletes form in listing", %{conn: conn, form: form} do
      {:ok, index_live, _html} = live(conn, ~p"/form")

      assert index_live |> element("#form-#{form.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#form-#{form.id}")
    end
  end

  describe "Show" do
    setup [:create_form]

    test "displays form", %{conn: conn, form: form} do
      {:ok, _show_live, html} = live(conn, ~p"/form/#{form}")

      assert html =~ "Show Form"
    end

    test "updates form within modal", %{conn: conn, form: form} do
      {:ok, show_live, _html} = live(conn, ~p"/form/#{form}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Form"

      assert_patch(show_live, ~p"/form/#{form}/show/edit")

      assert show_live
             |> form("#form-form", form: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#form-form", form: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/form/#{form}")

      html = render(show_live)
      assert html =~ "Form updated successfully"
    end
  end
end
