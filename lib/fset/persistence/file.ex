defmodule Fset.Persistence.File do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "files" do
    field :schema, :map
    field :name, :string
    many_to_many :users, Fset.Persistence.User, join_through: Fset.Persistence.UserFile

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> change()
    |> cast(attrs, [:schema, :name])
    |> validate_required([:schema])
    |> unique_constraint(:name)
  end
end
