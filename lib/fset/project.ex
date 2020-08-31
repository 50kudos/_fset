defmodule Fset.Project do
  alias Fset.Project.Root, as: Project
  alias Fset.Repo
  alias Fset.Utils

  def create(files) when is_list(files) do
    %Project{}
    |> Project.changeset(%{name: Utils.gen_key("project"), schs: files})
    |> Repo.insert()
  end
end
