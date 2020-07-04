defmodule Fset.Repo.Migrations.CreateOauthTokens do
  use Ecto.Migration

  def change do
    create table(:oauth_tokens) do
      add :refresh_token, :string, null: false
      add :avatar_url, :string
      add :provider, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:oauth_tokens, [:user_id])
  end
end
