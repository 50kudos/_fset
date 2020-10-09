defmodule Fset.Module do
  alias Fset.Module.Encode
  alias Fset.Utils
  alias Fset.Sch
  alias Fset.Sch.New

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
      name: "main",
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

  def changable_types do
    ~w(record list tuple string bool number null union value)
  end

  def change_type(root, path, type) do
    to_type =
      case type do
        "record" -> New.object()
        "list" -> New.array(:homo)
        "tuple" -> New.array(:hetero)
        "string" -> New.string()
        "bool" -> New.boolean()
        "number" -> New.number()
        "null" -> New.null()
        "union" -> New.any_of([New.object(), New.array(), New.string()])
        "value" -> New.const()
        {:ref, anchor} -> Sch.New.ref(anchor)
      end

    Sch.change_type(root, path, to_type)
  end

  def add_model(root, path, model) do
    add_field(root, path, model, anchor_prefix: "model")
  end

  def add_field(root, path, model, opts \\ []) do
    opts = Keyword.take(opts, [:anchor_prefix])

    model =
      case model do
        "Record" -> New.object(opts)
        "Field" -> New.string(opts)
        "List" -> New.array(:homo, opts)
        "Tuple" -> New.array(:hetero, opts)
        "Union" -> New.any_of([New.object(), New.array(), New.string()], opts)
      end

    Sch.put(root, path, Utils.gen_key(), model, 0)
  end

  def rename_key(%_{schema: root} = file, path, old_key, new_key) do
    %{file | schema: Sch.rename_key(root, path, old_key, new_key)}
  end
end
