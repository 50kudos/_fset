defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent}
  alias Fset.{Sch, Persistence, Module, Module2, Project, Accounts}

  @impl true
  def mount(params, _session, socket) do
    user = Accounts.get_user_by_username(params["username"])
    project = Project.get_by(name: params["project_name"])
    schs_indice = Project.schs_indice(project.id)
    socket = assign(socket, :current_file, project.main_sch)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update:" <> socket.assigns.current_file.id)
    end

    {:ok,
     socket
     |> assign_new(:current_user, fn -> user end)
     |> assign(:project_name, project.name)
     |> assign(:files, schs_indice)
     |> assign(:ui, %{
       current_path: project.main_sch.id,
       current_edit: nil,
       errors: []
     })}
  end

  @impl true
  def handle_event("add_field", %{"field" => field}, socket) do
    add_path = socket.assigns.ui.current_path
    handle_event("add_model", %{"model" => field, "path" => add_path}, socket)
  end

  def handle_event("add_model", %{"model" => model} = val, socket) do
    file = socket.assigns.current_file
    add_path = Map.get(val, "path", file.id)
    file = Module2.add_model(file, add_path, model)

    socket = update(socket, :current_file, fn _ -> file end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("change_type", val, socket) do
    type = Map.get(val, "type") || Map.get(val, "value")
    file = socket.assigns.current_file
    ui = socket.assigns.ui

    file =
      if file.type == :main do
        if type in Module.changable_types() do
          Module2.change_type(file, ui.current_path, type)
        end
      end

    # current_section_sch = file.schema
    # anchor =
    #   Enum.find_value(
    #     Sch.properties(current_section_sch),
    #     fn {k, sch} -> k == type && Sch.anchor(sch) end
    #   )

    # if anchor do
    #   fn sch -> Sch.change_type(sch, ui.current_path, New.ref(anchor)) end
    # else
    #   fn a -> a end
    # end

    socket = update(socket, :current_file, fn _ -> file end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    file = socket.assigns.current_file

    sch_path =
      case sch_path do
        [] -> socket.assigns.ui.current_path
        [a] -> a
        a -> a
      end

    file = Map.update!(file, :schema, &Sch.sanitize/1)

    {:noreply,
     socket
     |> update(:ui, fn ui ->
       ui
       |> Map.put(:current_path, sch_path)
       |> Map.put(:current_edit, nil)
     end)
     |> update(:current_file, fn _ -> file end)}
  end

  def handle_event("edit_sch", %{"path" => sch_path}, socket) do
    updated_ui =
      if socket.assigns.ui.current_path in Module.preserve_keys() do
        socket.assigns.ui
      else
        socket.assigns.ui
        |> Map.put(:current_path, sch_path)
        |> Map.put(:current_edit, sch_path)
      end

    {:noreply, update(socket, :ui, fn _ -> updated_ui end)}
  end

  def handle_event("update_sch", params, socket) do
    %{"key" => key} = params
    value = Map.get(params, "value")
    sch_path = socket.assigns.ui.current_path

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

    file = socket.assigns.current_file
    file = Module2.rename_key(file, parent_path, old_key, new_key)

    socket = update(socket, :current_file, fn _ -> file end)

    socket =
      update(socket, :ui, fn ui ->
        new_key = if new_key == "", do: old_key, else: new_key

        ui
        |> Map.put(:current_path, input_name(parent_path, new_key))
        |> Map.put(:current_edit, nil)
      end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "newIndices" => dst_indices} = payload

    file = socket.assigns.current_file

    paths_refs =
      Enum.map(List.wrap(socket.assigns.ui.current_path), fn p -> {p, Ecto.UUID.generate()} end)

    schema =
      for {current_path, ref} <- paths_refs, reduce: file.schema do
        acc -> Sch.update(acc, current_path, "$id", ref)
      end

    schema = Sch.move(schema, src_indices, dst_indices)

    socket = update(socket, :current_file, fn _ -> %{file | schema: schema} end)

    socket =
      update(socket, :ui, fn ui ->
        section_sch = socket.assigns.current_file.schema

        current_paths =
          for ref <- Keyword.values(paths_refs) do
            Sch.find_path(section_sch, fn sch -> Map.get(sch, "$id") == ref end)
          end

        current_paths = Enum.filter(current_paths, fn p -> p != "" end)
        current_paths = if length(current_paths) == 1, do: hd(current_paths), else: current_paths
        # current_paths = Sch.get_paths(section_sch, dst_indices)
        Map.put(ui, :current_path, current_paths)
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
    if socket.assigns.ui.current_path in Module.preserve_keys() do
      {:noreply, socket}
    else
      updated_assigns = module_keyup(val, socket.assigns)
      socket = assign(socket, updated_assigns)

      {:noreply, socket}
    end
  end

  defp module_keyup(%{"key" => key}, assigns) do
    file = assigns.current_file
    ui = assigns.ui

    assigns =
      case key do
        "Delete" ->
          async_update_schema()

          # Referential integrity

          referrers =
            Enum.map(List.wrap(ui.current_path), fn path ->
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
            schema = Sch.delete(file.schema, ui.current_path)
            new_current_paths = Map.keys(Sch.find_parents(ui.current_path))

            assigns
            |> put_in([:current_file], %{file | schema: schema})
            |> put_in([:ui, :current_path], new_current_paths)
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
          assigns
          |> put_in([:ui, :current_path], assigns.current_file.id)
          |> put_in([:ui, :current_edit], nil)

        _ ->
          assigns
      end

    Map.take(assigns, [:current_file, :ui])
  end

  @impl true
  def handle_info(:update_schema, socket) do
    updated_file = socket.assigns.current_file
    existing_file = Project.get_file(updated_file.id)

    existing_schema = existing_file.schema
    updated_schema = Sch.merge(existing_schema, updated_file.schema) |> Sch.sanitize()
    file = Persistence.replace_file(existing_file, schema: updated_schema)

    socket = assign(socket, :current_file, file)
    Phoenix.PubSub.broadcast_from!(Fset.PubSub, self(), "sch_update:" <> file.id, file)
    {:noreply, socket}
  end

  def handle_info(file, socket) do
    {:noreply, assign(socket, :current_file, file)}
  end

  defp async_update_schema() do
    Process.send_after(self(), :update_schema, Enum.random(200..300))
  end

  defp get_parent(current_file, ui) do
    parent_path = Sch.find_parent(ui.current_path).path
    Sch.get(current_file.schema, parent_path)
  end

  defp selected_count(ui, f) do
    length = length(List.wrap(ui.current_path) -- [f.name])
    if length < 1, do: false, else: length
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
end
