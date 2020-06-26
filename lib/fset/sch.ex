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
    put_schs(map, path, [%{key: key, sch: %{type: :string}, index: -1}])
  end

  def put_boolean(map, path, key \\ nil) do
    put_schs(map, path, [%{key: key, sch: %{type: :boolean}, index: -1}])
  end

  def put_number(map, path, key \\ nil) do
    put_schs(map, path, [%{key: key, sch: %{type: :number}, index: -1}])
  end

  def put_object(map, path, key \\ nil) do
    put_schs(map, path, [%{key: key, sch: %{type: :object, order: []}, index: -1}])
  end

  def put_array(map, path, key \\ nil) do
    put_schs(map, path, [%{key: key, sch: %{type: :array, items: %{}}, index: -1}])
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

  def move(map, src_indices, dst_indices)
      when is_list(src_indices) and is_list(dst_indices) and is_map(map) do
    zipped_indices = Enum.zip(src_indices, dst_indices)

    {popped_zips, remained} =
      zipped_indices
      |> Enum.group_by(fn {%{"from" => src}, _} -> src end)
      |> Enum.map_reduce(map, fn {src, indices_zip}, acc ->
        src_indices = Enum.map(indices_zip, fn {%{"index" => index}, _} -> index end)
        {popped, remained} = pop_schs(acc, src, src_indices)

        put_schs_zip = zip_popped_with_dst(map, src, popped, indices_zip)
        {put_schs_zip, remained}
      end)

    put_payloads = unzip_popped_with_dst(popped_zips)

    Enum.reduce(put_payloads, remained, fn {dst, raw_schs}, acc ->
      put_schs(acc, dst, raw_schs)
    end)
  end

  defp zip_popped_with_dst(map, src, popped, indices_zip) do
    popped =
      Enum.sort_by(popped, fn
        {k, _sch} when is_binary(k) ->
          Enum.find_index(get(map, src).order, fn key -> key === k end)

        {i, _sch} when is_integer(i) ->
          i
      end)

    indices_zip = Enum.sort_by(indices_zip, fn {%{"index" => index}, _} -> index end)
    Enum.zip(popped, indices_zip)
  end

  defp unzip_popped_with_dst(popped_zips) do
    popped_zips
    |> List.flatten()
    |> Enum.reduce(%{}, fn {{k, sch}, {_, dst_map}}, acc ->
      put_payload = %{key: dst_map["rename"] || "#{k}", sch: sch, index: dst_map["index"]}

      Map.update(acc, dst_map["to"], [put_payload], fn puts ->
        [put_payload | puts]
      end)
    end)
  end

  def rename_key(map, parent_path, old_key, new_key) do
    new_key = if new_key == "", do: old_key, else: new_key

    src_path = dst_path = parent_path
    sch = get(map, parent_path)
    index = Enum.find_index(sch.order, &(&1 == old_key))

    src_indices = [%{"from" => src_path, "index" => index}]
    dst_indices = [%{"to" => dst_path, "index" => index, "rename" => new_key}]
    move(map, src_indices, dst_indices)
  end

  def get_paths(map, dst_indices) when is_list(dst_indices) and is_map(map) do
    group_fn = fn %{"to" => dst} -> dst end
    map_fn = fn %{"index" => index} -> index end
    dst_indices = Enum.group_by(dst_indices, group_fn, map_fn)

    for {dst, dst_indices} <- dst_indices, reduce: [] do
      acc ->
        dst_paths =
          case get(map, dst) do
            %{type: :object, order: order} ->
              Enum.map(dst_indices, fn i -> dst <> "[" <> Enum.at(order, i) <> "]" end)

            %{type: :array} ->
              Enum.map(dst_indices, fn i -> dst <> "[][" <> "#{i}" <> "]" end)
          end

        dst_paths ++ acc
    end
  end

  def follow_lead(dst_indices) when is_list(dst_indices) do
    [lead | _] = Enum.sort_by(dst_indices, fn %{"index" => index} -> index end)

    dst_indices
    |> Enum.with_index(lead["index"])
    |> Enum.map(fn {a, i} -> Map.update!(a, "index", i) end)
  end

  def put_schs(map, _path, []), do: map

  def put_schs(map, path, raw_schs)
      when is_map(map) and is_binary(path) and is_list(raw_schs) do
    parent_path = access_path(path)

    update_in(map, parent_path, fn parent -> put_schs(parent, raw_schs) end)
  end

  defp put_schs(%{type: :object} = parent, raw_schs) do
    props = Map.new(raw_schs, fn raw_sch -> {raw_sch[:key], raw_sch[:sch]} end)

    parent
    |> Map.update(:properties, props, fn p -> Map.merge(p, props) end)
    |> Map.update!(:order, fn order ->
      reindex(raw_schs, order)
      |> Enum.map(fn
        %{key: k} -> k
        {k, _i} -> k
      end)
      |> Enum.uniq()
    end)
  end

  defp put_schs(%{type: :array, items: item} = parent, raw_schs) do
    schs = Enum.map(raw_schs, fn sch -> sch[:sch] end)

    case {schs, item} do
      {[sch], item} when item == %{} ->
        Map.put(parent, :items, sch)

      {_schs, items} when is_map(items) or is_list(items) ->
        items = List.wrap(items) |> Enum.filter(fn a -> map_size(a) != 0 end)

        Map.update!(parent, :items, fn _ ->
          reindex(raw_schs, items)
          |> Enum.map(fn
            %{sch: sch} -> sch
            {sch, _i} -> sch
          end)
        end)
    end
  end

  defp reindex(raw_schs, list) do
    whole_length = Enum.count(raw_schs ++ list)

    {raw_schs, coming_indices} =
      Enum.map_reduce(raw_schs, [], fn
        %{index: i} = raw_sch, acc when i < 0 ->
          {%{raw_sch | index: whole_length + i}, [whole_length + i | acc]}

        %{index: i} = raw_sch, acc ->
          {raw_sch, [i | acc]}
      end)

    list_indices = Enum.to_list(0..(whole_length - 1)) -- coming_indices
    list = Enum.zip(list, list_indices)

    Enum.sort_by(raw_schs ++ list, fn
      %{index: i} -> i
      {_k, i} -> i
    end)
  end

  def pop_schs(map, path, keys)
      when is_map(map) and is_binary(path) and is_list(keys) do
    parent_path = access_path(path)

    map
    |> get(path)
    |> pop_schs(keys)
    |> case do
      nil -> {nil, map}
      {schs, map_} -> {schs, update_in(map, parent_path, fn _ -> map_ end)}
    end
  end

  defp pop_schs(%{type: :object} = parent, keys) do
    keys =
      Enum.map(keys, fn
        k when is_binary(k) -> k
        i when is_integer(i) -> Enum.at(parent.order, i)
      end)

    {popped, remained} =
      parent
      |> Map.get(:properties)
      |> Enum.split_with(fn {prop, _} -> prop in keys end)

    map_ =
      parent
      |> Map.put(:properties, Map.new(remained))
      |> Map.update!(:order, fn order -> order -- Keyword.keys(popped) end)

    {popped, map_}
  end

  defp pop_schs(%{type: :array, items: item} = _parent, _indices) when item == %{} do
    raise "cannot pop an empty schema"
  end

  defp pop_schs(%{type: :array, items: item} = parent, _indices) when is_map(item) do
    {popped, _remained} = Map.pop!(parent, :items)
    map_ = Map.put(parent, :items, %{})
    popped = [{0, popped}]

    {popped, map_}
  end

  defp pop_schs(%{type: :array, items: items} = parent, indices) when is_list(items) do
    {popped, remained} =
      parent
      |> Map.get(:items)
      |> Enum.with_index()
      |> Enum.split_with(fn {_, i} -> i in indices end)

    map_ =
      parent
      |> Map.update!(:items, fn _ -> Keyword.keys(remained) end)
      |> Map.update!(:items, fn
        [] -> %{}
        [item] -> item
        items -> items
      end)

    popped = Enum.map(popped, fn {sch, i} -> {i, sch} end)

    {popped, map_}
  end

  defp pop_schs(_, _), do: nil

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
