defmodule FsetWeb.HomeController do
  use FsetWeb, :controller
  alias Fset.Persistence

  def index(conn, _params) do
    if user = conn.assigns[:current_user] do
      case Persistence.get_user_files(user.id) do
        [user_file | []] -> redirect(conn, to: Routes.main_path(conn, :index, user_file.file.id))
        user_files -> render(conn, "index.html", files: Enum.map(user_files, & &1.file))
      end
    else
      conn
      |> put_view(FsetWeb.StaticPageView)
      |> render("landing.html", error_message: nil)
    end
  end
end
