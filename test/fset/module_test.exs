defmodule Fset.ModuleTest do
  use ExUnit.Case, async: true
  use Fset.Sch.Vocab
  import Fset.Module2

  setup do
    nodefs = %{@id => "https://a.com"}
    defs = %{@defs => %{"a" => %{}, "b" => %{}}}

    %{nodefs: nodefs, defs: defs}
  end

  test "#encode empty schema" do
    assert encode(%{}) == %{main: %{}, model_schs: []}
  end

  test "#encode no defs schema", %{nodefs: jsch} do
    assert encode(jsch) == %{main: jsch, model_schs: []}
  end

  test "#encode schema produces default chunk size models", %{nodefs: nodefs, defs: defs} do
    jsch = Map.merge(nodefs, defs)
    assert encode(jsch) == %{main: nodefs, model_schs: [defs]}
  end

  test "#encode schema produces 1 models chunk", %{nodefs: nodefs, defs: defs} do
    jsch = Map.merge(nodefs, defs)
    assert encode(jsch, defs_per_file: 2) == %{main: nodefs, model_schs: [defs]}
  end

  test "#encode schema produces 2 models chunks", %{nodefs: nodefs, defs: defs} do
    jsch = Map.merge(nodefs, defs)

    assert encode(jsch, defs_per_file: 1) == %{
             main: nodefs,
             model_schs: [%{@defs => %{"a" => %{}}}, %{@defs => %{"b" => %{}}}]
           }
  end
end
