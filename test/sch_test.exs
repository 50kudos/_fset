defmodule SchTest do
  use ExUnit.Case, async: true
  import Fset.Sch

  setup do
    new("root")
  end

  test "#new", root do
    assert root.type == :object
    assert root.properties == %{"root" => %{type: :object, order: []}}
    assert root.order == ["root"]
  end

  test "#get", root do
    root = put_object(root, "root", "key")
    assert get(root, "root[key]") == %{type: :object, order: []}

    root = put_array(root, "root[key]", "arr_key")
    assert get(root, "root[key][arr_key]") == %{type: :array, items: %{}}
    assert get(root, "root[key][arr_key][]") == %{type: :array, items: %{}}
    assert get(root, "root[key][arr_key][][0]") == %{}

    root = put_string(root, "root[key][arr_key]")
    assert get(root, "root[key][arr_key][][0]") == %{type: :string}
    assert get(root, "root[key][arr_key][][0][]") == %{type: :string}
    assert get(root, "root[key][arr_key][][0][][0]") == %{}
  end

  test "#put_object to object", root do
    root = put_object(root, "root", "key")

    assert get(root, "root").type == :object
    assert get(root, "root").order == ["key"]
    assert get(root, "root").properties |> Map.has_key?("key")
    assert get(root, "root[key]") == %{type: :object, order: []}
  end

  test "#put_array to object", root do
    root = put_array(root, "root", "key")

    assert get(root, "root").type == :object
    assert get(root, "root").order == ["key"]
    assert get(root, "root").properties |> Map.has_key?("key")
    assert get(root, "root[key]") == %{type: :array, items: %{}}
  end

  test "#put_object to array", root do
    root = put_array(root, "root", "arr_key")
    root = put_object(root, "root[arr_key]")

    assert get(root, "root[arr_key]").type == :array
    assert get(root, "root[arr_key]").items == %{type: :object, order: []}

    root = put_object(root, "root[arr_key]")

    assert get(root, "root[arr_key][][0]") == %{type: :object, order: []}
    assert get(root, "root[arr_key][][1]") == %{type: :object, order: []}
  end

  test "#put_array to array", root do
    root = put_array(root, "root", "arr_key")
    root = put_array(root, "root[arr_key]")

    assert get(root, "root[arr_key]").type == :array
    assert get(root, "root[arr_key]").items == %{type: :array, items: %{}}

    root = put_array(root, "root[arr_key]")

    assert get(root, "root[arr_key][][0]") == %{type: :array, items: %{}}
    assert get(root, "root[arr_key][][1]") == %{type: :array, items: %{}}
  end

  test "#put_string to object", root do
    root = put_string(root, "root", "key")

    assert get(root, "root").type == :object
    assert get(root, "root").order == ["key"]
    assert get(root, "root[key]") == %{type: :string}
  end

  test "#put_string to array", root do
    root = put_array(root, "root", "arr_key")
    root = put_string(root, "root[arr_key]")

    assert get(root, "root[arr_key]").type == :array
    assert get(root, "root[arr_key]").items == %{type: :string}
    assert get(root, "root[arr_key][][0]") == %{type: :string}
  end

  test "#pop_schs object", root do
    root = put_object(root, "root", "key1")
    root = put_object(root, "root", "key2")
    assert get(root, "root").properties |> Map.has_key?("key1")
    assert get(root, "root").properties |> Map.has_key?("key2")
    assert get(root, "root").order == ["key1", "key2"]

    {schs, root} = pop_schs(root, "root", [0, 1])
    assert schs == [{"key1", %{type: :object, order: []}}, {"key2", %{type: :object, order: []}}]
    refute get(root, "root").properties |> Map.has_key?("key1")
    refute get(root, "root").properties |> Map.has_key?("key2")
    assert get(root, "root").order == []
  end

  test "#pop_schs array", root do
    root = put_array(root, "root", "arr_key")
    root = put_string(root, "root[arr_key]")
    root = put_string(root, "root[arr_key]")

    {schs, root} = pop_schs(root, "root[arr_key]", [0, 1])
    assert schs == [{0, %{type: :string}}, {1, %{type: :string}}]
    assert get(root, "root[arr_key]") == %{type: :array, items: %{}}
  end

  test "#pop_schs outsider then insider", root do
    root =
      root
      |> put_array("root", "outsider")
      |> put_array("root[outsider]")
      |> put_string("root[outsider][][0]")

    {[sch], root} = pop_schs(root, "root[outsider]", [])
    assert get(root, "root[outsider]") == %{type: :array, items: %{}}
    assert sch == {0, %{type: :array, items: %{type: :string}}}

    {schs, _} = pop_schs(root, "root[outsider][][0]", [])
    assert schs == nil
  end

  test "#pop_schs insider then outsider", root do
    root =
      root
      |> put_array("root", "outsider")
      |> put_array("root[outsider]")
      |> put_string("root[outsider][][0]")

    {[sch], root} = pop_schs(root, "root[outsider][][0]", [])
    assert get(root, "root[outsider][][0]") == %{type: :array, items: %{}}
    assert sch == {0, %{type: :string}}

    {[sch], _} = pop_schs(root, "root[outsider]", [])
    assert sch == {0, %{type: :array, items: %{}}}
  end

  test "#pop_schs sibling ", root do
    root =
      root
      |> put_array("root", "a")
      |> put_string("root[a]")
      |> put_boolean("root[a]")
      #
      |> put_array("root", "b")
      |> put_number("root[b]")
      |> put_string("root[b]")

    {[sch1], root} = pop_schs(root, "root[a]", [1])
    {[sch2], root} = pop_schs(root, "root[b]", [0])

    assert sch1 == {1, %{type: :boolean}}
    assert sch2 == {0, %{type: :number}}
    assert get(root, "root[a]") == %{type: :array, items: %{type: :string}}
    assert get(root, "root[b]") == %{type: :array, items: %{type: :string}}
  end

  test "#put_schs multiple props to empty object", root do
    raw_schs = [
      %{key: "a", sch: %{type: :number}, index: 1},
      %{key: "b", sch: %{type: :boolean}, index: 0}
    ]

    root = put_schs(root, "root", raw_schs)
    assert get(root, "root[a]") == %{type: :number}
    assert get(root, "root[b]") == %{type: :boolean}
    assert get(root, "root").order == ["b", "a"]
  end

  test "#put_schs multiple items to empty array", root do
    root = put_array(root, "root", "arr_key")

    raw_schs = [
      %{sch: %{type: :number}, index: 1},
      %{sch: %{type: :boolean}, index: 0}
    ]

    root = put_schs(root, "root[arr_key]", raw_schs)
    assert get(root, "root[arr_key][][1]") == %{type: :number}
    assert get(root, "root[arr_key][][0]") == %{type: :boolean}
  end

  test "#rename_key", root do
    root = put_string(root, "root", "a")
    root = put_string(root, "root", "y")
    root = put_string(root, "root", "b")
    assert get(root, "root").order == ["a", "y", "b"]

    root = rename_key(root, "root", "b", "x")
    root = rename_key(root, "root", "a", "a")
    assert get(root, "root[a]") == %{type: :string}
    assert get(root, "root[y]") == %{type: :string}
    assert get(root, "root[x]") == %{type: :string}
    assert get(root, "root[b]") == nil
    assert get(root, "root").order == ["a", "y", "x"]
  end

  test "#move multi-items up and down", root do
    root =
      root
      |> put_object("root", "a")
      |> put_array("root[a]", "b")
      |> put_string("root[a][b]")
      |> put_string("root[a][b]")

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

    assert get(moved_up, "root[a]").order == ["0", "1", "b"]
    assert get(moved_down, "root") == get(root, "root")
  end

  test "#move from multiple sources", root do
    root =
      root
      |> put_array("root", "a")
      |> put_string("root[a]")
      |> put_boolean("root[a]")
      #
      |> put_array("root", "b")
      |> put_number("root[b]")
      |> put_string("root[b]")

    dst_indices = [%{"to" => "root", "index" => 1}, %{"to" => "root", "index" => 0}]
    src_indices = [%{"from" => "root[a]", "index" => 1}, %{"from" => "root[b]", "index" => 0}]
    root = move(root, src_indices, dst_indices)

    assert get(root, "root").order == ["0", "1", "a", "b"]
  end

  test "#get_paths", root do
    root =
      root
      |> put_array("root", "a")
      |> put_string("root[a]")
      |> put_string("root[a]")

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
