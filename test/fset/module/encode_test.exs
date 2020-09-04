defmodule Fset.ModuleEncodeTest do
  use Fset.DataCase, async: true

  use Fset.Sch.Vocab
  alias Fset.Sch
  import Fset.Module2.Encode

  setup do
    nodefs = %{@id => "https://a.com"}
    defs = %{@defs => %{"a" => %{}, "b" => %{}}}

    %{nodefs: nodefs, defs: defs}
  end

  test "#from_json_schema empty schema" do
    assert from_json_schema(%{}) == %{main_sch: %{}, model_schs: []}
  end

  test "#from_json_schema no defs schema", %{nodefs: jsch} do
    assert from_json_schema(jsch) == %{main_sch: jsch, model_schs: []}
  end

  test "#from_json_schema schema produces default chunk size models", %{
    nodefs: nodefs,
    defs: defs
  } do
    jsch = Map.merge(nodefs, defs)
    encoded = from_json_schema(jsch)

    assert encoded.main_sch == nodefs

    for {model_sch, expected} <- Enum.zip(encoded.model_schs, [%{"a" => %{}, "b" => %{}}]) do
      assert Sch.properties(model_sch) == expected
    end
  end

  test "#from_json_schema schema produces 1 models chunk", %{nodefs: nodefs, defs: defs} do
    jsch = Map.merge(nodefs, defs)
    encoded = from_json_schema(jsch, defs_per_file: 2)

    assert encoded.main_sch == nodefs

    for {model_sch, expected} <- Enum.zip(encoded.model_schs, [%{"a" => %{}, "b" => %{}}]) do
      assert Sch.properties(model_sch) == expected
    end
  end

  test "#from_json_schema schema produces 2 models chunks", %{nodefs: nodefs, defs: defs} do
    jsch = Map.merge(nodefs, defs)
    encoded = from_json_schema(jsch, defs_per_file: 1)

    assert encoded.main_sch == nodefs

    for {model_sch, expected} <- Enum.zip(encoded.model_schs, [%{"a" => %{}}, %{"b" => %{}}]) do
      assert Sch.properties(model_sch) == expected
    end
  end
end
