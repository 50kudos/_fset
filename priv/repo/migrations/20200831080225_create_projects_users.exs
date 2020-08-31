defmodule Fset.Repo.Migrations.CreateProjectsUsers do
  use Ecto.Migration

  def change do
    create table(:projects_users) do
      add :project_id, references(:projects)
      add :user_id, references(:users)
    end

    create unique_index(:projects_users, [:project_id, :user_id])
  end
end
