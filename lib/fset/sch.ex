defmodule Fset.Sch do
  @types ~w(string number boolean object  array null)

  def prop(), do: Access.key(:properties, %{})
  def order(), do: Access.key(:order, [])
  def type(), do: Access.key(:type, %{})

  def put_string(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    put_prop(map, path, -1, key, %{type: :string})
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

  def move(map, src_path, dst_path, src_indices, dst_indices)
      when is_map(map) and is_binary(src_path) and is_binary(dst_path) and
             is_list(src_indices) and is_list(dst_indices) do
    src_keys_dst_indices = zip_key_index(map, src_path, src_indices, dst_indices)

    for {src_key, dst_index} <- src_keys_dst_indices, reduce: map do
      acc ->
        {src_sch, map_} = pop_prop(acc, src_path, src_key)
        put_prop(map_, dst_path, dst_index, src_key, src_sch)
    end
  end

  defp zip_key_index(map, path, old_indices, new_indices) do
    keys = get_in(map, access_path(path) ++ [order()])
    old_new_indices = Enum.zip(old_indices, new_indices)

    Enum.map(old_new_indices, fn {old_index, new_index} ->
      {Enum.at(keys, old_index - 1), new_index - 1}
    end)
  end

  defp put_prop(map, path, index, key, sch)
       when is_map(map) and is_binary(path) and is_binary(key) and is_map(sch) do
    parent_path = access_path(path)

    update_in(map, parent_path, fn
      %{type: :object} = parent ->
        parent
        |> put_in([prop(), key], sch)
        |> update_in([order()], fn order ->
          List.insert_at(order, index, key) |> Enum.uniq()
        end)

      parent ->
        parent
    end)
  end

  defp pop_prop(map, path, key) when is_map(map) and is_binary(path) and is_binary(key) do
    parent_path = access_path(path)

    {sch, map} = pop_in(map, parent_path ++ [prop(), key])
    map = update_in(map, parent_path ++ [order()], fn order -> List.delete(order, key) end)

    {sch, map}
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
