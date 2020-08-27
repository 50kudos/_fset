defmodule FsetWeb.UserRegistrationController do
  use FsetWeb, :controller

  alias Fset.Accounts
  alias Fset.Accounts.User
  alias FsetWeb.UserAuth
  alias Fset.{Persistence, Module, Sch}

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        file_attrs = %{schema: Module.new_sch(), name: Sch.gen_key("module")}
        {:ok, user_file} = Persistence.create_user_file(user, file_attrs)
        file_path = Routes.main_path(conn, :index, user_file.file_id)

        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user, %{user_return_to: file_path})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
