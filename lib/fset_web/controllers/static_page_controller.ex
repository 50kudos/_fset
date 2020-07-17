defmodule FsetWeb.StaticPageController do
  use FsetWeb, :controller

  def landing(conn, _params) do
    render(conn, "landing.html", error_message: nil)
  end
end
