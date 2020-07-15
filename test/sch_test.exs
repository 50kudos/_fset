defmodule SchTest do
  use ExUnit.Case, async: true
  import Fset.Sch

  setup do
    new("root")
  end

  test "#new", root do
    assert object?(root)
    assert prop_sch(root, "root") == new_object()
    assert order(root) == ["root"]
  end

  test "#get", root do
    root = put(root, "root", "key", new_object())
    assert get(root, "root[key]") == new_object()

    root = put(root, "root[key]", "arr_key", new_array())
    assert get(root, "root[key][arr_key]") == new_array()
    assert get(root, "root[key][arr_key][]") == new_array()
    assert get(root, "root[key][arr_key][][0]") == %{}

    root = put(root, "root[key][arr_key]", new_string())
    assert get(root, "root[key][arr_key][][0]") == new_string()
    assert get(root, "root[key][arr_key][][0][]") == new_string()
    assert get(root, "root[key][arr_key][][0][][0]") == %{}
  end

  test "#put_object to object", root do
    root = put(root, "root", "key", new_object())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == new_object()
  end

  test "#put_array to object", root do
    root = put(root, "root", "key", new_array())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root") |> properties() |> Map.has_key?("key")
    assert get(root, "root[key]") == new_array()
  end

  test "#put_object to array", root do
    root = put(root, "root", "arr_key", new_array())
    root = put(root, "root[arr_key]", new_object())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == new_object()

    root = put(root, "root[arr_key]", new_object())

    assert get(root, "root[arr_key][][0]") == new_object()
    assert get(root, "root[arr_key][][1]") == new_object()
  end

  test "#put_array to array", root do
    root = put(root, "root", "arr_key", new_array())
    root = put(root, "root[arr_key]", new_array())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == new_array()

    root = put(root, "root[arr_key]", new_array())

    assert get(root, "root[arr_key][][0]") == new_array()
    assert get(root, "root[arr_key][][1]") == new_array()
  end

  test "#put_string to object", root do
    root = put(root, "root", "key", new_string())

    assert get(root, "root") |> object?()
    assert get(root, "root") |> order() == ["key"]
    assert get(root, "root[key]") == new_string()
  end

  test "#put_string to array", root do
    root = put(root, "root", "arr_key", new_array())
    root = put(root, "root[arr_key]", new_string())

    assert get(root, "root[arr_key]") |> array?()
    assert get(root, "root[arr_key]") |> items() == new_string()
    assert get(root, "root[arr_key][][0]") == new_string()
  end

  test "#pop_schs object", root do
    root = put(root, "root", "key1", new_object())
    root = put(root, "root", "key2", new_object())
    assert get(root, "root") |> properties() |> Map.has_key?("key1")
    assert get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == ["key1", "key2"]

    {schs, root} = pop_schs(root, "root", [0, 1])
    assert schs == [{"key1", new_object()}, {"key2", new_object()}]
    refute get(root, "root") |> properties() |> Map.has_key?("key1")
    refute get(root, "root") |> properties() |> Map.has_key?("key2")
    assert get(root, "root") |> order() == []
  end

  test "#pop_schs array", root do
    root = put(root, "root", "arr_key", new_array())
    root = put(root, "root[arr_key]", new_string())
    root = put(root, "root[arr_key]", new_string())

    {schs, root} = pop_schs(root, "root[arr_key]", [0, 1])
    assert schs == [{0, new_string()}, {1, new_string()}]
    assert get(root, "root[arr_key]") == new_array()
  end

  test "#pop_schs outsider then insider", root do
    root =
      root
      |> put("root", "outsider", new_array())
      |> put("root[outsider]", new_array())
      |> put("root[outsider][][0]", new_string())

    {[sch], root} = pop_schs(root, "root[outsider]", [])
    assert get(root, "root[outsider]") == new_array()
    assert elem(sch, 0) == 0
    assert elem(sch, 1) |> items() == new_string()

    {schs, _} = pop_schs(root, "root[outsider][][0]", [])
    assert schs == nil
  end

  test "#pop_schs insider then outsider", root do
    root =
      root
      |> put("root", "outsider", new_array())
      |> put("root[outsider]", new_array())
      |> put("root[outsider][][0]", new_string())

    {[sch], root} = pop_schs(root, "root[outsider][][0]", [])
    assert get(root, "root[outsider][][0]") == new_array()
    assert sch == {0, new_string()}

    {[sch], _} = pop_schs(root, "root[outsider]", [])
    assert sch == {0, new_array()}
  end

  test "#pop_schs sibling ", root do
    root =
      root
      |> put("root", "a", new_array())
      |> put("root[a]", new_string())
      |> put("root[a]", new_boolean())
      #
      |> put("root", "b", new_array())
      |> put("root[b]", new_number())
      |> put("root[b]", new_string())

    {[sch1], root} = pop_schs(root, "root[a]", [1])
    {[sch2], root} = pop_schs(root, "root[b]", [0])

    assert sch1 == {1, new_boolean()}
    assert sch2 == {0, new_number()}
    assert get(root, "root[a]") |> items() == new_string()
    assert get(root, "root[b]") |> items() == new_string()
  end

  test "#put_schs multiple props to empty object", root do
    raw_schs = [
      %{key: "a", sch: new_number(), index: 1},
      %{key: "b", sch: new_boolean(), index: 0}
    ]

    root = put_schs(root, "root", raw_schs)
    assert get(root, "root[a]") == new_number()
    assert get(root, "root[b]") == new_boolean()
    assert get(root, "root") |> order() == ["b", "a"]
  end

  test "#put_schs multiple items to empty array", root do
    root = put(root, "root", "arr_key", new_array())

    raw_schs = [
      %{sch: new_number(), index: 1},
      %{sch: new_boolean(), index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key][][1]") == new_number()
    assert get(root, "root[arr_key][][0]") == new_boolean()
  end

  test "#rename_key", root do
    root = put(root, "root", "a", new_string())
    root = put(root, "root", "y", new_string())
    root = put(root, "root", "b", new_string())
    assert get(root, "root") |> order() == ["a", "y", "b"]

    root = rename_key(root, "root", "b", "x")
    root = rename_key(root, "root", "a", "a")
    assert get(root, "root[a]") == new_string()
    assert get(root, "root[y]") == new_string()
    assert get(root, "root[x]") == new_string()
    assert get(root, "root[b]") == nil
    assert get(root, "root") |> order() == ["a", "y", "x"]
  end

  test "#move multi-items up and down", root do
    root =
      root
      |> put("root", "a", new_object())
      |> put("root[a]", "b", new_array())
      |> put("root[a][b]", new_string())
      |> put("root[a][b]", new_string())

    src_indices = [
      %{"from" => "root[a][b]", "index" => 0},
      %{"from" => "root[a][b]", "index" => 1}
    ]

    dst_indices = [
      %{"to" => "root[a]", "index" => 0},
      %{"to" => "root[a]", "index" => 1}
    ]

    moved_up = move(root, src_indices, dst_indices)

    src_indices = [
      %{"from" => "root[a]", "index" => 0},
      %{"from" => "root[a]", "index" => 1}
    ]

    dst_indices = [
      %{"to" => "root[a][b]", "index" => 0},
      %{"to" => "root[a][b]", "index" => 1}
    ]

    moved_down = move(moved_up, src_indices, dst_indices)

    assert get(moved_up, "root[a]") |> order() == ["0", "1", "b"]
    assert get(moved_down, "root") == get(root, "root")
  end

  test "#move from multiple sources", root do
    root =
      root
      |> put("root", "a", new_array())
      |> put("root[a]", new_string())
      |> put("root[a]", new_boolean())
      #
      |> put("root", "b", new_array())
      |> put("root[b]", new_number())
      |> put("root[b]", new_string())

    dst_indices = [%{"to" => "root", "index" => 1}, %{"to" => "root", "index" => 0}]
    src_indices = [%{"from" => "root[a]", "index" => 1}, %{"from" => "root[b]", "index" => 0}]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root") |> order() == ["0", "1", "a", "b"]
  end

  test "#get_paths", root do
    root =
      root
      |> put("root", "a", new_array())
      |> put("root[a]", new_string())
      |> put("root[a]", new_string())

    src_indices = [
      %{"from" => "root[a]", "index" => 0},
      %{"from" => "root[a]", "index" => 1}
    ]

    dst_indices = [
      %{"to" => "root", "index" => 0},
      %{"to" => "root", "index" => 1}
    ]

    root = move(root, src_indices, dst_indices)

    assert get_paths(root, dst_indices) == ["root[0]", "root[1]"]
  end
end
