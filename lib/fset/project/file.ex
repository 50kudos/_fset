defmodule Fset.Project.File do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [:id, :name, :type, :schema]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "files" do
    field :name, :string
    field :type, Ecto.Enum, values: [:main, :model]
    field :schema, :map
    field :models_anchors, {:array, :any}, virtual: true, default: []

    # We also have "user_files" table which serves as like "uid". This project_id
    # fkey is sort of "gid" (group id). Any user that is a member of a project can
    # access files that belong to project, usually many files.

    # "uid" use case is when we want an access granted for a user who does not belong to
    # any project, such as turning an individual file into a public mode (like google doc share link).
    belongs_to :project, Fset.Project.Root

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
