defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent, ModelBarComponent, Presence}
  alias Fset.{Sch, Persistence, Module, Project}
  import Fset.Main

  @impl true
  def mount(params, _session, socket) do
    assigns = init_data(params)
    temporary_assigns = []

    if connected?(socket), do: subscribe_file_update(assigns.current_file)

    push_current_path(assigns.current_file.id)
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

    assigns = Map.put(%{}, :current_path, sch_path)
    track_user_update(user, file, current_path: sch_path, pid: socket.root_pid)
    push_current_path(sch_path)

    if length(sch_path) == 1 do
      sch = Sch.get(file.schema, hd(sch_path))
      send_update(FsetWeb.SchComponent, id: file.id, sch: sch, path: hd(sch_path))
    end

    {:noreply, assign(socket, assigns)}
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
    assigns = update_sch(socket.assigns, params)

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("rename_key", params, socket) do
    assigns = rename_key(socket.assigns, params)

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("move", params, socket) do
    assigns = move(socket.assigns, params)

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("escape", _val, socket) do
    handle_event("module_keyup", %{"key" => "Escape"}, socket)
  end

  def handle_event("delete", _val, socket) do
    handle_event("module_keyup", %{"key" => "Delete"}, socket)
  end

  def handle_event("module_keyup", params, socket) do
    # Prevent operations on file level
    if current_path(socket.assigns.ui) in Enum.map(socket.assigns.files_ids, & &1.id) do
      {:noreply, socket}
    else
      assigns =
        case params do
          %{"key" => "Escape"} ->
            escape(socket.assigns, params)

          %{"key" => "Delete"} ->
            delete(socket.assigns, params)

          # send_update(ModelBarComponent, id: :model_bar, paths: new_current_paths -- [file.id])

          _ ->
            %{}
        end

      {:noreply, assign(socket, assigns)}
    end
  end

  @impl true
  def handle_info({:update_sch, path, sch, _opts}, socket) do
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

  def handle_info({:re_render_current_path, paths}, socket) do
    {:noreply, push_event(socket, "current_path", %{paths: paths})}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    {:noreply, socket}
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
