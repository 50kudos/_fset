defmodule Fset.Repo.Migrations.CreateUsersFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :schema, :map

      timestamps()
    end

    create table(:users_files) do
      add :user_id, references(:users)
      add :file_id, references(:files, type: :binary_id)
    end

    create unique_index(:users_files, [:user_id, :file_id])
  end
end
