defmodule Fset.Module.Encode do
  alias Fset.Sch

  @defs_chunk_size 100

  def from_json_schema(sch, opts \\ []) do
    {defs, main} = Sch.pop_defs(sch)

    model_schs =
      for defs_chuck <- chunk_defs(defs, opts[:defs_per_file]) do
        raw_schs =
          defs_chuck
          |> Enum.with_index()
          |> Enum.map(fn {{key, sch}, i} -> %{key: key, sch: sch, index: i} end)

        "temp_root"
        |> Sch.new(Sch.New.object())
        |> Sch.put_schs("temp_root", raw_schs)
        |> Sch.get("temp_root")
      end

    [main | model_schs] = resolve_ref_to_anchor(main: main, model: model_schs)

    %{main_sch: main, model_schs: model_schs}
  end

  defp chunk_defs(nil, _), do: []

  defp chunk_defs(defs, chunk_size) do
    defs
    |> Enum.sort_by(fn {key, _sch} -> key end)
    |> Enum.chunk_every(chunk_size || @defs_chunk_size)
    |> Enum.map(fn defs_chuck ->
      Enum.map(defs_chuck, fn {def, sch} -> {def, encode(sch)} end)
    end)
  end

  defp encode(map, acc \\ %{})

  defp encode(map, _acc) do
    map
    |> Sch.New.put_anchor(prefix: "model")
    |> Sch.walk_container(fn sch ->
      cond do
        Sch.object?(sch) -> Sch.ensure_props_order(sch)
        Sch.enum?(sch) -> Sch.enum_to_union_value(sch)
        Sch.leaf?(sch, :multi) -> Sch.expand_multi_types(sch)
        true -> sch
      end
    end)
  end

  defp resolve_ref_to_anchor(schs) do
    models_anchors = models_anchors(schs[:model])
    schs = [schs[:main] | schs[:model]]

    for file_sch <- schs do
      Sch.walk_container(file_sch, fn sch ->
        cond do
          Sch.ref?(sch) -> ref_to_anchor(sch, models_anchors)
          true -> sch
        end
      end)
    end
  end

  defp models_anchors(model_schs) do
    Enum.flat_map(model_schs, fn model_sch ->
      Enum.map(Sch.properties(model_sch), fn {model_name, sch} ->
        {model_name, Sch.anchor(sch)}
      end)
    end)
  end

  defp ref_to_anchor(sch, models_anchors) do
    ref_ = Sch.ref(sch)

    with model_name <- Sch.split_fragment_path(ref_),
         {_model, anchor} <- Enum.find(models_anchors, fn {model, _a} -> model == model_name end) do
      Sch.New.put_ref(sch, "#" <> anchor)
    else
      _ -> sch
    end
  end
end
