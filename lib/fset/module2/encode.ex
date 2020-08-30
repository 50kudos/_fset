defmodule Fset.Module2.Encode do
  alias Fset.Sch

  @defs_chunk_size 100

  def from_json_schema(sch, opts \\ []) do
    {defs, main} = Sch.pop_defs(sch)

    model_schs =
      for defs_chuck <- chunk_defs(defs, opts[:defs_per_file]) do
        Sch.put_defs(%{}, defs_chuck)
      end

    %{main: main, model_schs: model_schs}
  end

  defp chunk_defs(nil, _), do: []

  defp chunk_defs(defs, chunk_size) do
    defs
    |> Enum.chunk_every(chunk_size || @defs_chunk_size)
    |> Enum.map(fn defs_chuck ->
      Enum.reduce(defs_chuck, %{}, fn {def, sch}, acc ->
        Map.put(acc, def, encode(sch))
      end)
    end)
  end

  defp encode(sch, acc \\ %{})

  defp encode(sch, _acc) do
    sch
  end
end