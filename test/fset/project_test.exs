defmodule Fset.ProjectTest do
  use Fset.DataCase, async: true
  use Fset.Sch.Vocab
  alias Fset.{Sch, Module}

  import Fset.Project
  import Fset.AccountsFixtures

  setup do
    files =
      %{
        @id => "https://a.com",
        @defs => %{"a" => %{}, "b" => %{}}
      }
      |> Module.encode(defs_per_file: 1)
      |> Module.init_files()

    %{files: files}
  end

  test "#create", %{files: files} do
    {:ok, project} = create(files)
    assert length(project.schs) == 3

    for file <- project.schs do
      assert Sch.get(file.schema, file.id) != nil
    end
  end

  test "#create_with_user successfully", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user(files, user.id)
    project = Fset.Repo.preload(project, :users)

    assert length(project.schs) == 3
    assert Enum.map(project.users, & &1.id) == [user.id]
  end

  test "#create_with_user unsuccessfully", %{files: files} do
    user = user_fixture()
    [main | models] = files
    files = [%{main | type: :invalid_type} | models]

    {:error, changeset} = create_with_user(files, user.id)
    assert %{schs: [%{type: ["is invalid"]}, %{}, %{}]} = errors_on(changeset)
  end

  test "#all", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user(files, user.id)

    assert project.id in Enum.map(all(user.id), & &1.id)
  end

  test "#schs_indice", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user(files, user.id)

    [main | models] = schs_indice(project.id)

    for model <- models do
      assert model.project_id == project.id
      assert model.type == :model
      assert model.id != nil
      assert model.name != nil
      assert model.schema == nil
    end

    assert main.type == :main
    assert main.project_id == project.id
    assert main.id != nil
    assert main.name != nil
    assert main.schema == nil
  end

  test "#load json schema successfully" do
    file = %{
      path: Path.expand("../../test/support/fixtures/sch_samples/github-action.json", __DIR__)
    }

    {:ok, map} = load(file, encoder: &Module.encode/1)
    assert %{main_sch: _, model_schs: _} = map
  end

  test "#load bad json format" do
    {:error, error_struct} = load("{#}", encoder: &Module.encode/1)

    assert error_struct.data == "{#}"
    assert error_struct.position == 1
  end
end
