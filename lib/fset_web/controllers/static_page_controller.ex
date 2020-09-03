defmodule FsetWeb.StaticPageController do
  use FsetWeb, :controller
  import Phoenix.LiveView.Controller

  def landing(conn, _params) do
    if conn.assigns.current_user do
      live_render(conn, FsetWeb.ProfileLive)
    else
      render(conn, "landing.html", error_message: nil)
    end
  end
end
