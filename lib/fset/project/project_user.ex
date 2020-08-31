defmodule Fset.Project.ProjectUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "projects_users" do
    belongs_to :user, Fset.Project.User
    belongs_to :project, Fset.Project.Root
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :project_id])
    |> unique_constraint([:user_id, :project_id])
  end
end
