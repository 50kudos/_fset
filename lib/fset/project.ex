defmodule Fset.Project do
  alias Fset.Project.{Root, Create, ProjectUser}
  alias Fset.{Repo, Utils, Module}

  import Ecto.Query, warn: false

  def load(%{path: path}, encoder) do
    load(File.read!(path), encoder)
  end

  def load(map, encoder) when is_map(map) do
    with %{main_sch: _, model_schs: _} = map <- encoder.(map) do
      {:ok, map}
    else
      {:error, _err_struct} ->
        {:error, [encoder: {"schema encoding is not completed", []}]}
    end
  end

  def load(data, encoder) when is_binary(data) do
    with {:ok, map} <- Jason.decode(data),
         %{main_sch: _, model_schs: _} = map <- encoder.(map) do
      {:ok, map}
    else
      {:error, %Jason.DecodeError{data: d, position: pos}} ->
        {:error, [json: {"invalid json at position #{pos}", [data: d]}]}

      {:error, _err_struct} ->
        {:error, [encoder: {"schema encoding is not completed", []}]}
    end
  end

  def get_by!(attrs) do
    Repo.get_by!(Root, attrs) |> Repo.preload(:main_sch)
  end

  def get_file!(file_id) do
    Repo.get!(Fset.Project.File, file_id)
  end

  def all(user_id) when is_integer(user_id) do
    user_projects_q = user_projects_query(user_id)

    user_projects_q =
      from p in Root,
        join: pu in subquery(user_projects_q),
        on: pu.project_id == p.id,
        order_by: [desc: p.updated_at],
        select: [:id, :name, :updated_at]

    Repo.all(user_projects_q)
  end

  def all_files(project_id) do
    all_files_q =
      from f in Fset.Project.File,
        where: f.project_id == ^project_id,
        select: [:id, :name, :type, :project_id, :schema]

    Repo.all(all_files_q)
  end

  def change_bare_create(attrs \\ %{}) do
    Ecto.Changeset.change(Create.bare_changeset(%Create{}, attrs))
  end

  def change_import_create(attrs \\ %{}) do
    Ecto.Changeset.change(Create.import_changeset(%Create{}, attrs))
  end

  defp fetch_schema(url) do
    case Finch.request(Finch.build(:get, url), FsetHttp) do
      {:ok, result} ->
        {:ok, result.body}

      {:error, %Mint.TransportError{} = error} ->
        {:error, [url: {Exception.message(error), []}]}

      {:error, %Mint.HTTPError{} = error} ->
        {:error, [url: {Exception.message(error), []}]}
    end
  end

  defp encode_schema(schema) do
    load(schema, fn a -> Module.encode(a, defs_per_file: 50) end)
  end

  def create(user_id, %{"type" => "import"} = params) do
    changeset = change_import_create(params)

    with {:ok, project} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, schema} <- fetch_schema(project.url),
         {:ok, encoded_schema} <- encode_schema(schema) do
      encoded_schema
      |> Module.init_files()
      |> create_with_user!(user_id, project.name)
    else
      {:error, %Ecto.Changeset{}} = errors -> errors
      {:error, errors} -> collect_errors(changeset, errors)
    end
  end

  def create(user_id, %{"type" => "bare"} = params) do
    changeset = change_bare_create(params)

    with {:ok, project} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, encoded_schema} <- encode_schema("{}") do
      encoded_schema
      |> Module.init_files()
      |> create_with_user!(user_id, project.name)
    else
      {:error, %Ecto.Changeset{}} = errors -> errors
      {:error, errors} -> collect_errors(changeset, errors)
    end
  end

  def collect_errors(changeset, errors) when is_list(errors) do
    errors
    |> Enum.reduce(changeset, fn {key, {msg, _meta}}, acc ->
      Ecto.Changeset.add_error(acc, key, msg)
    end)
    |> Ecto.Changeset.apply_action(:collect_errors)
  end

  def create!(files, name) when is_list(files) do
    %Root{}
    |> Root.changeset(%{name: name || Utils.gen_key("project"), schs: files})
    |> Repo.insert!()
  end

  def add_member!(project_id, user_id) do
    %ProjectUser{}
    |> ProjectUser.changeset(%{project_id: project_id, user_id: user_id})
    |> Repo.insert!()
  end

  def create_with_user!(files, user_id, filename \\ nil)

  def create_with_user!(files, user_id, filename) do
    [main_file | _] = files

    Repo.transaction(fn ->
      project = create!(files, filename)
      _project_user = add_member!(project.id, user_id)
      %{project | main_sch: main_file}
    end)
  end

  defp user_projects_query(user_id) do
    from pu in ProjectUser, where: pu.user_id == ^user_id
  end
end
