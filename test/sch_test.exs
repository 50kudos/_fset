defmodule SchTest do
  use ExUnit.Case, async: true
  alias Fset.Sch

  setup do
    Sch.new("root")
  end

  test "#new", root do
    assert root.type == :object
    assert root.properties == %{"root" => %{type: :object, order: []}}
    assert root.order == ["root"]
  end

  test "#put_object to object", root do
    root = Sch.put_object(root, "root", "key")
    parent = Sch.get(root, "root")
    sch = Sch.get(root, "root[key]")

    assert parent.type == :object
    assert parent.order == ["key"]
    assert parent.properties |> Map.has_key?("key")
    assert sch == %{type: :object, order: []}
  end

  test "#put_array to object", root do
    root = Sch.put_array(root, "root", "key")
    parent = Sch.get(root, "root")
    sch = Sch.get(root, "root[key]")

    assert parent.type == :object
    assert parent.order == ["key"]
    assert parent.properties |> Map.has_key?("key")
    assert sch == %{type: :array, items: %{}}
  end

  test "#put_object to array", root do
    root =
      root
      |> Sch.put_array("root", "arr_key")
      |> Sch.put_object("root[arr_key]")

    parent = Sch.get(root, "root[arr_key]")

    assert parent.type == :array
    assert parent.items == %{type: :object, order: []}

    root = Sch.put_object(root, "root[arr_key]")

    assert Sch.get(root, "root[arr_key][][0]") == %{type: :object, order: []}
    assert Sch.get(root, "root[arr_key][][1]") == %{type: :object, order: []}
  end

  test "#put_array to array", root do
    root =
      root
      |> Sch.put_array("root", "arr_key")
      |> Sch.put_array("root[arr_key]")

    parent = Sch.get(root, "root[arr_key]")

    assert parent.type == :array
    assert parent.items == %{type: :array, items: %{}}

    root = Sch.put_array(root, "root[arr_key]")

    assert Sch.get(root, "root[arr_key][][0]") == %{type: :array, items: %{}}
    assert Sch.get(root, "root[arr_key][][1]") == %{type: :array, items: %{}}
  end

  test "#put_string to object", root do
    root = Sch.put_string(root, "root", "key")
    parent = Sch.get(root, "root")
    sch = Sch.get(root, "root[key]")

    assert parent.type == :object
    assert parent.order == ["key"]
    assert sch == %{type: :string}
  end

  test "#put_string to array", root do
    root = Sch.put_array(root, "root", "arr_key")
    root = Sch.put_string(root, "root[arr_key]")

    parent = Sch.get(root, "root[arr_key]")
    sch = Sch.get(root, "root[arr_key][][0]")

    assert parent.type == :array
    assert parent.items == %{type: :string}
    assert sch == %{type: :string}
  end

  test "#rename_key", root do
    root = Sch.put_string(root, "root", "a")
    root = Sch.rename_key(root, "root", "a", "b")

    assert Sch.get(root, "root[a]") == nil
    assert Sch.get(root, "root[b]") == %{type: :string}
  end
end
