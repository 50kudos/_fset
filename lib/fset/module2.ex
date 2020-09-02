defmodule Fset.Module2 do
  alias Fset.Module2.Encode
  alias Fset.Utils

  @moduledoc """
  Deals with schema level data and is independent from database layer.
  Data comes from outside worlds, either from imported files or database.
  But the data has to be already a map.
  """

  def encode(map, opts \\ []) do
    Encode.from_json_schema(map, opts)
  end

  @doc """
  Map schs into ready-to-persist format. And may have responsibilty at schema level
  to transform schema before output the format.
  """
  def to_files(%{main_sch: main, model_schs: models}, _opts \\ [])
      when is_map(main) and is_list(models) do
    main_file = %{
      name: Utils.gen_key("main"),
      type: :main,
      schema: main
    }

    model_files =
      Enum.map(models, fn model ->
        %{
          name: Utils.gen_key("model"),
          type: :model,
          schema: model
        }
      end)

    [main_file | model_files]
  end

  def from_files(files) when is_list(files) do
    {[main], models} = Enum.split_with(files, fn f -> f.type == :main end)

    %{main_sch: main, model_schs: models}
  end
end
