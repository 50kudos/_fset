defmodule Fset.Repo.Migrations.CreateGithubTokens do
  use Ecto.Migration

  def change do
    create table(:github_tokens) do
      add :encrypted_token, :binary, null: false
      add :meta, :map
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:github_tokens, [:user_id])
  end
end
