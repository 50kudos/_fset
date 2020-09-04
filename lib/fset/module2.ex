defmodule Fset.Module2 do
  alias Fset.Module2.Encode
  alias Fset.Utils
  alias Fset.Sch

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
  def init_files(%{main_sch: main, model_schs: models}, _opts \\ [])
      when is_map(main) and is_list(models) do
    main_file_id = Ecto.UUID.generate()

    main_file = %{
      id: main_file_id,
      name: Utils.gen_key("main"),
      type: :main,
      schema: Sch.new(main_file_id, main)
    }

    model_files =
      Enum.map(models, fn model ->
        model_file_id = Ecto.UUID.generate()

        %{
          id: model_file_id,
          name: Utils.gen_key("model"),
          type: :model,
          schema: Sch.new(model_file_id, model)
        }
      end)

    [main_file | model_files]
  end

  def from_files(files) when is_list(files) do
    {[main], models} = Enum.split_with(files, fn f -> f.type == :main end)

    %{main_sch: main, model_schs: models}
  end

  def change_type(%_{schema: root} = file, path, type) do
    to_type =
      case type do
        "record" -> Sch.New.object()
        "list" -> Sch.New.array(:homo)
        "tuple" -> Sch.New.array(:hetero)
        "string" -> Sch.New.string()
        "bool" -> Sch.New.boolean()
        "number" -> Sch.New.number()
        "null" -> Sch.New.null()
        "union" -> Sch.New.any_of([Sch.New.object(), Sch.New.array(), Sch.New.string()])
        "value" -> Sch.New.const()
      end

    %{file | schema: Sch.change_type(root, path, to_type)}
  end
end
