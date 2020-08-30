defmodule Fset.SchTest do
  use ExUnit.Case, async: true
  import Fset.Sch
  alias Fset.Sch.New

  setup do
    new("root", New.object())
  end

  test "#new", root do
    assert object?(root)
    assert prop_sch(root, "root") == New.object()
    assert order(root) == ["root"]
  end

  test "#get", root do
    root = put(root, "root", "key", New.object())
    assert get(root, "root[key]") == New.object()

    root = put(root, "root[key]", "arr_key", New.array())
    assert get(root, "root[key][arr_key]") == New.array()
    assert get(root, "root[key][arr_key][]") == New.array()
    assert get(root, "root[key][arr_key][][0]") == %{}

    root = put(root, "root[key][arr_key]", New.string())
    assert get(root, "root[key][arr_key][][0]") == New.string()
    assert get(root, "root[key][arr_key][][0][]") == New.string()

    assert get(root, "root[key][arr_key][][0][][0]") == nil

    union = New.any_of([New.object(), New.array(), New.string()])
    root = put(root, "root", "union", union)
    assert get(root, "root[union][][1]") == New.array()
  end

  test "#put_object to object", root do
    root = put(root, "root", "key", New.object())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == New.object()
  end

  test "#put_array to object", root do
    root = put(root, "root", "key", New.array())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == New.array()
  end

  test "#put_object to array", root do
    root = put(root, "root", "arr_key", New.array())
    root = put(root, "root[arr_key]", New.object())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == New.object()

    root = put(root, "root[arr_key]", New.object())

    assert get(root, "root[arr_key][][0]") == New.object()
    assert get(root, "root[arr_key][][1]") == New.object()
  end

  test "#put_array to array", root do
    root = put(root, "root", "arr_key", New.array())
    root = put(root, "root[arr_key]", New.array())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == New.array()

    root = put(root, "root[arr_key]", New.array())

    assert get(root, "root[arr_key][][0]") == New.array()
    assert get(root, "root[arr_key][][1]") == New.array()
  end

  test "#put_string to object", root do
    root = put(root, "root", "key", New.string())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root[key]") == New.string()
  end

  test "#put_string to array", root do
    root = put(root, "root", "arr_key", New.array())
    root = put(root, "root[arr_key]", New.string())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == New.string()
    assert get(root, "root[arr_key][][0]") == New.string()
  end

  test "#pop_schs object", root do
    root = put(root, "root", "key1", New.object())
    root = put(root, "root", "key2", New.object())
    assert get(root, "root") |> properties() |> Map.has_key?("key1")
    assert get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == ["key1", "key2"]

    {schs, root} = pop_schs(root, "root", [0, 1])
    assert schs == [{"key1", New.object()}, {"key2", New.object()}]
    refute get(root, "root") |> properties() |> Map.has_key?("key1")
    refute get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == []
  end

  test "#pop_schs array", root do
    root = put(root, "root", "arr_key", New.array())
    root = put(root, "root[arr_key]", New.string())
    root = put(root, "root[arr_key]", New.string())

    {schs, root} = pop_schs(root, "root[arr_key]", [0, 1])
    assert schs == [{0, New.string()}, {1, New.string()}]
    assert get(root, "root[arr_key]") == New.array()
  end

  test "#pop_schs outsider then insider", root do
    root =
      root
      |> put("root", "outsider", New.array())
      |> put("root[outsider]", New.array())
      |> put("root[outsider][][0]", New.string())

    {[sch], root} = pop_schs(root, "root[outsider]", [])
    assert get(root, "root[outsider]") == New.array()
    assert elem(sch, 0) == 0
    assert elem(sch, 1) |> items() == New.string()

    {schs, _} = pop_schs(root, "root[outsider][][0]", [])
    assert schs == nil
  end

  test "#pop_schs insider then outsider", root do
    root =
      root
      |> put("root", "outsider", New.array())
      |> put("root[outsider]", New.array())
      |> put("root[outsider][][0]", New.string())

    {[sch], root} = pop_schs(root, "root[outsider][][0]", [])
    assert get(root, "root[outsider][][0]") == New.array()
    assert sch == {0, New.string()}

    {[sch], _} = pop_schs(root, "root[outsider]", [])
    assert sch == {0, New.array()}
  end

  test "#pop_schs sibling ", root do
    root =
      root
      |> put("root", "a", New.array())
      |> put("root[a]", New.string())
      |> put("root[a]", New.boolean())
      #
      |> put("root", "b", New.array())
      |> put("root[b]", New.number())
      |> put("root[b]", New.string())

    {[sch1], root} = pop_schs(root, "root[a]", [1])
    {[sch2], root} = pop_schs(root, "root[b]", [0])

    assert sch1 == {1, New.boolean()}
    assert sch2 == {0, New.number()}
    assert get(root, "root[a]") |> items() == New.string()
    assert get(root, "root[b]") |> items() == New.string()
  end

  test "#put_schs multiple props to empty object", root do
    raw_schs = [
      %{key: "a", sch: New.number(), index: 1},
      %{key: "b", sch: New.boolean(), index: 0}
    ]

    root = put_schs(root, "root", raw_schs)
    assert get(root, "root[a]") == New.number()
    assert get(root, "root[b]") == New.boolean()
    assert get(root, "root") |> order() == ["b", "a"]
  end

  test "#put_schs multiple items to empty array", root do
    root = put(root, "root", "arr_key", New.array())

    raw_schs = [
      %{sch: New.number(), index: 1},
      %{sch: New.boolean(), index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key][][1]") == New.number()
    assert get(root, "root[arr_key][][0]") == New.boolean()
  end

  test "#put_schs any to empty array", root do
    root = put(root, "root", "arr_key", New.array())

    raw_schs = [
      %{sch: New.any(), index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key]") |> items() == New.any()
  end

  test "#rename_key", root do
    root = put(root, "root", "a", New.string())
    root = put(root, "root", "y", New.string())
    root = put(root, "root", "b", New.string())
    assert get(root, "root") |> order() == ["a", "y", "b"]

    root = rename_key(root, "root", "b", "x")
    root = rename_key(root, "root", "a", "a")
    assert get(root, "root[a]") == New.string()
    assert get(root, "root[y]") == New.string()
    assert get(root, "root[x]") == New.string()
    assert get(root, "root[b]") == nil
    assert get(root, "root") |> order() == ["a", "y", "x"]
  end

  test "#move multi-items up and down", root do
    root =
      root
      |> put("root", "a", New.object())
      |> put("root[a]", "b", New.array())
      |> put("root[a][b]", New.string())
      |> put("root[a][b]", New.string())

    src_indices = [
      src_item("root[a][b]", 0),
      src_item("root[a][b]", 1)
    ]

    dst_indices = [
      dst_item("root[a]", 0),
      dst_item("root[a]", 1)
    ]

    moved_up = move(root, src_indices, dst_indices)

    src_indices = [
      src_item("root[a]", 0),
      src_item("root[a]", 1)
    ]

    dst_indices = [
      dst_item("root[a][b]", 0),
      dst_item("root[a][b]", 1)
    ]

    moved_down = move(moved_up, src_indices, dst_indices)

    assert get(moved_up, "root[a]") |> order() == ["0", "1", "b"]
    assert get(moved_down, "root[a][b]") |> items() == [New.string(), New.string(), New.any()]
  end

  test "#move from multiple sources", root do
    root =
      root
      |> put("root", "a", New.array())
      |> put("root[a]", New.string())
      |> put("root[a]", New.boolean())
      #
      |> put("root", "b", New.array())
      |> put("root[b]", New.number())
      |> put("root[b]", New.string())

    dst_indices = [dst_item("root", 1), dst_item("root", 0)]
    src_indices = [src_item("root[a]", 1), src_item("root[b]", 0)]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root") |> order() == ["0", "1", "a", "b"]
  end

  test "#move non-any (any, str) in tuple, should not delete the any", root do
    root = put(root, "root", "tuple", New.array(:hetero))
    root = put(root, "root[tuple]", New.any())

    dst_indices = [dst_item("root[tuple]", 1)]
    src_indices = [src_item("root[tuple]", 0)]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root[tuple]") |> items() |> length() == 2
  end

  test "#move a leaf of 1st level list into 3rd level list", root do
    root = put(root, "root", "arr_key", New.array())
    root = put(root, "root[arr_key]", New.boolean())
    root = put(root, "root[arr_key]", New.string())
    root = put(root, "root[arr_key]", New.null())
    root = put(root, "root[arr_key]", New.array(:hetero))
    root = put(root, "root[arr_key][][3]", New.array(:hetero))

    dst_indices = [dst_item("root[arr_key][][3][][1]", 1)]
    src_indices = [src_item("root[arr_key]", 2)]

    root = move(root, src_indices, dst_indices)
    assert get(root, "root[arr_key][][2][][1]") |> items() == [New.string(), New.null()]
  end

  test "#get_paths", root do
    root =
      root
      |> put("root", "a", New.array())
      |> put("root[a]", New.string())
      |> put("root[a]", New.string())

    src_indices = [
      src_item("root[a]", 0),
      src_item("root[a]", 1)
    ]

    dst_indices = [
      dst_item("root", 0),
      dst_item("root", 1)
    ]

    root = move(root, src_indices, dst_indices)

    assert get_paths(root, dst_indices) == ["root[0]", "root[1]"]
  end

  test "#delete by paths", root do
    root =
      root
      |> put("root", "a", New.array())
      |> put("root[a]", New.string())
      |> put("root[a]", New.boolean())
      #
      |> put("root", "b", New.array())
      |> put("root[b]", New.number())
      |> put("root[b]", New.string())

    root = delete(root, ["root[a][][1]", "root[b][][0]"])

    assert get(root, "root[a]") |> items() == New.string()
    assert get(root, "root[b]") |> items() == New.string()
  end

  test "#expand_multi_types" do
    root = new("root", %{})
    schs = [New.array(), New.object(), New.string()]
    root = Enum.reduce(schs, root, &Map.merge/2)
    root = Map.merge(root, New.type(Enum.map(schs, &type/1)))

    any_of_schs = any_of(expand_multi_types(root))
    assert length(any_of_schs) == 3
    assert array?(Enum.at(any_of_schs, 0))
    assert object?(Enum.at(any_of_schs, 1))
    assert string?(Enum.at(any_of_schs, 2))
  end
end
