defmodule Fset.Sch.Migrator do
  # alias Fset.Sch

  def add_id(sch) when is_map(sch) do
    Map.put_new(sch, "$id", "urn:uuid:" <> Ecto.UUID.generate())
  end

  def remove_id(sch) when is_map(sch) do
    Map.delete(sch, "$id")
  end

  def add_anchor(sch) when is_map(sch) do
    Map.put_new(sch, "$anchor", "a_" <> Ecto.UUID.generate())
  end

  def correct_ref(sch) when is_map(sch) do
    case sch do
      %{"$ref" => _} = sch -> Map.take(sch, ["$ref"])
      sch -> sch
    end
  end

  def rename_key(sch, keys_change) when is_map(sch) and is_list(keys_change) do
    for {from, to} <- keys_change, reduce: sch do
      acc -> Map.put_new(acc, to, Map.get(sch, from))
    end
  end
end
