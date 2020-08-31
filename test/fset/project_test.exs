defmodule Fset.ProjectTest do
  use Fset.DataCase, async: true
  use Fset.Sch.Vocab
  alias Fset.Module2
  import Fset.Project
  import Fset.AccountsFixtures

  setup do
    files =
      %{
        @id => "https://a.com",
        @defs => %{"a" => %{}, "b" => %{}}
      }
      |> Module2.encode(defs_per_file: 1)
      |> Module2.to_files()

    %{files: files}
  end

  test "#create", %{files: files} do
    {:ok, project} = create(files)

    assert length(project.schs) == 3
  end

  test "#create_with_user", %{files: files} do
    user = user_fixture()
    {:ok, project} = create_with_user(files, user.id)
    project = Fset.Repo.preload(project, :users)

    assert length(project.schs) == 3
    assert Enum.map(project.users, & &1.id) == [user.id]
  end
end
