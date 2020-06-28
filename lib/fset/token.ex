defmodule Fset.Token do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_tokens" do
    field :encrypted_token, Fset.EctoType.EncryptedBinary
    field :meta, :map
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:encrypted_token, :meta])
    |> validate_required([:encrypted_token, :meta])
  end
end
