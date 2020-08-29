defmodule Fset.Module do
  use Fset.Module.Vocab

  alias Fset.Sch
  alias Fset.Sch.New
  alias Fset.Module.Encode

  @moduledoc """
    File is only a thin layer on top of Fset.Sch module. It's an opinioned scheme
    used to manage schema modularity.

    By resuing Fset.Sch "root" concept applied to,
    For example __MODEL__, it's a definition at first, not a schema, it can't utilize
    Fset.Sch module's functions until we Sch.new(__MODEL__, model_sch) it, meaning wraping
    model schema with __MODEL__ root, then it's treated as plain schema
    (i.e. __MODEL__ is now an object typed schema)

    Therefore, file body can be manipulated by Fset.Sch module. In future, this module
    will fully encapsulate the underline schema when abstraction is obvious.

    File body structure is:
    {
      "$id": "domain/namespace/file",
      "$defs": {
        "__MODEL__": { $anchor: "MODEL", "type": "object" },
        "__VAR__": { "type": "object" },
        "__LOGIC__": { $anchor: "LOGIC", "type": "object" },
        "__MAIN__": { $anchor: "MAIN" }
      },
      "allOf": [{"$ref": "#MAIN"}, {"$ref": "#LOGIC"}]
    }

    1. We call the root schema a file "body". (file variable in this module means file body)
    2. __MODEL__ is where you define type (models) where no logics involved here.
    3. __VAR__ is like a local scope for declaring ad-hoc shape of schema that will be
      used in __LOGIC__ definition.
    4. __LOGIC__ is where all inter-model conditions happen.
      This keyword only allows logical operation (and, or, xor). Operands must be
      in form of $ref to things under __VAR__ definition.
    5. These anchors are unique with $id as a base URI

    ## Reasoning
    __MODEL__, __LOGIC__, and __VAR__ are always object type. We could put things under
    $defs inside these two keywords, but decide not to because we do not threat the keywords
    as kind of definition. They are themselves schemas.

    Each property of these special definition will have $anchor keyword that referer in other place

    __MAIN__ is an entry schema. Allow to wrap models with any type (record, list, tuple, union)
    It's like __MODEL__ but with a root wrapper. There must be a root here unlike __MODEL__ that
    contains many definitions without root because there is no need for an entry point for definitions.

    Why not unwraping __MAIN__ into "body"?
    Because we want __LOGIC__ and __MAIN__ to be their own namespace, open opportunity of reuse
    with or without each other.

    $anchor works like export in module system. Whatever we want to expose, we give it $anchor.
    It is also used as local reference.
  """

  def preserve_keys(), do: [@model_key, @main_key, @logic_key, @var_key]

  def new_sch(module \\ %{}) do
    module
    |> Map.merge(New.all_of([New.ref(@main_anchor), New.ref(@logic_anchor)]))
    |> Sch.put_def(@model_key, New.object(anchor: @model_anchor))
    |> Sch.put_def(@main_key, New.anchor(@main_anchor))
    |> Sch.put_def(@logic_key, New.anchor(@logic_anchor))
    |> Sch.put_def(@var_key, %{})
  end

  def encode_sch(sch), do: Encode.from_json_schema(sch)

  # def locator(namespace, filename, domain \\ "https://fsetapp.com") do
  #   Path.join([domain, namespace, filename])
  # end

  # """
  # Give a file body.
  # Turn __MODEL__ definition into a __MODEL__ schema as object type.
  # Meaning that this model will have __MODEL__ as its root, and can be accessed by
  # "__MODEL__[prop]" path

  # ## Examples

  #   iex> model_section(%{})
  #   %{"type": "object", "properties": %{"__MODEL__" => %{}}}

  # """
  defp defs_section(root_sch, section_key) when is_map(root_sch) and is_binary(section_key) do
    section_sch = Map.get(Sch.defs(root_sch), section_key)

    section_sch =
      case section_key do
        @model_key -> Map.merge(New.object(), section_sch)
        @main_key -> section_sch
      end

    Sch.new(section_key, section_sch)
  end

  def from_schema(sch) when is_map(sch) do
    %{
      model: defs_section(sch, @model_key),
      main: defs_section(sch, @main_key),
      current_section: which_section(@model_key),
      current_section_key: @model_key
    }
  end

  def current_section(%{current_section: s} = module), do: module[s]

  def current_section_sch(module, path \\ nil) do
    module
    |> current_section()
    |> Sch.get(path || module.current_section_key)
  end

  def update_current_section(%{current_section: s} = module, fun) when is_function(fun) do
    Map.update!(module, s, fun)
  end

  defp unwrap(name, sch) do
    if sch_ = Sch.get(sch, name), do: unwrap(name, sch_), else: sch
  end

  def to_schema(%{main: main, model: model}) do
    main = unwrap(@main_key, main)
    model = unwrap(@model_key, model)

    new_sch()
    |> Sch.put_def(@model_key, model)
    |> Sch.put_def(@main_key, main)
  end

  def which_section(@main_key), do: :main
  def which_section(@model_key), do: :model

  def put_model(module_sch, defs_props) when is_map(defs_props) do
    module = from_schema(module_sch)

    module =
      update_current_section(module, fn section_sch ->
        for {k, sch} <- defs_props, reduce: section_sch do
          acc -> Sch.put(acc, @model_key, k, sch, -1)
        end
      end)

    to_schema(module)
  end

  def add_model_fun(model, path) do
    case model do
      "Record" ->
        fn sch -> Sch.put(sch, path, Sch.gen_key(), New.object(anchor_prefix: "model"), 0) end

      "Field" ->
        fn sch -> Sch.put(sch, path, Sch.gen_key(), New.string(anchor_prefix: "model"), 0) end

      "List" ->
        fn sch ->
          Sch.put(sch, path, Sch.gen_key(), New.array(:homo, anchor_prefix: "model"), 0)
        end

      "Tuple" ->
        fn sch ->
          Sch.put(sch, path, Sch.gen_key(), New.array(:hetero, anchor_prefix: "model"), 0)
        end

      "Union" ->
        union = New.any_of([New.object(), New.array(), New.string()], anchor_prefix: "model")
        fn sch -> Sch.put(sch, path, Sch.gen_key(), union, 0) end

      _ ->
        fn a -> a end
    end
  end

  defp change_type_fun_table(path) do
    [
      {"record", fn sch -> Sch.change_type(sch, path, New.object()) end},
      {"list", fn sch -> Sch.change_type(sch, path, New.array(:homo)) end},
      {"tuple", fn sch -> Sch.change_type(sch, path, New.array(:hetero)) end},
      {"string", fn sch -> Sch.change_type(sch, path, New.string()) end},
      {"bool", fn sch -> Sch.change_type(sch, path, New.boolean()) end},
      {"number", fn sch -> Sch.change_type(sch, path, New.number()) end},
      {"null", fn sch -> Sch.change_type(sch, path, New.null()) end},
      {"union",
       fn sch ->
         Sch.change_type(sch, path, New.any_of([New.object(), New.array(), New.string()]))
       end},
      {"value", fn sch -> Sch.change_type(sch, path, New.const()) end}
    ]
  end

  def changable_types() do
    Enum.map(change_type_fun_table(""), fn {k, _} -> k end)
  end

  def change_type_fun(type, path) do
    path
    |> change_type_fun_table()
    |> List.keyfind(type, 0, fn a -> a end)
    |> elem(1)
  end

  # Sch path requires a root properties to operate on its ("root" path) schema.
  # In order to rename the root key, we wrap it in a temp root, change key, and
  # unwrap it.
  # def rename(file, old_name, new_name) do
  #   wraper_key = "temp_wrapper"
  #   wrapper = Sch.new(wraper_key)
  #   wrapped_file = Sch.put(wrapper, wraper_key, old_name, Sch.get(file.schema, old_name))

  #   wrapped_file = Sch.rename_key(wrapped_file, wraper_key, old_name, new_name)
  #   _unwrapped_file = Sch.get(wrapped_file, wraper_key)
  # end
end
