defmodule Fset.Project.Root do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    has_many :schs, Fset.Project.File, foreign_key: :project_id
    has_one :main_sch, Fset.Project.File, where: [type: "main"], foreign_key: :project_id
    has_many :model_schs, Fset.Project.File, where: [type: "model"], foreign_key: :project_id

    many_to_many :users, Fset.Project.User,
      join_through: Fset.Project.ProjectUser,
      join_keys: [project_id: :id, user_id: :id]

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> update_change(:name, fn name -> String.replace(name, "/", "-") end)
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> cast_assoc(:schs)
  end
end
