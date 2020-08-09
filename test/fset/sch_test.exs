defmodule Fset.SchTest do
  use ExUnit.Case, async: true
  import Fset.Sch

  setup do
    new("root", object())
  end

  test "#new", root do
    assert object?(root)
    assert prop_sch(root, "root") == object()
    assert order(root) == ["root"]
  end

  test "#get", root do
    root = put(root, "root", "key", object())
    assert get(root, "root[key]") == object()

    root = put(root, "root[key]", "arr_key", array())
    assert get(root, "root[key][arr_key]") == array()
    assert get(root, "root[key][arr_key][]") == array()
    assert get(root, "root[key][arr_key][][0]") == %{}

    root = put(root, "root[key][arr_key]", string())
    assert get(root, "root[key][arr_key][][0]") == string()
    assert get(root, "root[key][arr_key][][0][]") == string()

    assert_raise RuntimeError, fn -> get(root, "root[key][arr_key][][0][][0]") end

    union = any_of([object(), array(), string()])
    root = put(root, "root", "union", union)
    assert get(root, "root[union][][1]") == array()
  end

  test "#put_object to object", root do
    root = put(root, "root", "key", object())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == object()
  end

  test "#put_array to object", root do
    root = put(root, "root", "key", array())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == array()
  end

  test "#put_object to array", root do
    root = put(root, "root", "arr_key", array())
    root = put(root, "root[arr_key]", object())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == object()

    root = put(root, "root[arr_key]", object())

    assert get(root, "root[arr_key][][0]") == object()
    assert get(root, "root[arr_key][][1]") == object()
  end

  test "#put_array to array", root do
    root = put(root, "root", "arr_key", array())
    root = put(root, "root[arr_key]", array())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == array()

    root = put(root, "root[arr_key]", array())

    assert get(root, "root[arr_key][][0]") == array()
    assert get(root, "root[arr_key][][1]") == array()
  end

  test "#put_string to object", root do
    root = put(root, "root", "key", string())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root[key]") == string()
  end

  test "#put_string to array", root do
    root = put(root, "root", "arr_key", array())
    root = put(root, "root[arr_key]", string())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == string()
    assert get(root, "root[arr_key][][0]") == string()
  end

  test "#pop_schs object", root do
    root = put(root, "root", "key1", object())
    root = put(root, "root", "key2", object())
    assert get(root, "root") |> properties() |> Map.has_key?("key1")
    assert get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == ["key1", "key2"]

    {schs, root} = pop_schs(root, "root", [0, 1])
    assert schs == [{"key1", object()}, {"key2", object()}]
    refute get(root, "root") |> properties() |> Map.has_key?("key1")
    refute get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == []
  end

  test "#pop_schs array", root do
    root = put(root, "root", "arr_key", array())
    root = put(root, "root[arr_key]", string())
    root = put(root, "root[arr_key]", string())

    {schs, root} = pop_schs(root, "root[arr_key]", [0, 1])
    assert schs == [{0, string()}, {1, string()}]
    assert get(root, "root[arr_key]") == array()
  end

  test "#pop_schs outsider then insider", root do
    root =
      root
      |> put("root", "outsider", array())
      |> put("root[outsider]", array())
      |> put("root[outsider][][0]", string())

    {[sch], root} = pop_schs(root, "root[outsider]", [])
    assert get(root, "root[outsider]") == array()
    assert elem(sch, 0) == 0
    assert elem(sch, 1) |> items() == string()

    {schs, _} = pop_schs(root, "root[outsider][][0]", [])
    assert schs == nil
  end

  test "#pop_schs insider then outsider", root do
    root =
      root
      |> put("root", "outsider", array())
      |> put("root[outsider]", array())
      |> put("root[outsider][][0]", string())

    {[sch], root} = pop_schs(root, "root[outsider][][0]", [])
    assert get(root, "root[outsider][][0]") == array()
    assert sch == {0, string()}

    {[sch], _} = pop_schs(root, "root[outsider]", [])
    assert sch == {0, array()}
  end

  test "#pop_schs sibling ", root do
    root =
      root
      |> put("root", "a", array())
      |> put("root[a]", string())
      |> put("root[a]", boolean())
      #
      |> put("root", "b", array())
      |> put("root[b]", number())
      |> put("root[b]", string())

    {[sch1], root} = pop_schs(root, "root[a]", [1])
    {[sch2], root} = pop_schs(root, "root[b]", [0])

    assert sch1 == {1, boolean()}
    assert sch2 == {0, number()}
    assert get(root, "root[a]") |> items() == string()
    assert get(root, "root[b]") |> items() == string()
  end

  test "#put_schs multiple props to empty object", root do
    raw_schs = [
      %{key: "a", sch: number(), index: 1},
      %{key: "b", sch: boolean(), index: 0}
    ]

    root = put_schs(root, "root", raw_schs)
    assert get(root, "root[a]") == number()
    assert get(root, "root[b]") == boolean()
    assert get(root, "root") |> order() == ["b", "a"]
  end

  test "#put_schs multiple items to empty array", root do
    root = put(root, "root", "arr_key", array())

    raw_schs = [
      %{sch: number(), index: 1},
      %{sch: boolean(), index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key][][1]") == number()
    assert get(root, "root[arr_key][][0]") == boolean()
  end

  test "#put_schs any to empty array", root do
    root = put(root, "root", "arr_key", array())

    raw_schs = [
      %{sch: any(), index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key]") |> items() == any()
  end

  test "#rename_key", root do
    root = put(root, "root", "a", string())
    root = put(root, "root", "y", string())
    root = put(root, "root", "b", string())
    assert get(root, "root") |> order() == ["a", "y", "b"]

    root = rename_key(root, "root", "b", "x")
    root = rename_key(root, "root", "a", "a")
    assert get(root, "root[a]") == string()
    assert get(root, "root[y]") == string()
    assert get(root, "root[x]") == string()
    assert get(root, "root[b]") == nil
    assert get(root, "root") |> order() == ["a", "y", "x"]
  end

  test "#move multi-items up and down", root do
    root =
      root
      |> put("root", "a", object())
      |> put("root[a]", "b", array())
      |> put("root[a][b]", string())
      |> put("root[a][b]", string())

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
    assert get(moved_down, "root[a][b]") |> items() == [string(), string(), any()]
  end

  test "#move from multiple sources", root do
    root =
      root
      |> put("root", "a", array())
      |> put("root[a]", string())
      |> put("root[a]", boolean())
      #
      |> put("root", "b", array())
      |> put("root[b]", number())
      |> put("root[b]", string())

    dst_indices = [dst_item("root", 1), dst_item("root", 0)]
    src_indices = [src_item("root[a]", 1), src_item("root[b]", 0)]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root") |> order() == ["0", "1", "a", "b"]
  end

  test "#move non-any (any, str) in tuple, should not delete the any", root do
    root = put(root, "root", "tuple", array(:hetero))
    root = put(root, "root[tuple]", any())

    dst_indices = [dst_item("root[tuple]", 1)]
    src_indices = [src_item("root[tuple]", 0)]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root[tuple]") |> items() |> length() == 2
  end

  test "#get_paths", root do
    root =
      root
      |> put("root", "a", array())
      |> put("root[a]", string())
      |> put("root[a]", string())

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
      |> put("root", "a", array())
      |> put("root[a]", string())
      |> put("root[a]", boolean())
      #
      |> put("root", "b", array())
      |> put("root[b]", number())
      |> put("root[b]", string())

    root = delete(root, ["root[a][][1]", "root[b][][0]"])

    assert get(root, "root[a]") |> items() == string()
    assert get(root, "root[b]") |> items() == string()
  end
end
