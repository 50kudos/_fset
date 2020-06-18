defmodule Fset.Sch do
  @types ~w(string number boolean object array null)

  def props(), do: Access.key(:properties, %{})
  def mono_items(), do: Access.key(:items, %{})
  def hetero_items(), do: Access.key(:items, [])
  def order(), do: Access.key(:order, [])

  def new(root_key) do
    %{type: :object, properties: %{root_key => %{type: :object, order: []}}, order: [root_key]}
  end

  def put_string(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    put_sch(map, path, -1, key, %{type: :string})
  end

  def put_string(map, path) when is_binary(path) and is_map(map) do
    put_sch(map, path, -1, nil, %{type: :string})
  end

  def put_object(map, path, key) when is_binary(key) and is_binary(path) and is_map(map) do
    put_sch(map, path, -1, key, %{type: :object})
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
    update_in(map, access_path(path) ++ [:type], fn _ -> String.to_atom(type) end)
  end

  def move(map, src_path, dst_path, src_indices, dst_indices)
      when is_map(map) and is_binary(src_path) and is_binary(dst_path) and
             is_list(src_indices) and is_list(dst_indices) do
    keys_indices = zip_key_index(map, src_path, src_indices, dst_indices)

    schs =
      for {src_key, dst_key, dst_index} <- keys_indices, reduce: [] do
        acc ->
          {src_sch, _} = pop_sch(map, src_path, src_key)
          [{src_sch, dst_key, dst_index} | acc]
      end
      |> Enum.reverse()

    map =
      for {src_key, _, _} <- keys_indices, reduce: map do
        acc ->
          {_, map_} = pop_sch(acc, src_path, src_key)
          map_
      end

    for {src_sch, dst_key, dst_index} <- schs, reduce: map do
      acc -> put_sch(acc, dst_path, dst_index, dst_key, src_sch)
    end
  end

  def get_paths(map, dst, dst_indices)
      when is_list(dst_indices) and is_binary(dst) and is_map(map) do
    dst_schs = get_in(map, access_path(dst))

    case dst_schs do
      %{type: :object} ->
        Enum.map(dst_indices, fn i -> dst <> "[" <> Enum.at(dst_schs.order, i) <> "]" end)

      %{type: :array} ->
        Enum.map(dst_indices, fn i -> dst <> "[][" <> "#{i}" <> "]" end)
    end
  end

  defp zip_key_index(map, path, old_indices, new_indices) do
    map = get_in(map, access_path(path))

    # Only care about first index of multidrag, the rest new index will follow.
    [first_index | rest_indices] = new_indices
    new_indices = [first_index | Enum.map(rest_indices, fn _ -> first_index + 1 end)]
    old_new_indices = Enum.zip(old_indices, new_indices)

    Enum.map(old_new_indices, fn
      {old_index, {new_key, new_index}}
      when is_integer(old_index) and is_integer(new_index) and is_binary(new_key) ->
        case map do
          %{type: :object, order: keys} ->
            old_key = Enum.at(keys, old_index)
            {old_key, new_key, new_index}

          %{type: :array, items: _items} ->
            old_key = new_key = old_index
            {old_key, "#{new_key}", new_index}
        end

      {old_index, new_index} when is_integer(old_index) and is_integer(new_index) ->
        case map do
          %{type: :object, order: keys} ->
            old_key = new_key = Enum.at(keys, old_index)
            {old_key, new_key, new_index}

          %{type: :array, items: _items} ->
            old_key = new_key = old_index
            {old_key, "#{new_key}", new_index}
        end
    end)
  end

  defp put_sch(map, path, index, key, sch)
       when is_map(map) and
              is_binary(path) and
              (is_binary(key) or is_nil(key)) and
              is_map(sch) do
    parent_path = access_path(path)

    update_in(map, parent_path, fn
      %{type: :object} = parent ->
        parent
        |> put_in([props(), key], sch)
        |> update_in([order()], fn order ->
          List.insert_at(order, index, key) |> Enum.uniq()
        end)

      %{type: :array, items: item} = parent when item == %{} ->
        put_in(parent, [:items], sch)

      %{type: :array, items: item} = parent when is_map(item) ->
        update_in(parent, [:items], fn item -> [item, sch] end)

      %{type: :array, items: items} = parent when is_list(items) ->
        update_in(parent, [:items], fn items -> List.insert_at(items, index, sch) end)

      parent ->
        parent
    end)
  end

  defp pop_sch(map, path, key)
       when is_map(map) and is_binary(path) and
              (is_binary(key) or is_integer(key)) do
    parent_path = access_path(path)

    {sch, map_} =
      case get_in(map, parent_path) do
        %{type: :object} = parent ->
          {sch, map_} = pop_in(parent, [props(), key])
          {sch, update_in(map_, [order()], &List.delete(&1, key))}

        %{type: :array, items: item} = parent when is_map(item) ->
          pop_in(parent, [:items])

        %{type: :array, items: items} = parent when is_list(items) ->
          pop_in(parent, [:items, Access.at(key)])

        _ ->
          {nil, map}
      end

    {sch, update_in(map, parent_path, fn _ -> map_ end)}
  end

  def access_path(path) when is_binary(path) do
    path
    |> URI.encode_www_form()
    |> Plug.Conn.Query.decode()
    |> access_path()
    |> Enum.reverse()
  end

  def access_path(path) when is_nil(path), do: []

  def access_path(path) when is_map(path) or is_list(path) do
    Enum.reduce(path, [], fn
      {k, v}, acc ->
        access_path(v) ++ [k | [props() | acc]]

      %{} = map, acc ->
        [{index, v}] = Map.to_list(map)
        access_path(v) ++ [Access.at(String.to_integer(index)) | [hetero_items() | acc]]
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
