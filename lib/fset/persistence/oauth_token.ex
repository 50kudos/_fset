defmodule Fset.Persistence.OauthToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "oauth_tokens" do
    field :avatar_url, :string
    field :provider, :string
    field :refresh_token, :string
    belongs_to :user, Fset.Persistence.User

    timestamps()
  end

  @doc false
  def changeset(oauth_token, attrs) do
    oauth_token
    |> cast(attrs, [:avatar_url, :provider, :refresh_token])
    |> validate_required([:avatar_url, :provider, :refresh_token])
  end
end
