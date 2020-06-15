defmodule Fset.Sch do
  @types ~w(string number boolean object  array null)

  def prop(), do: Access.key(:properties, %{})
  def order(), do: Access.key(:order, [])
  def type(), do: Access.key(:type, %{})

  def new(root_key) do
    %{type: :object, properties: %{root_key => %{type: :object, order: []}}, order: [root_key]}
  end

  def put_string(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    put_prop(map, path, -1, key, %{type: :string})
  end

  def put_object(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    put_prop(map, path, -1, key, %{type: :object})
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
      |> Map.put_new(:items, %{})
    end)
  end

  def change_type(map, path, type) when type in @types do
    update_in(map, access_path(path) ++ [type()], fn _ -> String.to_atom(type) end)
  end

  def move(map, src_path, dst_path, src_indices, dst_indices)
      when is_map(map) and is_binary(src_path) and is_binary(dst_path) and
             is_list(src_indices) and is_list(dst_indices) do
    keys_indices = zip_key_index(map, src_path, src_indices, dst_indices)

    for {src_key, dst_key, dst_index} <- keys_indices, reduce: map do
      acc ->
        {src_sch, map_} = pop_prop(acc, src_path, src_key)
        put_prop(map_, dst_path, dst_index, dst_key, src_sch)
    end
  end

  def get_paths(map, dst, dst_indices)
      when is_list(dst_indices) and is_binary(dst) and is_map(map) do
    dst_schs = get_in(map, access_path(dst))

    Enum.map(dst_indices, fn i -> dst <> "[" <> Enum.at(dst_schs.order, i) <> "]" end)
  end

  defp zip_key_index(map, path, old_indices, new_indices) do
    keys = get_in(map, access_path(path) ++ [order()])

    # Only care about first index of multidrag, the rest new index will follow.
    [first_index | rest_indices] = new_indices
    new_indices = [first_index | Enum.map(rest_indices, fn _ -> first_index + 1 end)]
    old_new_indices = Enum.zip(old_indices, new_indices)

    Enum.map(old_new_indices, fn
      {old_index, {new_key, new_index}}
      when is_integer(old_index) and is_integer(new_index) and is_binary(new_key) ->
        old_key = Enum.at(keys, old_index)
        {old_key, new_key, new_index}

      {old_index, new_index} when is_integer(old_index) and is_integer(new_index) ->
        old_key = new_key = Enum.at(keys, old_index)
        {old_key, new_key, new_index}
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

  def access_path(path) when is_nil(path), do: []

  def access_path(path) when is_binary(path) do
    path
    |> URI.encode_www_form()
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
