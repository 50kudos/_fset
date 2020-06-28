defmodule Fset.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :avatar_url, :string
    field :email, :string
    has_one :github_token, {"github_tokens", Fset.Token}, foreign_key: :user_id
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
