defmodule Fset.Sch.Migrator do
  alias Fset.Sch
  use Fset.Sch.Vocab

  def add_id(sch) when is_map(sch) do
    Map.put_new(sch, @id, "urn:uuid:" <> Ecto.UUID.generate())
  end

  def remove_id(sch) when is_map(sch) do
    Map.delete(sch, @id)
  end

  def add_anchor(sch) when is_map(sch) do
    Map.put_new(sch, @anchor, "a_" <> Ecto.UUID.generate())
  end

  def correct_ref(sch) when is_map(sch) do
    case sch do
      %{@ref => _} = sch -> Map.take(sch, [@ref])
      sch -> sch
    end
  end

  def rename_key(sch, keys_change) when is_map(sch) and is_list(keys_change) do
    for {from, to} <- keys_change, reduce: sch do
      acc -> Map.put_new(acc, to, Map.get(sch, from))
    end
  end

  def compute_examples(sch) when is_map(sch) do
    cond do
      Sch.object?(sch, :empty) ->
        Map.put(sch, @examples, [%{}])

      Sch.object?(sch) ->
        example =
          for {k, sch_} <- Sch.properties(sch), reduce: %{} do
            acc -> Map.put(acc, k, Sch.example(sch_))
          end

        Map.put(sch, @examples, [example])

      Sch.array?(sch, :homo) ->
        item = Sch.items(sch)
        Map.put(sch, @examples, [[Sch.example(item)]])

      Sch.array?(sch, :hetero) ->
        items = Sch.items(sch)
        Map.put(sch, @examples, [Enum.map(items, &Sch.example/1)])

      Sch.any_of?(sch) ->
        [one] = Enum.take_random(Sch.any_of(sch), 1)
        Map.put(sch, @examples, [Sch.example(one)])

      Sch.leaf?(sch) ->
        cond do
          Sch.string?(sch) ->
            min = Map.get(sch, @min_length, 0)
            max = Map.get(sch, @max_length, 500)
            string_data = StreamData.string(:alphanumeric, length: min..max)
            Map.put(sch, @examples, Enum.take(string_data, 3))

          Sch.number?(sch) ->
            min = Map.get(sch, @minimum, 0)
            max = Map.get(sch, @maximum, 500)
            # multiple_of = Map.get(sch, @multiple_of, 1)
            float_data = StreamData.float(min: min, max: max)
            Map.put(sch, @examples, Enum.take(float_data, 3))

          Sch.boolean?(sch) ->
            Map.put(sch, @examples, [true, false])

          Sch.null?(sch) ->
            Map.put(sch, @examples, [nil])
        end

      Sch.any?(sch) ->
        Map.put(sch, @examples, ["any"])

      Sch.ref?(sch) ->
        Map.put(sch, @examples, [Sch.ref(sch)])

      Sch.const?(sch) ->
        Map.put(sch, @examples, [Sch.const(sch)])
    end
  end
end
