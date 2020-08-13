defmodule Fset.Sch.Migrator do
  alias Fset.Sch

  def add_id(map) when is_map(map) do
    Sch.walk_container(map, fn sch ->
      Map.put_new(sch, "$id", "urn:uuid:" <> Ecto.UUID.generate())
    end)
  end

  def remove_id(map) when is_map(map) do
    Sch.walk_container(map, fn sch ->
      Map.delete(sch, "$id")
    end)
  end

  def add_anchor(map) when is_map(map) do
    Sch.walk_container(map, fn sch ->
      Map.put_new(sch, "$anchor", "a_" <> Ecto.UUID.generate())
    end)
  end

  def correct_ref(map) when is_map(map) do
    Sch.walk_container(map, fn
      %{"$ref" => _} = sch -> Map.take(sch, ["$ref"])
      sch -> sch
    end)
  end

  def rename_key(map, keys_change) when is_map(map) and is_list(keys_change) do
    Sch.walk_container(map, fn sch ->
      for {from, to} <- keys_change, reduce: sch do
        acc -> Map.put_new(acc, to, Map.get(sch, from))
      end
    end)
  end
end
