defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent}
  alias Fset.{Sch, Persistence, Module, Project, Accounts, Utils}

  @impl true
  def mount(params, _session, socket) do
    user = Accounts.get_user_by_username(params["username"])
    project = Project.get_by(name: params["project_name"])
    schs_indice = Project.schs_indice(project.id)

    current_file =
      if params["file_id"], do: Project.get_file(params["file_id"]), else: project.main_sch

    socket = assign(socket, :current_file, current_file)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update:" <> socket.assigns.current_file.id)
    end

    {model_names, schs_indice} =
      Enum.flat_map_reduce(schs_indice, [], fn fi, acc ->
        fi = Map.update!(fi, :schema, fn root -> Sch.get(root, fi.id) end)
        schema = fi.schema

        model_anchor =
          for k <- Sch.order(schema) do
            model_sch = Sch.prop_sch(schema, k)
            {k, Sch.anchor(model_sch)}
          end

        {model_anchor, [%{fi | schema: nil} | acc]}
      end)

    models_nav = Sch.order(Sch.get(current_file.schema, current_file.id))
    :ets.new(:main, [:set, :protected, :named_table])
    :ets.insert(:main, {:current_path, [current_file.id]})

    {
      :ok,
      socket
      |> assign_new(:current_user, fn -> user end)
      |> assign(:project_name, project.name)
      |> assign(:files, Enum.reverse(schs_indice))
      |> assign(:model_names, model_names)
      |> assign(:models_nav, models_nav)
      |> assign(:ui, %{current_edit: nil, errors: []}),
      temporary_assigns: [models_nav: []]
    }
  end

  @impl true
  def handle_event("add_field", %{"field" => field}, socket) do
    add_path = socket.assigns.current_path

    handle_event("add_model", %{"model" => field, "path" => add_path}, socket)
  end

  def handle_event("add_model", %{"model" => model} = val, socket) do
    file = socket.assigns.current_file
    add_path = Map.get(val, "path", file.id)
    file = Module.add_model(file, add_path, model)

    socket = update(socket, :current_file, fn _ -> file end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("change_type", val, socket) do
    type = Map.get(val, "type") || Map.get(val, "value")
    file = socket.assigns.current_file
    model_names = socket.assigns.model_names
    selected_paths = Sch.selected_paths(file)

    file =
      cond do
        type in Module.changable_types() ->
          Module.change_type(file, selected_paths, type)

        {_m, anchor} = Enum.find(model_names, fn {m, _a} -> m == type end) ->
          Module.change_type(file, selected_paths, {:ref, anchor})

        true ->
          file
      end

    socket = update(socket, :current_file, fn _ -> file end)

    async_update_schema()
    {:noreply, socket}
  end

  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    sch_path = List.wrap(sch_path)

    {:memory, mem} = Process.info(socket.root_pid, :memory)
    IO.inspect("#{mem / (1024 * 1024)} MB", label: "MEMORY")

    file = socket.assigns.current_file
    previous_path = current_path()
    :ets.insert(:main, {:current_path, sch_path})

    case previous_path do
      [path] when is_binary(path) ->
        send_update(FsetWeb.ModelComponent, id: path)

      paths when is_list(paths) ->
        for path <- paths do
          send_update(FsetWeb.ModelComponent, id: path)
        end
    end

    case sch_path do
      [path] when is_binary(path) ->
        sch = Sch.get(file.schema, path)

        send_update(FsetWeb.ModelComponent, id: path)
        send_update(FsetWeb.SchComponent, id: file.id, sch: sch, path: path)

      paths when is_list(paths) ->
        for path <- paths do
          send_update(FsetWeb.ModelComponent, id: path)
        end
    end

    {
      :noreply,
      socket
      |> update(:ui, fn ui -> Map.put(ui, :current_edit, nil) end)
    }
  end

  def handle_event("edit_sch", %{"path" => sch_path}, socket) do
    updated_ui =
      if socket.assigns.ui.current_path in Enum.map(socket.assigns.files, & &1.id) do
        socket.assigns.ui
      else
        socket.assigns.ui
        |> Map.put(:current_path, sch_path)
        |> Map.put(:current_edit, sch_path)
      end

    {:noreply, update(socket, :ui, fn _ -> updated_ui end)}
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

    file = socket.assigns.current_file
    file = Module.rename_key(file, parent_path, old_key, new_key)

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
    if socket.assigns.ui.current_path in Enum.map(socket.assigns.files, & &1.id) do
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

    Phoenix.PubSub.broadcast_from!(
      Fset.PubSub,
      self(),
      "sch_update:" <> file.id,
      {:update_file, file}
    )

    {:noreply, socket}
  end

  def handle_info({:update_file, file}, socket) do
    {:noreply, assign(socket, :current_file, file)}
  end

  def handle_info({:update_sch, sch, path}, socket) do
    send_update(FsetWeb.SchComponent, id: path, sch: sch)
    {:noreply, socket}
  end

  defp async_update_schema() do
    Process.send_after(self(), :update_schema, Enum.random(200..300))
  end

  defp get_parent(current_file, ui) do
    parent_path = Sch.find_parent(ui.current_path).path
    Sch.get(current_file.schema, parent_path)
  end

  defp selected_count(ui, f) do
    # length = length(List.wrap(ui.current_path) -- [f.name])
    # if length < 1, do: false, else: length
    false
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

  defp text_val_types(model_names) do
    Module.changable_types() ++ Enum.map(model_names, fn {key, _} -> key end)
  end

  def selected?([path], current_path), do: selected?(path, current_path)

  def selected?(path, current_path) when is_binary(path) do
    path in current_path
  end

  def selected?([path], current_path, :single), do: selected?(path, current_path, :single)

  def selected?(path, current_path, :single) do
    path in current_path && Enum.count(current_path) == 1
  end

  def selected?([path], current_path, :multi), do: selected?(path, current_path, :multi)

  def selected?(path, current_path, :multi) do
    path in current_path && Enum.count(current_path) > 1
  end

  def current_path(), do: :ets.lookup(:main, :current_path)[:current_path]
end
