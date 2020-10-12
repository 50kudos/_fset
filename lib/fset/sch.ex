defmodule Fset.Sch do
  use Fset.Sch.Vocab

  # Accessor
  ## Core
  def id(sch) when is_map(sch), do: Map.get(sch, @id)
  def ref(sch) when is_map(sch), do: Map.get(sch, @ref)
  def defs(sch) when is_map(sch), do: Map.get(sch, @defs) || Map.get(sch, @definitions)
  def anchor(sch) when is_map(sch), do: Map.get(sch, @anchor)

  ## Validation
  ### object
  def min_properties(sch) when is_map(sch), do: Map.get(sch, @min_properties)
  def max_properties(sch) when is_map(sch), do: Map.get(sch, @max_properties)
  def required(sch) when is_map(sch), do: Map.get(sch, @required, [])
  ### array
  def min_items(sch) when is_map(sch), do: Map.get(sch, @min_items)
  def max_items(sch) when is_map(sch), do: Map.get(sch, @max_items)
  ### string
  def min_length(sch) when is_map(sch), do: Map.get(sch, @min_length)
  def max_length(sch) when is_map(sch), do: Map.get(sch, @max_length)
  def pattern(sch) when is_map(sch), do: Map.get(sch, @pattern)
  ### number
  def minimum(sch) when is_map(sch), do: Map.get(sch, @minimum)
  def maximum(sch) when is_map(sch), do: Map.get(sch, @maximum)
  def multiple_of(sch) when is_map(sch), do: Map.get(sch, @multiple_of)
  ## typed
  def const(sch) when is_map(sch), do: Map.get(sch, @const)
  def type(sch) when is_map(sch), do: Map.get(sch, @type_)

  ## Applicator
  def items(sch) when is_map(sch), do: Map.get(sch, @items, %{})
  def properties(sch) when is_map(sch), do: Map.get(sch, @properties, %{})
  def any_of(sch) when is_map(sch), do: Map.get(sch, @any_of)

  ## Metadata
  def title(sch) when is_map(sch), do: Map.get(sch, @title, "")
  def description(sch) when is_map(sch), do: Map.get(sch, @description, "")
  def examples(sch) when is_map(sch), do: Map.get(sch, @examples, [])

  def example(sch) do
    example = Enum.take_random(examples(sch), 1)
    if(example == [], do: [], else: hd(example))
  end

  # Helper
  def prop_sch(sch, key) when is_map(sch), do: Map.get(properties(sch), key)
  def def_sch(sch, key) when is_map(sch), do: Map.get(defs(sch), key)

  ## Custom
  def order(sch) when is_map(sch), do: Map.get(sch, @props_order, [])
  def defs_order(sch) when is_map(sch), do: Map.get(sch, @defs_order, [])
  # END Accessor

  # Matcher
  def object?(sch),
    do: match?(%{@type_ => @object}, sch)

  def object?(sch, :empty),
    do: match?(%{@type_ => @object, @properties => prop} when prop == %{}, sch)

  def array?(sch),
    do: match?(%{@type_ => @array, @items => _}, sch)

  def array?(sch, :empty),
    do: match?(%{@type_ => @array, @items => item} when item == %{}, sch)

  def array?(sch, :homo),
    do: match?(%{@type_ => @array, @items => item} when is_map(item), sch)

  def array?(sch, :hetero),
    do: match?(%{@type_ => @array, @items => items} when is_list(items), sch)

  def any_of?(sch),
    do: match?(%{@any_of => schs} when is_list(schs) and length(schs) > 0, sch)

  def string?(sch), do: match?(%{@type_ => @string}, sch)
  def number?(sch), do: match?(%{@type_ => @number}, sch)
  def integer?(sch), do: match?(%{@type_ => @integer}, sch)
  def boolean?(sch), do: match?(%{@type_ => @boolean}, sch)
  def null?(sch), do: match?(%{@type_ => @null}, sch)
  def leaf?(sch), do: match?(%{@type_ => _}, sch)
  def leaf?(sch, :multi), do: match?(%{@type_ => types} when is_list(types), sch)
  def ref?(sch), do: match?(%{@ref => _}, sch)
  def const?(sch), do: match?(%{@const => _}, sch)
  def enum?(sch), do: match?(%{@enum => _}, sch)

  def any?(sch) do
    Enum.all?([
      !ref?(sch),
      !const?(sch),
      !leaf?(sch)
    ])
  end

  # END Matcher

  @doc """
  schema with a wrapper name. When a schema is created, we can then use this wrapper
  name to query its body.

  ## Examples

      iex> new("root", %{})
      %{
        "type" => @object,
        "properties" => %{root_key => %{}},
        "order" => [root_key]
      }

  """
  def new(root_key, init_sch \\ %{}) do
    %{
      @type_ => @object,
      @properties => %{root_key => init_sch},
      @props_order => [root_key]
    }
  end

  def get({_pre, _post, map}, path), do: get(map, path)

  def get(map, path) when is_map(map) and is_binary(path) do
    get_in(map, access_path(path))
  end

  def put(map, path, sch), do: put(map, path, nil, sch)

  @doc """
    %{key: _, sch: _, index: _} is called `raw_sch` within this module.
  """
  def put(map, path, key, sch, index \\ -1) when is_map(sch) do
    put_schs(map, path, [%{key: key, sch: sch, index: index}])
  end

  def put_def(map, key, sch, index \\ -1) when is_binary(key) and is_map(sch) do
    raw_schs = [%{key: key, sch: sch, index: index}]
    defs = Map.new(raw_schs, fn %{key: key, sch: sch} -> {key, sch} end)

    map
    |> Map.update(@defs, defs, fn p -> Map.merge(p, defs) end)
    |> Map.update!(@defs_order, fn order ->
      reindex(raw_schs, order)
      |> Enum.map(fn
        %{key: k} -> k
        {k, _i} -> k
      end)
      |> Enum.uniq()
    end)
  end

  def put_defs(map, defs) when is_map(map), do: Map.put(map, @defs, defs)

  def pop_defs(sch) when is_map(sch) do
    case Map.pop(sch, @defs) do
      {nil, sch} ->
        Map.pop(sch, @definitions)

      {defs, sch} ->
        {defs, sch}
    end
  end

  def change_type(map, path, %{@type_ => type} = new_sch) when type in @types do
    {pre, new_map} =
      get_and_update_in(map, access_path(path), fn sch ->
        {sch,
         Map.merge(sch, new_sch, fn
           @type_, _v1, v2 -> v2
           @items, _v1, v2 -> v2
           # TODO: When prefixItem is added (draft-8 patch), add @prefixItems here.
           _k, v1, _v2 -> v1
         end)
         |> case do
           %{@type_ => @object} = sch ->
             Map.take(sch, [@type_, @properties, @props_order, @anchor])

           %{@type_ => @array} = sch ->
             Map.take(sch, [@type_, @items, @anchor])

           sch ->
             sch
         end}
      end)

    {pre, _post = get(new_map, path), new_map}
  end

  def change_type(map, path, %{@any_of => schs}) when is_list(schs) and length(schs) > 0 do
    {pre, new_map} =
      get_and_update_in(map, access_path(path), fn sch ->
        {sch,
         sch
         |> Map.update(@any_of, schs, fn old_schs -> old_schs end)
         |> Map.take([@any_of, @anchor])}
      end)

    {pre, _post = get(new_map, path), new_map}
  end

  def change_type(map, path, %{@ref => ref}) do
    {pre, new_map} =
      get_and_update_in(map, access_path(path), fn sch ->
        {sch,
         sch
         |> Map.put(@ref, ref)
         |> Map.take([@ref, @anchor])}
      end)

    {pre, _post = get(new_map, path), new_map}
  end

  def change_type(map, path, %{@const => const}) do
    {pre, new_map} =
      get_and_update_in(map, access_path(path), fn sch ->
        {sch,
         sch
         |> Map.put(@const, const)
         |> Map.take([@const, @anchor])}
      end)

    {pre, _post = get(new_map, path), new_map}
  end

  def enum_to_union_value(%{@enum => enum} = map) when is_list(enum) do
    map
    |> Map.delete(@enum)
    |> Map.delete(@type_)
    |> Map.put(@any_of, Enum.map(enum, fn el -> %{@const => el} end))
  end

  def repair_keywords(map) do
    walk_container(map, fn
      %{@type_ => @object} ->
        map = Map.put_new(map, @properties, %{})
        _map = Map.put_new(map, @props_order, Map.keys(Map.get(map, @properties)))

      %{@type_ => @array} ->
        _map = Map.put_new(map, @items, %{})

      _ ->
        map
    end)
  end

  def expand_multi_types(%{@type_ => types} = map) when is_list(types) do
    {types, map} = Map.pop(map, @type_)

    {typed_schs, no_types} =
      types
      |> Enum.filter(fn t -> t in @types end)
      |> Enum.map(fn t -> %{@type_ => t} end)
      |> Enum.map_reduce(map, fn
        %{@type_ => @object} = sch, acc ->
          object_keywords = [
            @properties,
            @patternProperties,
            @props_order,
            @max_properties,
            @min_properties,
            @required
          ]

          {took, remained} = Map.split(map, object_keywords)
          {Map.merge(sch, took), Map.merge(acc, remained)}

        %{@type_ => @array} = sch, acc ->
          array_keywords = [@items, @max_items, @min_items]
          {took, remained} = Map.split(map, array_keywords)

          {Map.merge(sch, took), Map.merge(acc, remained)}

        %{@type_ => @string} = sch, acc ->
          string_keywords = [@min_length, @max_length, @pattern]
          {took, remained} = Map.split(map, string_keywords)
          {Map.merge(sch, took), Map.merge(acc, remained)}

        %{@type_ => @number} = sch, acc ->
          number_keywords = [@multiple_of, @maximum, @minimum]
          {took, remained} = Map.split(map, number_keywords)
          {Map.merge(sch, took), Map.merge(acc, remained)}

        %{@type_ => @boolean} = sch, acc ->
          {sch, acc}

        %{@type_ => @null} = sch, acc ->
          {sch, acc}
      end)

    Map.merge(no_types, %{@any_of => typed_schs})
  end

  def src_item(path, index) when is_binary(path) and is_integer(index) do
    %{"from" => path, "index" => index}
  end

  def dst_item(path, index) when is_binary(path) and is_integer(index) do
    %{"to" => path, "index" => index}
  end

  def put_dst_id(map, dst_indices) do
    dst_indices
    |> Enum.group_by(fn %{"to" => dst} -> dst end)
    |> Enum.map_reduce(map, fn {dst, _}, acc ->
      id = Ecto.UUID.generate()

      acc =
        update_in(acc, access_path(dst), fn dst_sch ->
          Map.put(dst_sch, @id, id)
        end)

      {%{dst => id}, acc}
    end)
  end

  def put_moved_items_id(put_payloads) do
    {ids, put_payloads} =
      Enum.map_reduce(put_payloads, %{}, fn {dst, raw_schs}, acc ->
        ids_raw_schs =
          for raw_sch <- raw_schs do
            id = Ecto.UUID.generate()
            raw_sch = %{raw_sch | sch: Map.put(raw_sch[:sch], @id, id)}

            {id, raw_sch}
          end

        {ids, raw_schs} = Enum.unzip(ids_raw_schs)
        {ids, Map.put(acc, dst, raw_schs)}
      end)

    {List.flatten(ids), put_payloads}
  end

  def move(map, src_indices, dst_indices)
      when is_list(src_indices) and is_list(dst_indices) and is_map(map) do
    zipped_indices = Enum.zip(src_indices, dst_indices)
    {dst_ids, map} = put_dst_id(map, dst_indices)

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
    {moved_ids, put_payloads} = put_moved_items_id(put_payloads)

    new_schema =
      Enum.reduce(put_payloads, remained, fn {dst, raw_schs}, acc ->
        case get(acc, dst) do
          nil ->
            # There exists a case where given dst is no longer point to a sch.
            # In a scenario that we move a sibling sch [1] into a sibling container [2],
            # and [1] index is less than [2], poping [1] results in [2] index located at [1],
            # So dst point to [2] no longer able to get the sch.

            attempt_put_schs(acc, dst, raw_schs, dst_ids)

          _ ->
            update_in(acc, access_path(dst), fn parent -> put_schs(parent, raw_schs) end)
        end
      end)

    moved_paths = Enum.map(moved_ids, &find_path_by_id(new_schema, &1))

    {moved_paths, new_schema}
  end

  defp zip_popped_with_dst(map, src, popped, indices_zip) do
    popped =
      Enum.sort_by(popped, fn
        {k, _sch} when is_binary(k) ->
          Enum.find_index(get(map, src) |> order(), fn key -> key === k end)

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
    new_key = String.trim(new_key)
    old_key = String.trim(old_key)
    new_key = if new_key == "", do: old_key, else: new_key

    src_path = dst_path = parent_path
    sch = get(map, parent_path)
    index = Enum.find_index(order(sch), &(&1 == old_key))

    src_indices = [%{"from" => src_path, "index" => index}]
    dst_indices = [%{"to" => dst_path, "index" => index, "rename" => new_key}]
    {_moved_paths, new_schema} = move(map, src_indices, dst_indices)
    {_pre = sch, _post = get(new_schema, parent_path), new_schema}
  end

  def get_paths(map, dst_indices) when is_list(dst_indices) and is_map(map) do
    group_fn = fn %{"to" => dst} -> dst end
    map_fn = fn %{"index" => index} -> index end
    dst_indices = Enum.group_by(dst_indices, group_fn, map_fn)

    for {dst, dst_indices} <- dst_indices, reduce: [] do
      acc ->
        dst_paths =
          case get(map, dst) do
            %{@type_ => @object, @props_order => order} ->
              Enum.map(dst_indices, fn i -> dst <> "[" <> Enum.at(order, i) <> "]" end)

            %{@type_ => @array} ->
              Enum.map(dst_indices, fn i -> dst <> "[][" <> "#{i}" <> "]" end)

            %{@any_of => _} ->
              Enum.map(dst_indices, fn i -> dst <> "[][" <> "#{i}" <> "]" end)
          end

        dst_paths ++ acc
    end
  end

  def delete(map, paths) when is_binary(paths) or is_list(paths) do
    parent_paths_children_keys = find_parents(paths)

    for {parent_path, children_keys} <- parent_paths_children_keys, reduce: map do
      acc -> pop_schs(acc, parent_path, children_keys) |> elem(1)
    end
  end

  def follow_lead(dst_indices) when is_list(dst_indices) do
    [lead | _] = Enum.sort_by(dst_indices, fn %{"index" => index} -> index end)

    dst_indices
    |> Enum.with_index(lead["index"])
    |> Enum.map(fn {a, i} -> Map.update!(a, "index", i) end)
  end

  def attempt_put_schs(map, dst, raw_schs, ids) do
    id = Enum.find_value(ids, fn %{^dst => id} -> id end)

    case find_path_by_id(map, id) do
      "" ->
        raise "not found sch for #{dst} path"

      dst ->
        update_in(map, access_path(dst), fn parent -> put_schs(parent, raw_schs) end)
    end
  end

  def find_path_by_id(map, id) do
    find_path(map, fn sch -> Map.get(sch, @id) == id end)
  end

  @doc """
  Find path based on a given function result as boolean.
  Halted immedialy when condition is met.
  """
  def find_path(map, fun) do
    map
    |> find_path_by(fun)
    |> Enum.reverse()
    |> List.update_at(0, fn head -> head |> String.trim("[") |> String.trim("]") end)
    |> Enum.join()
  end

  defp find_path_by(%{@type_ => @object, @properties => props}, fun)
       when is_function(fun) do
    Enum.reduce_while(props, [], fn {k, sch}, acc ->
      path = ["[#{k}]" | acc]
      find_path_by_(sch, fun, path)
    end)
  end

  defp find_path_by(%{@type_ => @object, @patternProperties => props}, fun)
       when is_function(fun) do
    Enum.reduce_while(props, [], fn {k, sch}, acc ->
      path = ["[#{k}]" | acc]
      find_path_by_(sch, fun, path)
    end)
  end

  defp find_path_by(%{@type_ => @array} = map, fun) when is_function(fun) do
    List.wrap(items(map))
    |> Enum.with_index()
    |> Enum.reduce_while([], fn {sch, i}, acc ->
      path = ["[#{i}]", "[]"] ++ acc
      find_path_by_(sch, fun, path)
    end)
  end

  defp find_path_by(%{@any_of => schs}, fun) when is_function(fun) do
    schs
    |> Enum.with_index()
    |> Enum.reduce_while([], fn {sch, i}, acc ->
      path = ["[#{i}]", "[]"] ++ acc
      find_path_by_(sch, fun, path)
    end)
  end

  defp find_path_by(_map, _fun), do: []

  defp find_path_by_(sch, fun, path) do
    cond do
      fun.(sch) ->
        {:halt, path}

      true ->
        case find_path_by(sch, fun) do
          [] -> {:cont, []}
          p -> {:halt, p ++ path}
        end
    end
  end

  def put_schs({_pre, _post, map}, _path, []), do: {nil, nil, map}
  def put_schs(map, _path, []), do: {nil, nil, map}

  def put_schs({_pre, _post, map}, path, raw_schs), do: put_schs(map, path, raw_schs)

  def put_schs(map, path, raw_schs)
      when is_map(map) and is_binary(path) and is_list(raw_schs) do
    parent_path = access_path(path)

    {pre, new_map} = get_and_update_in(map, parent_path, &{&1, put_schs(&1, raw_schs)})
    {pre, _post = get(new_map, path), new_map}
  end

  defp put_schs(%{@type_ => @object} = parent, raw_schs) do
    props = Map.new(raw_schs, fn %{key: key, sch: sch} when not is_nil(key) -> {key, sch} end)

    parent
    |> Map.update(@properties, props, fn p -> Map.merge(p, props) end)
    |> Map.update!(@props_order, fn order ->
      reindex(raw_schs, order)
      |> Enum.map(fn
        %{key: k} -> k
        {k, _i} -> k
      end)
      |> Enum.uniq()
    end)
  end

  defp put_schs(%{@type_ => @array, @items => item} = parent, raw_schs) do
    schs = Enum.map(raw_schs, fn sch -> sch[:sch] end)

    case {schs, item} do
      {[sch], item} when item == %{} ->
        Map.put(parent, @items, sch)

      {_schs, items} when is_map(items) or is_list(items) ->
        items = List.wrap(items)

        Map.update!(parent, @items, fn _ ->
          reindex(raw_schs, items)
          |> Enum.map(fn
            %{sch: sch} -> sch
            {sch, _i} -> sch
          end)
        end)
    end
  end

  defp put_schs(%{@any_of => any_of_schs} = parent, raw_schs) when is_list(any_of_schs) do
    Map.update!(parent, @any_of, fn _ ->
      reindex(raw_schs, any_of_schs)
      |> Enum.map(fn
        %{sch: sch} -> sch
        {sch, _i} -> sch
      end)
    end)
  end

  # New schs come as raw_schs that contain an index for each. `reindex/2` sort
  # those schs combined with existing ones in a container responsible for its ordering.
  # And returns sorted items in raw form (contain indices).
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

  # This only works with path style produced by Plug.Conn.Query
  def find_parents(paths) when is_list(paths) or is_binary(paths) do
    paths
    |> List.wrap()
    |> Enum.map(fn path -> find_parent(path) end)
    |> Enum.group_by(& &1.path, & &1.child_key)
  end

  def find_parent(path) when is_binary(path) do
    case path_tokens = split_path(path) do
      [] ->
        %{path: path, child_key: nil}

      [p] ->
        %{path: p, child_key: nil}

      _ ->
        [leaf | parent] = Enum.reverse(path_tokens)
        [root | rest] = Enum.reverse(parent)

        parent =
          for a <- rest, reduce: root do
            acc ->
              path =
                case Integer.parse(a) do
                  :error -> "[" <> a <> "]"
                  _ -> "[]" <> "[" <> a <> "]"
                end

              acc <> path
          end

        %{path: parent, child_key: leaf}
    end
  end

  def split_path(path) when is_binary(path) do
    String.split(path, :binary.compile_pattern(["[", "][", "]"]), trim: true)
  end

  def split_fragment_path("#/" <> @definitions <> path) do
    split_fragment_path("#/" <> @defs <> path)
  end

  def split_fragment_path("#/" <> @defs <> "" <> path) do
    String.split(path, :binary.compile_pattern(["/"]), trim: true) |> List.last()
  end

  def split_fragment_path(_), do: nil

  # defp find_root(path) when is_binary(path) do
  #   hd(split_path(path))
  # end

  # pop_schs/3 intends to work with path that points to container type such as object or array.
  # If a given path points to a leaf, it will find its parent and pop the leaf.
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

  defp pop_schs(%{@type_ => @object} = parent, keys) do
    keys =
      Enum.map(keys, fn
        k when is_binary(k) -> k
        i when is_integer(i) -> Enum.at(order(parent), i)
      end)

    {popped, remained} =
      parent
      |> Map.get(@properties, %{})
      |> Enum.split_with(fn {prop, _} -> prop in keys end)

    map_ =
      parent
      |> Map.put(@properties, Map.new(remained))
      |> Map.update(@props_order, Keyword.keys(remained), fn order ->
        order -- Keyword.keys(popped)
      end)

    {popped, map_}
  end

  defp pop_schs(%{@type_ => @array, @items => item} = _parent, _indices) when item == %{} do
    raise "cannot pop an empty schema"
  end

  defp pop_schs(%{@type_ => @array, @items => item} = parent, _indices) when is_map(item) do
    {popped, _remained} = Map.pop!(parent, @items)
    map_ = Map.put(parent, @items, %{})
    popped = [{0, popped}]

    {popped, map_}
  end

  defp pop_schs(%{@type_ => @array, @items => items} = parent, indices) when is_list(items) do
    integer_indices =
      Enum.map(indices, fn
        i when is_binary(i) -> String.to_integer(i)
        i when is_integer(i) -> i
        i -> raise "#{i} index must be integer"
      end)

    {popped, remained} =
      parent
      |> Map.get(@items)
      |> Enum.with_index()
      |> Enum.split_with(fn {_, i} -> i in integer_indices end)

    map_ =
      parent
      |> Map.update!(@items, fn _ -> Keyword.keys(remained) end)
      |> Map.update!(@items, fn
        [] -> %{}
        [item] when item == %{} -> [%{}]
        [item] -> item
        items -> items
      end)

    popped = Enum.map(popped, fn {sch, i} -> {i, sch} end)

    {popped, map_}
  end

  defp pop_schs(%{@any_of => any_of_schs} = parent, indices) when is_list(any_of_schs) do
    integer_indices =
      Enum.map(indices, fn
        i when is_binary(i) -> String.to_integer(i)
        i when is_integer(i) -> i
        i -> raise "#{i} index must be integer"
      end)

    {popped, remained} =
      parent
      |> Map.get(@any_of)
      |> Enum.with_index()
      |> Enum.split_with(fn {_, i} -> i in integer_indices end)

    map_ =
      parent
      |> Map.update!(@any_of, fn _ -> Keyword.keys(remained) end)
      |> Map.update!(@any_of, fn
        [] -> [%{}]
        schs -> schs
      end)

    popped = Enum.map(popped, fn {sch, i} -> {i, sch} end)

    {popped, map_}
  end

  defp pop_schs(_, _), do: nil

  def ensure_props_order(object) do
    props = Map.keys(Map.get(object, @properties, %{}))
    object = Map.put_new(object, @props_order, props)
    props_order = Map.get(object, @props_order)

    if Enum.count(props) != Enum.count(props_order) do
      Map.update!(object, @props_order, fn order -> Enum.uniq(order ++ props) end)
    else
      object
    end
  end

  def replace(map, path, sch) when is_map(sch) do
    update_in(map, access_path(path), fn _ -> sch end)
  end

  def update(map, path, key, val) when is_binary(key) do
    cond do
      key in [@title, @description, @id] and is_binary(val) ->
        {pre, new_map} =
          get_and_update_in(map, access_path(path), fn parent ->
            {parent, Map.put(parent, key, val)}
          end)

        {pre, _post = get(new_map, path), new_map}

      key == @required ->
        parent = find_parent(path)

        {pre, new_map} =
          get_and_update_in(map, access_path(parent.path), fn
            %{@type_ => @object} = object ->
              {object,
               cond do
                 # Previous value is false
                 val in ["false"] ->
                   Map.update(object, key, [], fn required ->
                     Enum.uniq([parent.child_key | required])
                   end)

                 # Previous value is true (unchecked input have no value set; i.e. nil)
                 val in [nil] ->
                   Map.update(object, key, [], fn required ->
                     List.delete(required, parent.child_key)
                   end)

                 true ->
                   object
               end}

            object ->
              {object, object}
          end)

        {pre, _post = get(new_map, parent.path), new_map}

      is_binary(key) ->
        {pre, new_map} =
          get_and_update_in(map, access_path(path), fn parent ->
            {parent, update(parent, key, val)}
          end)

        {pre, _post = get(new_map, path), new_map}

      true ->
        {nil, nil, map}
    end
  end

  def merge(map1, map2) when is_map(map1) and is_map(map2) do
    map2
  end

  defp positive_int_keys() do
    object = [@max_properties, @min_properties]
    array = [@max_items, @min_items]
    string = [@max_length, @min_length]
    number = [@maximum, @minimum, @multiple_of]
    object ++ array ++ string ++ number
  end

  defp update(%{@type_ => @object} = parent, key, val) do
    val = if key in positive_int_keys(), do: positive_int(val), else: val

    cond do
      key in [@max_properties, @min_properties] && val ->
        Map.put(parent, key, val)

      true ->
        parent
    end
  end

  defp update(%{@type_ => @array} = parent, key, val) do
    val = if key in positive_int_keys(), do: positive_int(val), else: val

    cond do
      key in ~w(maxItems minItems) && val ->
        Map.put(parent, key, val)

      true ->
        parent
    end
  end

  defp update(%{@type_ => @string} = sch, key, val) do
    cond do
      key in [@max_length, @min_length] ->
        val = positive_int(val)
        sch = Map.put(sch, key, val)
        min = Map.get(sch, @min_length)
        max = Map.get(sch, @max_length)

        case {min, max} do
          {nil, nil} ->
            sch
            |> Map.delete(@min_length)
            |> Map.delete(@max_length)

          {min, nil} ->
            sch
            |> Map.put(@min_length, min)
            |> Map.delete(@max_length)

          {nil, max} ->
            sch
            |> Map.delete(@min_length)
            |> Map.put(@max_length, max)

          {min, max} when min <= max ->
            sch
            |> Map.put(@min_length, min)
            |> Map.put(@max_length, max)

          {min, max} when min > max ->
            sch
            |> Map.put(@min_length, max)
            |> Map.put(@max_length, max)
        end

      key in [@pattern] && is_binary(val) ->
        val = String.trim(val)

        case Regex.compile(val) do
          {:ok, _regex} -> Map.put(sch, key, val)
          {:error, _error} -> Map.delete(sch, key)
        end

      true ->
        sch
    end
  end

  defp update(%{@type_ => @number} = parent, key, val) do
    val = if key in positive_int_keys(), do: positive_int(val), else: val

    cond do
      key in ~w(maximum minimum multipleOf) && val ->
        Map.put(parent, key, val)

      true ->
        parent
    end
  end

  defp update(%{@type_ => _} = parent, _key, _val), do: parent

  defp update(%{@const => _} = parent, _key, val) do
    case Jason.decode(val) do
      {:ok, val} -> Map.put(parent, @const, val)
      _ -> parent
    end
  end

  defp positive_int(val) when is_binary(val) do
    if String.match?(val, ~r/\d+/), do: max(0, String.to_integer(val)), else: nil
  end

  defp positive_int(val), do: val

  defp access_list(index) do
    fn
      ops, %{@type_ => @array, @items => item} = data, next when is_map(item) ->
        Access.key!(@items).(ops, data, next)

      ops, %{@type_ => @array, @items => items} = data, next when is_list(items) ->
        next = fn items_ -> Access.at(String.to_integer(index)).(ops, items_, next) end
        Access.key!(@items).(ops, data, next)

      ops, %{@any_of => any_of_schs} = data, next when is_list(any_of_schs) ->
        next = fn any_of_schs_ ->
          Access.at(String.to_integer(index)).(ops, any_of_schs_, next)
        end

        Access.key!(@any_of).(ops, data, next)

      _ops, _data, next ->
        next.(nil)
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
        access_path(v) ++ [k | [Access.key(@properties, %{}) | acc]]

      %{} = map, acc ->
        [{index, v}] = Map.to_list(map)
        access_path(v) ++ [access_list(index) | acc]
    end)
  end

  def walk_container(map, fun) when is_map(map) and is_function(fun) do
    case map do
      %{@type_ => @object, @properties => properties} ->
        for {k, sch} <- properties, reduce: map do
          acc ->
            acc
            |> Map.update(@properties, %{}, fn props ->
              Map.put(props, k, walk_container(sch, fun))
            end)
        end

      %{@type_ => @object, @patternProperties => pattern_roperties} ->
        for {k, sch} <- pattern_roperties, reduce: map do
          acc ->
            acc
            |> Map.update(@patternProperties, %{}, fn props ->
              Map.put(props, k, walk_container(sch, fun))
            end)
        end

      %{@type_ => @array} ->
        items =
          case items(map) do
            item when is_map(item) ->
              walk_container(item, fun)

            items when is_list(items) ->
              for {sch, _i} <- Enum.with_index(items), do: walk_container(sch, fun)
          end

        Map.put(map, @items, items)

      %{@any_of => schs} ->
        schs = for {sch, _i} <- Enum.with_index(schs), do: walk_container(sch, fun)
        Map.put(map, @any_of, schs)

      _ ->
        map
    end
    |> fun.()
  end

  # Helpers

  def sanitize(map) when is_map(map) do
    map
    |> walk_container(fn sch ->
      sch

      #   |> Fset.Sch.Migrator.compute_examples()
      #   |> Fset.Sch.Migrator.remove_id()
      #   |> Fset.Sch.Migrator.add_anchor()
      #   |> Fset.Sch.Migrator.correct_ref()
    end)
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
