defmodule Fset.ModuleTest do
  use Fset.DataCase, async: true

  use Fset.Sch.Vocab
  alias Fset.Sch
  import Fset.Module2

  setup do
    nodefs = %{@id => "https://a.com"}
    defs = %{@defs => %{"a" => %{}, "b" => %{}}}

    %{nodefs: nodefs, defs: defs}
  end

  test "#init_files", %{nodefs: nodefs, defs: defs} do
    imported = encode(Map.merge(nodefs, defs), defs_per_file: 1)
    [main_file | model_files] = init_files(imported)

    assert String.starts_with?(main_file.name, "main_")
    assert main_file.type == :main
    assert Sch.get(main_file.schema, main_file.id) == nodefs

    assert length(model_files) == 2

    for {model_file, expected} <- Enum.zip(model_files, [%{"a" => %{}}, %{"b" => %{}}]) do
      model_sch = Sch.get(model_file.schema, model_file.id)
      model_props = Sch.properties(model_sch)

      assert model_props == expected
      assert String.starts_with?(model_file.name, "model_")
      assert model_file.type == :model
    end
  end
end
