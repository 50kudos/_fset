defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent, ModelBarComponent, Presence}
  alias Fset.{Sch, Persistence, Module, Project, Utils}
  import Fset.Main

  @impl true
  def mount(params, _session, socket) do
    assigns = init_data(params)
    temporary_assigns = []

    if connected?(socket), do: subscribe_file_update(assigns.current_file)
    track_user(assigns.current_user, assigns.current_file)

    {:ok, assign(socket, assigns), temporary_assigns: temporary_assigns}
  end

  @impl true
  def handle_event("add_model", params, socket) do
    assigns = add_model(socket.assigns, params)

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("change_type", params, socket) do
    assigns = change_type(socket.assigns, params)

    {:noreply, assign(socket, assigns)}
  end

  # TODO: Completely move select state to client side. Tracking current_path is
  # problematic, things get impured. Instead, we want to always send path on every
  # operation to server when it is needed.
  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    {:memory, mem} = Process.info(socket.root_pid, :memory)
    IO.inspect("#{mem / (1024 * 1024)} MB", label: "MEMORY")

    user = socket.assigns.current_user
    file = socket.assigns.current_file
    sch_path = Utils.unwrap(sch_path, file.id)

    # Stash current path and update a new one
    previous_path = List.wrap(current_path(socket.assigns.ui))
    track_user_update(user, file, current_path: sch_path, pid: socket.root_pid)

    sch_path = List.wrap(sch_path) -- [file.id]

    send_update(ModelBarComponent, id: :model_bar, paths: sch_path)
    re_render_model(previous_path ++ sch_path)

    if length(sch_path) == 1 do
      sch = Sch.get(file.schema, hd(sch_path))
      send_update(FsetWeb.SchComponent, id: file.id, sch: sch, path: hd(sch_path))
    end

    {:noreply, socket}
  end

  # TODO: See "select_sch" todo
  def handle_event("edit_sch", %{"path" => sch_path}, socket) do
    user = socket.assigns.current_user
    file = socket.assigns.current_file
    root_model_paths = Enum.map(socket.assigns.files_ids, & &1.id)

    unless current_path(socket.assigns.ui) in root_model_paths do
      track_user_update(user, file, current_path: sch_path, current_edit: sch_path)
      re_render_model(sch_path)
    end

    {:noreply, socket}
  end

  def handle_event("update_sch", params, socket) do
    %{"key" => key, "path" => sch_path} = params
    value = Map.get(params, "value")

    file = socket.assigns.current_file
    schema = Sch.update(file.schema, sch_path, key, value)
    socket = update(socket, :current_file, fn _ -> %{file | schema: schema} end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("rename_key", params, socket) do
    %{"parent_path" => parent_path, "old_key" => old_key, "value" => new_key} = params

    old_key = String.slice(old_key, 0, min(255, String.length(old_key)))
    new_key = String.slice(new_key, 0, min(255, String.length(new_key)))

    user = socket.assigns.current_user
    file = socket.assigns.current_file
    file = Module.rename_key(file, parent_path, old_key, new_key)

    socket = update(socket, :current_file, fn _ -> file end)

    new_key = if new_key == "", do: old_key, else: new_key
    new_path = input_name(parent_path, new_key)

    Presence.update(self(), socket.assigns.ui.topic, user.id, fn meta ->
      meta = Map.put(meta, :current_path, new_path)
      _meta = Map.put(meta, :current_edit, nil)
    end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "newIndices" => dst_indices} = payload

    user = socket.assigns.current_user
    file = socket.assigns.current_file

    paths_refs =
      Enum.map(List.wrap(current_path(socket.assigns.ui)), fn p -> {p, Ecto.UUID.generate()} end)

    schema =
      for {current_path, ref} <- paths_refs, reduce: file.schema do
        acc -> Sch.update(acc, current_path, "$id", ref)
      end

    schema = Sch.move(schema, src_indices, dst_indices)

    socket =
      if file.type == :model do
        schema = Sch.get(schema, file.id)

        models =
          for key <- Sch.order(schema) do
            {key, Sch.prop_sch(schema, key)}
          end

        assign(socket, :models, models)
      else
        socket
      end

    socket = update(socket, :current_file, fn _ -> %{file | schema: schema} end)

    section_sch = socket.assigns.current_file.schema

    current_paths =
      for ref <- Keyword.values(paths_refs) do
        Sch.find_path(section_sch, fn sch -> Map.get(sch, "$id") == ref end)
      end

    current_paths = Enum.filter(current_paths, fn p -> p != "" end)
    current_paths = if length(current_paths) == 1, do: hd(current_paths), else: current_paths
    # current_paths = Sch.get_paths(section_sch, dst_indices)

    Presence.update(self(), socket.assigns.ui.topic, user.id, fn meta ->
      _meta = Map.put(meta, :current_path, current_paths)
    end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("escape", _val, socket) do
    handle_event("module_keyup", %{"key" => "Escape"}, socket)
  end

  def handle_event("delete", _val, socket) do
    handle_event("module_keyup", %{"key" => "Delete"}, socket)
  end

  def handle_event("module_keyup", val, socket) do
    if current_path(socket.assigns.ui) in Enum.map(socket.assigns.files_ids, & &1.id) do
      {:noreply, socket}
    else
      updated_assigns = module_keyup(val, socket.assigns)
      socket = assign(socket, updated_assigns)

      {:noreply, socket}
    end
  end

  defp module_keyup(%{"key" => key}, assigns) do
    user = assigns.current_user
    file = assigns.current_file
    current_path = current_path(assigns.ui)

    assigns =
      case key do
        "Delete" ->
          async_update_schema()

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
            schema = Sch.delete(file.schema, current_path)
            new_current_paths = Map.keys(Sch.find_parents(current_path))

            Presence.update(self(), assigns.ui.topic, user.id, fn meta ->
              _meta = Map.put(meta, :current_path, new_current_paths)
            end)

            send_update(ModelBarComponent, id: :model_bar, paths: new_current_paths -- [file.id])

            if length(new_current_paths) == 1 do
              send_update(FsetWeb.SchComponent,
                id: file.id,
                sch: schema,
                path: hd(new_current_paths)
              )
            end

            assigns
            |> put_in([:current_file], %{file | schema: schema})
          else
            assigns
            |> put_in([:ui, :errors], [
              %{
                type: :reference,
                payload: %{msg: "Deleting models being referenced!", path: referrers}
              }
            ])
          end

        "Escape" ->
          previous_path = current_path(assigns.ui)

          Presence.update(self(), assigns.ui.topic, user.id, fn meta ->
            meta = Map.put(meta, :current_path, file.id)
            _meta = Map.put(meta, :current_edit, nil)
          end)

          re_render_model(previous_path)
          send_update(FsetWeb.SchComponent, id: file.id, sch: file.schema, path: file.id)
          send_update(ModelBarComponent, id: :model_bar, paths: List.wrap(file.id) -- [file.id])
          assigns

        _ ->
          assigns
      end

    Map.take(assigns, [:current_file, :ui])
  end

  @impl true
  def handle_info(:update_schema, socket) do
    updated_file = socket.assigns.current_file
    existing_file = Project.get_file!(updated_file.id)

    existing_schema = existing_file.schema
    updated_schema = Sch.merge(existing_schema, updated_file.schema) |> Sch.sanitize()
    file = Persistence.replace_file(existing_file, schema: updated_schema)

    socket = assign(socket, :current_file, file)
    {:noreply, socket}
  end

  def handle_info({:update_sch, path, sch}, socket) do
    re_render_model(path, sch: sch)
    current_file = socket.assigns.current_file
    existing_file = Project.get_file!(current_file.id)

    current_schema = Sch.replace(current_file.schema, path, sch)
    existing_schema = existing_file.schema
    updated_schema = Sch.merge(existing_schema, current_schema)
    file = Persistence.replace_file(existing_file, schema: updated_schema)

    socket = assign(socket, :current_file, file)
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, socket}
  end

  defp async_update_schema() do
    Process.send_after(self(), :update_schema, Enum.random(200..300))
  end

  defp percent(byte_size, :per_mb, quota) do
    quota_byte = quota * (1024 * 1024)
    Float.floor(byte_size / quota_byte * 100, 2)
  end

  def render_storage(assigns) do
    ~L"""
    <div class="px-4 py-2 border-t-2 border-gray-800 bg-gray-900">
      <h5>Storage</h4>
      <div class="my-1">
        <label for="disk" class="block my-1">
          <p class="text-xs">Internal (of 1 MB quota):</p>
          <progress id="disk" max="100" value="<%= percent(@current_file.bytes, :per_mb, 1) %>" class="h-1 w-full"></progress>
          <p>
            <span class="text-xs"><%= (@current_file.bytes / 1024 / 1024) |> Float.round(2) %> MB</span>
            <span>·</span>
            <span class="text-xs"><%= percent(@current_file.bytes, :per_mb, 1) %>%</span>
          </p>
        </label>
      </div>
      <hr class="border-gray-800 border-opacity-50">
      <div class="mt-2 text-xs">
        <p>External:</p>
        <a href="/auth/github" class="inline-block my-2 px-2 py-1 border border-gray-700 rounded self-end text-gray-500 hover:text-gray-400">Connect Github</a>
      </div>
    </div>
    """
  end

  defp text_val_types(models_anchors) do
    Module.changable_types() ++ Enum.map(models_anchors, fn {key, _} -> key end)
  end

  def selected?(path, current_path) when is_binary(path) do
    path in List.wrap(current_path)
  end

  def selected?(path, current_path, :single) do
    current_path = List.wrap(current_path)
    path in current_path && Enum.count(current_path) == 1
  end

  def selected?(path, current_path, :multi) do
    current_path = List.wrap(current_path)
    path in current_path && Enum.count(current_path) > 1
  end

  def current_path(ui) do
    %{metas: metas} = Presence.get_by_key(ui.topic, ui.user_id)

    meta = Enum.find(metas, fn meta -> meta.pid == self() end)
    meta = meta || hd(metas)
    meta.current_path
  end

  def current_edit(ui) do
    %{metas: metas} = Presence.get_by_key(ui.topic, ui.user_id)

    meta = Enum.find(metas, fn meta -> meta.pid == self() end)
    meta = meta || hd(metas)
    meta.current_edit
  end

  def re_render_model(path_, opts \\ []) do
    case List.wrap(path_) do
      [path] when is_binary(path) ->
        send_update(FsetWeb.ModelComponent, Keyword.merge(opts, id: path))

      paths when is_list(paths) ->
        for path <- paths do
          send_update(FsetWeb.ModelComponent, Keyword.merge(opts, id: path))
        end
    end
  end
end
