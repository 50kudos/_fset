defmodule Fset.Module2.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    has_many :schs, Fset.Module2.File, foreign_key: :project_id
    has_one :main_sch, Fset.Module2.File, where: [type: "main"], foreign_key: :project_id
    has_many :model_schs, Fset.Module2.File, where: [type: "model"], foreign_key: :project_id

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> cast_assoc(:schs)
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
