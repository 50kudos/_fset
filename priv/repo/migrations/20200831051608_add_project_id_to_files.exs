defmodule Fset.Repo.Migrations.AddProjectIdToFiles do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      timestamps()
    end

    create unique_index(:projects, [:name])

    alter table(:files) do
      add :project_id, references(:projects)
      add :type, :string
    end
  end
end
