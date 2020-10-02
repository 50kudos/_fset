defmodule Fset.Project.Create do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :url, :string, virtual: true
  end

  def bare_changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unsafe_validate_unique(:name, Fset.Repo)
  end

  def import_changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :url])
    |> validate_required([:name, :url])
    |> unsafe_validate_unique(:name, Fset.Repo)
    |> validate_url()
  end

  def validate_url(changeset) do
    validate_change(changeset, :url, fn :url, url ->
      uri = URI.parse(url)

      if Enum.all?([uri.scheme, uri.host]) do
        []
      else
        [url: "invalid url"]
      end
    end)
  end
end
