defmodule Fset.Persistence.UserFile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "users_files" do
    belongs_to :user, Fset.Persistence.User
    belongs_to :file, Fset.Persistence.File, type: Ecto.UUID
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :file_id])
    |> unique_constraint([:user_id, :file_id])
  end
end
