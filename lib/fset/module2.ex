defmodule Fset.Module2 do
  alias Fset.Module2.Encode
  alias Fset.Utils

  def encode(map, opts \\ []) do
    Encode.from_json_schema(map, opts)
  end

  def to_files(%{main_sch: main, model_schs: models}) when is_map(main) and is_list(models) do
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
end
