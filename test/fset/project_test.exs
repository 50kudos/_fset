defmodule Fset.ProjectTest do
  use Fset.DataCase, async: true
  use Fset.Sch.Vocab
  alias Fset.Module2
  import Fset.Project

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
end
