defmodule Fset.Project do
  alias Fset.Project.Root, as: Project
  alias Fset.Project.ProjectUser
  alias Fset.Repo
  alias Fset.Utils

  def create(files) when is_list(files) do
    %Project{}
    |> Project.changeset(%{name: Utils.gen_key("project"), schs: files})
    |> Repo.insert()
  end

  def add_member(project_id, user_id) do
    %ProjectUser{}
    |> ProjectUser.changeset(%{project_id: project_id, user_id: user_id})
    |> Repo.insert()
  end

  def create_with_user(files, user_id) do
    Repo.transaction(fn ->
      with {:ok, project} <- create(files),
           {:ok, _project_user} <- add_member(project.id, user_id) do
        project
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
end
