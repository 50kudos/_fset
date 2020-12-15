defmodule Fset.Main do
  @moduledoc """
  Main Fset application works on highest level closed to web framework such as
  Liveview event handler. And only manage inputs from boundary, feed into a blackbox
  layer, then manage output to be returned.

  It also depend on applications started under main supervision tree such as
  Fset.PubSub and FsetWeb.Presence
  """
  @file_topic "module_update:"

  alias Fset.{Accounts, Project, Module, Sch, Utils}
  alias FsetWeb.Presence

  def init_data(params) do
    with project <- get_project(params["project_name"]),
         [main | _] = files <- get_project_meta(project),
         user <- Accounts.get_user_by_username!(params["username"]),
         file_id <- params["file_id"] || main.id do
      %{}
      |> Map.put(:project_name, project.name)
      |> Map.put(:project, project)
      |> Map.put(:current_user, user)
      |> Map.put(:current_path, [file_id])
      |> Map.put(:files, files)
      |> Map.put(:pinned_file_ids, Enum.map(files, & &1.id))
      |> Map.put(:ui, %{errors: [], topic: @file_topic <> file_id, user_id: user.id})
    end
  end

  def change_file_data(assigns, params) do
    with file_id <- params["file_id"],
         current_file <- get_current_file(assigns.project, file_id),
         {models_bodies, height} <- models_bodies(current_file) do
      %{}
      |> Map.put(:current_file, current_file)
      |> Map.put(:current_path, [current_file.id])
      |> Map.put(:current_models_bodies, models_bodies)
      |> Map.put(:ui, Map.put(assigns.ui, :module_container_height, height))
    end
  end

  @doc """
  Add a sch to a container sch such as object, array or union.
  """
  def add_field(assigns, %{"field" => field, "path" => add_path}) do
    schema = Sch.new("temp_parent", assigns.sch)
    {_pre, postsch, _new_schema} = Module.add_field(schema, "temp_parent", field)

    # Note: if we decide to move renderer to frontend, change the handle_info
    # from calling send_update to push_event with same parameters for client to patch
    # the DOM.
    @file_topic <> file_id = assigns.ui.topic
    push_current_path(add_path)
    broadcast_update_sch(%{id: file_id}, add_path, postsch)

    Map.put(%{}, :sch, postsch)
  end

  def add_model(assigns, %{"model" => model}) do
    file = assigns.current_file
    add_path = file.id

    {_pre, postsch, new_schema} = Module.add_model(file.schema, add_path, model)

    [added_key | _] = Sch.order(postsch)
    added_sch = Sch.get(postsch, added_key)

    broadcast_update_sch(file, add_path, postsch)

    files =
      Enum.map(assigns.files, fn
        %{id: ^add_path} = f ->
          %{f | models_anchors: [{added_key, added_sch} | f.models_anchors]}

        f ->
          f
      end)

    %{}
    |> Map.put(:current_file, %{file | schema: new_schema})
    |> Map.put(:files, files)
  end

  def change_type(assigns, %{"value" => type, "path" => path}) do
    file = assigns.current_file
    models_anchors = models_anchors(assigns.files)

    new_schema =
      cond do
        type in Module.changable_types() ->
          {_pre, postsch, new_schema} = Module.change_type(file.schema, path, type)
          broadcast_update_sch(file, path, postsch)
          new_schema

        {_m, anchor} = Enum.find(models_anchors, fn {m, _a} -> m == type end) ->
          {_pre, postsch, new_schema} = Module.change_type(file.schema, path, {:ref, anchor})
          broadcast_update_sch(file, path, postsch)
          new_schema

        true ->
          file.schema
      end

    new_file = %{file | schema: new_schema}
    {models_bodies, _} = models_bodies(new_file)

    %{}
    |> Map.put(:current_file, new_file)
    |> Map.put(:current_models_bodies, models_bodies)
  end

  def update_sch(assigns, %{"key" => key, "path" => sch_path} = params) do
    value = Map.get(params, "value")
    file = assigns.current_file

    {_pre, postsch, new_schema} = Sch.update(file.schema, sch_path, key, value)
    broadcast_update_sch(file, sch_path, postsch)

    Map.put(%{}, :current_file, %{file | schema: new_schema})
  end

  def rename_key(assigns, %{
        "parent_path" => parent_path,
        "old_key" => old_key,
        "value" => new_key
      }) do
    # String max length < 255
    old_key = String.slice(old_key, 0, min(255, String.length(old_key)))
    new_key = String.slice(new_key, 0, min(255, String.length(new_key)))

    user = assigns.current_user
    file = assigns.current_file
    {_pre, postsch, new_schema} = Sch.rename_key(file.schema, parent_path, old_key, new_key)

    new_key = if new_key == "", do: old_key, else: new_key
    new_path = parent_path <> "[" <> new_key <> "]"
    broadcast_update_sch(file, parent_path, postsch)
    track_user_update(user, file, current_path: new_path)

    %{}
    |> Map.put(:current_file, %{file | schema: new_schema})
    |> Map.put(:current_path, List.wrap(new_path))
  end

  def move(assigns, %{"oldIndices" => src_indices, "newIndices" => dst_indices}) do
    user = assigns.current_user
    file = assigns.current_file

    {moved_paths, new_schema} = Sch.move(file.schema, src_indices, dst_indices)
    file = %{file | schema: new_schema}
    {models_bodies, _} = models_bodies(file)

    return_assigns =
      %{}
      |> Map.put(:current_file, file)
      |> Map.put(:current_path, moved_paths)
      |> Map.put(:current_models_bodies, models_bodies)

    track_user_update(user, file, current_path: Utils.unwrap(moved_paths))

    case file.type do
      :model ->
        keyed_model_schs = Map.get(return_assigns, :current_models_bodies)
        pathed_models = models_target(file.id, src_indices, dst_indices, keyed_model_schs)

        for {model_path, model_sch} <- pathed_models do
          broadcast_update_sch(file, model_path, model_sch)
        end

      :main ->
        broadcast_update_sch(file, file.id, Sch.get(file.schema, file.id))
    end

    push_current_path(moved_paths)
    return_assigns
  end

  def escape(assigns, %{"key" => "Escape"}) do
    file = assigns.current_file
    user = assigns.current_user
    current_path = [file.id]

    track_user_update(user, file, current_path: current_path)
    push_current_path(current_path)
    Map.put(%{}, :current_path, current_path)
  end

  def delete(assigns, %{"key" => "Delete"}) do
    file = assigns.current_file
    user = assigns.current_user
    current_path = FsetWeb.MainLive.current_path(assigns.ui)

    # Referential integrity
    referrers =
      Enum.map(List.wrap(current_path), fn path ->
        if sch = Sch.get(file.schema, path) do
          Sch.find_path(file.schema, fn sch_ ->
            if ref = Sch.ref(sch_) do
              "#" <> ref = ref
              ref == Sch.anchor(sch)
            end
          end)
        end
      end)
      |> Enum.reject(fn a -> is_nil(a) || a == "" end)

    if Enum.empty?(referrers) do
      {parents_of_deleted, new_schema} = Sch.delete(file.schema, current_path)
      new_current_paths = Map.keys(Sch.find_parents(current_path))

      for parent_path <- parents_of_deleted do
        broadcast_update_sch(file, parent_path, Sch.get(new_schema, parent_path))
      end

      track_user_update(user, file, current_path: parents_of_deleted)

      %{}
      |> Map.put(:current_file, %{file | schema: new_schema})
      |> Map.put(:current_path, new_current_paths)
    else
      %{}
      |> Map.put(:ui, assigns.ui)
      |> put_in([:ui, :errors], [
        %{
          type: :reference,
          payload: %{msg: "Deleting models being referenced!", path: referrers}
        }
      ])
    end
  end

  def models_bodies(file, meta \\ nil)

  def models_bodies(%{type: :main} = file, _meta) do
    schema = Sch.get(file.schema, file.id)
    ksch_pairs = [{:main, schema}]

    {ksch_pairs, _container_height = sch_height(schema)}
  end

  def models_bodies(%{type: :model} = file, _meta) do
    schema = Sch.get(file.schema, file.id)
    line_h = 24
    buffer = 32
    gap = 8

    {ksch_pairs, _h} =
      Sch.order(schema)
      |> Enum.with_index()
      |> Enum.reduce({[], 0}, fn {key, index}, {pair_acc, h_acc} ->
        sch = Sch.prop_sch(schema, key)
        sch_h = sch_height(sch)

        sch =
          sch
          |> Map.put(:index, index)
          |> Map.put(:offset, h_acc)
          |> Map.put(:height, sch_h)

        # accumulate sch height per line. h_acc is a next item's offset.
        h_acc = h_acc + sch_h * line_h + buffer + gap
        _acc = {[{key, sch} | pair_acc], h_acc}
      end)

    {Enum.reverse(ksch_pairs), _container_height = sch_height(schema) * line_h}
  end

  defp sch_height(sch) when is_map(sch) do
    {_new_sch, height} =
      Sch.reduce(sch, 0, fn a, acc ->
        cond do
          # Sch.array?(a, :homo) -> {a, acc}
          true -> {a, acc + 1}
        end
      end)

    height
  end

  defp get_project(project_name) do
    p = Project.get_by!(name: project_name)

    {[main_file], model_files} = Enum.split_with(p.schs, &(&1.type == :main))
    %{p | main_sch: main_file, model_schs: model_files, schs: []}
  end

  defp get_project_meta(project) do
    main_file = %{project.main_sch | models_anchors: [], schema: nil}

    model_files =
      Enum.map(project.model_schs, fn file ->
        schema = Sch.get(file.schema, file.id)

        models_anchors =
          for k <- Sch.order(schema) do
            model_sch = Sch.prop_sch(schema, k)
            {k, Sch.anchor(model_sch)}
          end

        %{file | models_anchors: models_anchors, schema: nil}
      end)

    [main_file | model_files]
  end

  defp get_current_file(project, file_id) do
    if project do
      Enum.find(project.model_schs, fn file -> file.id == file_id end) ||
        project.main_sch
    else
      Project.get_file!(file_id)
    end
  end

  def models_anchors(files) do
    Enum.flat_map(files, fn file -> file.models_anchors end)
  end

  # Process or application dependent functions
  #
  def subscribe_file_update(file_id) do
    Phoenix.PubSub.subscribe(Fset.PubSub, @file_topic <> file_id)
  end

  def broadcast_update_sch(%{id: id}, path, sch, opts \\ []) when is_binary(id) do
    Phoenix.PubSub.broadcast!(
      Fset.PubSub,
      @file_topic <> id,
      {:update_sch, path, sch, opts}
    )
  end

  def track_user(user_id, file_id) do
    Presence.track(self(), @file_topic <> file_id, user_id, %{
      current_path: file_id,
      pid: self()
    })
  end

  def track_user_update(user, file, data) do
    Presence.update(self(), @file_topic <> file.id, user.id, fn meta ->
      new_meta = Map.take(Enum.into(data, %{}), [:current_path, :pid])
      _meta = Map.merge(meta, new_meta)
    end)
  end

  def push_current_path(sch_path) when is_binary(sch_path) or is_list(sch_path) do
    Process.send(self(), {:re_render_current_path, List.wrap(sch_path)}, [:noconnect])
  end

  defp models_target(file_id, src_indices, dst_indices, keyed_model_schs) do
    srcs = Enum.map(src_indices, fn src -> src["from"] end)
    dsts = Enum.map(dst_indices, fn src -> src["to"] end)

    for path <- Enum.uniq(dsts ++ srcs) do
      Enum.find_value(keyed_model_schs, fn {key, model_sch} ->
        model_path = file_id <> "[" <> key <> "]"
        if String.starts_with?(path, model_path), do: {model_path, model_sch}
      end)
    end
  end
end
