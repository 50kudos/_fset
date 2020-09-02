defmodule FsetWeb.UserSessionController do
  use FsetWeb, :controller

  alias Fset.Accounts
  alias FsetWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    Accounts.get_user_by_email_and_password(email, password)

    if user = Accounts.get_user_by_email_and_password(email, password) do
      profile_path = Routes.profile_path(conn, :index, user.email)
      UserAuth.log_in_user(conn, user, Map.put(user_params, :user_return_to, profile_path))
    else
      render(conn, "new.html", error_message: "Invalid e-mail or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
