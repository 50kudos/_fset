defmodule Fset.Repo.Migrations.AddNameToFiles do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add(:name, :string, null: false, default: "")
    end

    create index(:files, [:name], unique: true)
  end
end
