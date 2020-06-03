defmodule Fset.Sch do
  @types ~w(string number boolean object  array null)

  def prop(), do: Access.key(:properties, %{})
  def order(), do: Access.key(:order, [])
  def type(), do: Access.key(:type, %{})

  def put_string(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    parent_path = access_path(path)

    map
    |> put_in(parent_path ++ [prop(), key], %{type: :string})
    |> update_in(parent_path ++ [order()], fn order -> [key | order] end)
  end

  def change_type(map, path, "object") do
    update_in(map, access_path(path), fn sch ->
      sch
      |> Map.put(:type, :object)
      |> Map.put_new(:order, [])
    end)
  end

  def change_type(map, path, "array") do
    update_in(map, access_path(path), fn sch ->
      sch
      |> Map.put(:type, :array)
      |> Map.put_new(:order, [])
    end)
  end

  def change_type(map, path, type) when type in @types do
    update_in(map, access_path(path) ++ [type()], fn _ -> String.to_atom(type) end)
  end

  def access_path([]), do: []
  def access_path(path) when is_nil(path), do: []

  def access_path(path) when is_binary(path) do
    path
    |> Plug.Conn.Query.decode()
    |> access_path()
    |> Enum.reverse()
  end

  def access_path(path) when is_map(path) do
    Enum.reduce(path, [], fn
      {k, v}, acc when is_map(v) ->
        access_path(v) ++ [k | [prop() | acc]]

      {k, v}, acc when is_nil(v) ->
        [k | [prop() | acc]]
    end)
  end

  # Helpers

  def gen_key() do
    id = DateTime.to_unix(DateTime.now!("Etc/UTC"), :microsecond)
    id = String.slice("#{id}", 6..-1)
    "key_#{to_string(id)}"
  end

  def inspect_path(path) do
    Enum.map(path, fn
      a when is_function(a) -> Function.info(a)[:env]
      a -> a
    end)
    |> IO.inspect()
  end
end
