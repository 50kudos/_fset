defmodule Fset.Main do
  @moduledoc """
  Main Fset application works on highest level closed to web framework such as
  Liveview event handler. And only manage inputs from boundary, feed into a blackbox
  layer, then manage output to be returned.

  It also depend on applications started under main supervision tree such as
  Fset.PubSub and FsetWeb.Presence
  """
  @file_topic "module_update:"

  alias Fset.{Accounts, Project, Module, Sch}
  alias FsetWeb.Presence

  def init_data(params) do
    with project <- Project.get_by!(name: params["project_name"]),
         current_file <- get_current_file(project, params["file_id"]),
         {models_anchors, files_ids} <- get_project_meta(project.id),
         models_bodies <- models_bodies(current_file),
         user <- Accounts.get_user_by_username!(params["username"]) do
      %{}
      |> Map.put(:project_name, project.name)
      |> Map.put(:current_user, user)
      |> Map.put(:current_file, current_file)
      |> Map.put(:files_ids, files_ids)
      |> Map.put(:models_anchors, models_anchors)
      |> Map.put(:current_models_bodies, models_bodies)
      |> Map.put(:ui, %{errors: [], topic: @file_topic <> current_file.id, user_id: user.id})
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

    %{}
    |> Map.put(:current_file, %{file | schema: new_schema})
    |> Map.put(:models_anchors, [{added_key, added_sch} | assigns.models_anchors])
  end

  def change_type(assigns, %{"value" => type, "path" => path}) do
    file = assigns.current_file

    new_schema =
      cond do
        type in Module.changable_types() ->
          {_pre, postsch, new_schema} = Module.change_type(file.schema, path, type)
          broadcast_update_sch(file, path, postsch)
          new_schema

        {_m, anchor} = Enum.find(assigns.models_anchors, fn {m, _a} -> m == type end) ->
          {_pre, postsch, new_schema} = Module.change_type(file.schema, path, {:ref, anchor})
          broadcast_update_sch(file, path, postsch)
          new_schema

        true ->
          file.schema
      end

    Map.put(%{}, :current_file, %{file | schema: new_schema})
  end

  defp models_bodies(%{type: :main} = file), do: file.schema

  defp models_bodies(%{type: :model} = file) do
    for key <- Sch.order(file.schema) do
      {key, Sch.prop_sch(file.schema, key)}
    end
  end

  defp get_project_meta(project_id) do
    all_files = Project.all_files(project_id)

    {_models_anchors, _files_ids} =
      Enum.flat_map_reduce(all_files, [], fn fi, acc ->
        fi = Map.update!(fi, :schema, &Sch.get(&1, fi.id))
        schema = fi.schema

        model_anchor =
          for k <- Sch.order(schema) do
            model_sch = Sch.prop_sch(schema, k)
            {k, Sch.anchor(model_sch)}
          end
          |> Enum.filter(fn {_, sch} -> sch != nil end)

        {model_anchor, [%{fi | schema: nil} | acc]}
      end)
  end

  defp get_current_file(project, file_id) do
    if file_id, do: Project.get_file!(file_id), else: project.main_sch
  end

  # Process or application dependent functions
  #
  def subscribe_file_update(file) do
    Phoenix.PubSub.subscribe(Fset.PubSub, @file_topic <> file.id)
  end

  def broadcast_update_sch(%{id: id}, path, sch) when is_binary(id) do
    Phoenix.PubSub.broadcast!(
      Fset.PubSub,
      @file_topic <> id,
      {:update_sch, path, sch}
    )
  end

  def track_user(user, file) do
    Presence.track(self(), @file_topic <> file.id, user.id, %{
      current_path: file.id,
      current_edit: nil,
      pid: self()
    })
  end
end
