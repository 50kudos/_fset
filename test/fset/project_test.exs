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

  test "#create" do
    user = user_fixture()
    {:ok, project} = create(user.id, %{"type" => "bare", "name" => "a.json"})
    assert length(project.schs) == 1

    for file <- project.schs do
      assert Sch.get(file.schema, file.id) != nil
    end
  end

  test "#create_with_user successfully", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user!(files, user.id)
    project = Fset.Repo.preload(project, :users)

    assert length(project.schs) == 3
    assert Enum.map(project.users, & &1.id) == [user.id]
  end

  test "#create_with_user unsuccessfully", %{files: files} do
    user = user_fixture()
    [main | models] = files
    files = [%{main | type: :invalid_type} | models]

    assert_raise Ecto.InvalidChangesetError, fn ->
      create_with_user!(files, user.id)
    end
  end

  test "#all", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user!(files, user.id)

    assert project.id in Enum.map(all(user.id), & &1.id)
  end

  test "#all_files", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user!(files, user.id)

    [main | models] = all_files(project.id, schema: true)

    for model <- models do
      assert model.project_id == project.id
      assert model.type == :model
      assert model.id != nil
      assert model.name != nil
      assert Sch.object?(Sch.get(model.schema, model.id))
    end

    assert main.type == :main
    assert main.project_id == project.id
    assert main.id != nil
    assert main.name != nil
    assert Sch.any?(Sch.get(main.schema, main.id))
  end

  test "#load json schema successfully" do
    file = %{
      path: Path.expand("../../test/support/fixtures/json_schema/draft_7.json", __DIR__)
    }

    {:ok, map} = load(file, &Module.encode/1)
    assert %{main_sch: _, model_schs: _} = map
  end

  test "#load bad json format" do
    {:error, [json: {msg, meta}]} = load("{#}", &Module.encode/1)

    assert msg == "invalid json at position 1"
    assert meta[:data] == "{#}"
  end
end
