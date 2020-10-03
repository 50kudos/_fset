defmodule Fset.Repo.Migrations.UniqueProjectFilename do
  use Ecto.Migration

  def change do
    drop index(:files, [:name], unique: true)
    create index(:files, [:project_id, :name], unique: true)
  end
end
