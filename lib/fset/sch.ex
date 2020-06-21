defmodule Fset.Sch do
  @types ~w(string number boolean object array null)

  def props(), do: Access.key(:properties, %{})
  def items(), do: Access.key(:items, %{})
  def order(), do: Access.key(:order, [])

  def new(root_key) do
    %{type: :object, properties: %{root_key => %{type: :object, order: []}}, order: [root_key]}
  end

  def get(map, path) when is_map(map) and is_binary(path) do
    get_in(map, access_path(path))
  end

  def put_string(map, path, key \\ nil) do
    put_sch(map, path, -1, key, %{type: :string})
  end

  def put_object(map, path, key \\ nil) do
    put_sch(map, path, -1, key, %{type: :object, order: []})
  end

  def put_array(map, path, key \\ nil) do
    put_sch(map, path, -1, key, %{type: :array, items: %{}})
  end

  def change_type(map, path, "object") do
    update_in(map, access_path(path), fn %{type: _} = sch ->
      sch
      |> Map.put(:type, :object)
      |> Map.put_new(:order, [])
    end)
  end

  def change_type(map, path, "array") do
    update_in(map, access_path(path), fn %{type: _} = sch ->
      sch
      |> Map.put(:type, :array)
      |> Map.put_new(:items, %{})
    end)
  end

  def change_type(map, path, type) when type in @types do
    update_in(map, access_path(path), fn %{type: _} = sch ->
      Map.put(sch, :type, String.to_atom(type))
    end)
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
      case get_in(map, access_path(src_path)) do
        %{items: items} = sch when is_list(items) ->
          update_in(map, access_path(src_path), fn _ ->
            %{sch | items: items -- Enum.map(schs, fn {sch, _, _} -> sch end)}
          end)

        _ ->
          for {src_key, _, _} <- keys_indices, reduce: map do
            acc ->
              {_, map_} = pop_sch(acc, src_path, src_key)
              map_
          end
      end

    for {src_sch, dst_key, dst_index} <- schs, reduce: map do
      acc -> put_sch(acc, dst_path, dst_index, dst_key, src_sch)
    end
  end

  def rename_key(map, parent_path, old_key, new_key) do
    new_key = if new_key == "", do: old_key, else: new_key

    src_path = dst_path = parent_path
    sch = get(map, parent_path)
    index = Enum.find_index(sch.order, &(&1 == old_key))

    move(map, src_path, dst_path, [index], [{new_key, index}])
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
    new_indices =
      case new_indices do
        [{_, first_index} | _] ->
          new_indices
          |> Enum.with_index(first_index)
          |> Enum.map(fn {{a, _}, i} -> {a, i} end)

        [first_index | _] ->
          new_indices
          |> Enum.with_index(first_index)
          |> Enum.map(fn {_, i} -> i end)
      end

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
          {sch, map_} = pop_in(parent, [:items, Access.at(key)])

          {sch,
           Map.update!(map_, :items, fn
             [] -> %{}
             [item] -> item
             items -> items
           end)}

        _ ->
          {nil, map}
      end

    {sch, update_in(map, parent_path, fn _ -> map_ end)}
  end

  defp homo_or_hetero(index) do
    fn
      _ops, data, next when is_map(data) ->
        next.(data)

      ops, data, next when is_list(data) ->
        Access.at(String.to_integer(index)).(ops, data, next)
    end
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
        access_path(v) ++ [homo_or_hetero(index) | [items() | acc]]
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
      a when is_function(a) -> Function.info(a)[:env] |> Enum.at(0)
      a -> a
    end)
    |> IO.inspect()

    path
  end
end
