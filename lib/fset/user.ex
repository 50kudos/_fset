defmodule Fset.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :avatar_url, :string
    field :email, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :avatar_url])
    |> validate_required([:email, :avatar_url])
    |> unique_constraint(:email)
  end
end
