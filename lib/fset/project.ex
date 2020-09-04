defmodule Fset.Project do
  alias Fset.Project.Root, as: Project
  alias Fset.Project.ProjectUser
  alias Fset.Project.File, as: ProjectFile
  alias Fset.Repo
  alias Fset.Utils
  import Ecto.Query, warn: false

  def load(%{path: path}, encoder: encoder) do
    load(File.read!(path), encoder: encoder)
  end

  def load(data, encoder: encoder) when is_binary(data) do
    with {:ok, map} <- Jason.decode(data),
         %{main_sch: _, model_schs: _} = map <- encoder.(map) do
      {:ok, map}
    else
      {:error, _err_struct} = error -> error
    end
  end

  def get_by(attrs) do
    Repo.get_by!(Project, attrs) |> Repo.preload(:main_sch)
  end

  def get_file(file_id) do
    Repo.get!(ProjectFile, file_id)
  end

  def all(user_id) when is_integer(user_id) do
    user_projects_q = user_projects_query(user_id)

    user_projects_q =
      from p in Project,
        join: pu in subquery(user_projects_q),
        on: pu.project_id == p.id,
        select: [:id, :name]

    Repo.all(user_projects_q)
  end

  def schs_indice(project_id) do
    schs_indice_q =
      from f in ProjectFile,
        where: f.project_id == ^project_id,
        select: [:id, :name, :type, :project_id]

    Repo.all(schs_indice_q)
  end

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

  defp user_projects_query(user_id) do
    from pu in ProjectUser, where: pu.user_id == ^user_id
  end
end
