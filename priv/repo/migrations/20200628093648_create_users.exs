defmodule Fset.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
