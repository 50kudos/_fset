defmodule FsetWeb.MainLiveTest do
  use FsetWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Main"
    assert render(page_live) =~ "Main"
  end
end
