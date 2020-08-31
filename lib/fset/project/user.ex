defmodule Fset.Project.User do
  use Ecto.Schema

  schema "users" do
    field :email

    many_to_many :projects, Fset.Project.Root,
      join_through: Fset.Project.ProjectUser,
      join_keys: [project_id: :id, user_id: :id]
  end
end
