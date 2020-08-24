defmodule Fset.Persistence.User do
  use Ecto.Schema

  schema "users" do
    field :email
    many_to_many :files, Fset.Persistence.File, join_through: Fset.Persistence.UserFile
  end
end
