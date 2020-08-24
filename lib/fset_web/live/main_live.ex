defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent}
  alias Fset.{Sch, Persistence, Module}
  alias Fset.Sch.New

  @impl true
  def mount(params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update")
    end

    user_files = Fset.Persistence.get_user_files(session["current_user_id"])

    files = Enum.map(user_files, &Map.take(&1.file, [:id, :name]))
    user_file = Enum.find(user_files, fn user_file -> user_file.file.id == params["file_id"] end)
    file = file_assigns(user_file.file)

    {:ok,
     socket
     |> assign_new(:current_user, fn -> user_file.user end)
     |> assign(:current_file, file)
     |> assign(:files, files)
     |> assign(:ui, %{
       current_path: file.module.current_section_key,
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
    add_path = Map.get(val, "path", file.module.current_section_key)

    module =
      Module.update_current_section(
        file.module,
        Module.add_model_fun(model, add_path)
      )

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  def handle_event("change_type", val, socket) do
    type = Map.get(val, "type") || Map.get(val, "value")
    file = socket.assigns.current_file
    ui = socket.assigns.ui

    change_type_fun =
      if type in Module.changable_types() do
        Module.change_type_fun(type, ui.current_path)
      else
        current_section_sch = Module.current_section_sch(file.module)

        anchor =
          Enum.find_value(
            Sch.properties(current_section_sch),
            fn {k, sch} -> k == type && Sch.anchor(sch) end
          )

        if anchor do
          fn sch -> Sch.change_type(sch, ui.current_path, New.ref(anchor)) end
        else
          fn a -> a end
        end
      end

    module = Module.update_current_section(file.module, change_type_fun)
    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    file = socket.assigns.current_file
    module = Module.update_current_section(file.module, &Sch.sanitize/1)

    sch_path =
      case sch_path do
        [] -> socket.assigns.ui.current_path
        [a] -> a
        a -> a
      end

    {:noreply,
     socket
     |> update(:ui, fn ui ->
       ui
       |> Map.put(:current_path, sch_path)
       |> Map.put(:current_edit, nil)
     end)
     |> update(:current_file, fn _ -> %{file | module: module} end)}
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

    module =
      Module.update_current_section(file.module, fn section_sch ->
        Sch.update(section_sch, sch_path, key, value)
      end)

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  def handle_event("rename_key", params, socket) do
    %{"parent_path" => parent_path, "old_key" => old_key, "value" => new_key} = params

    old_key = String.slice(old_key, 0, min(255, String.length(old_key)))
    new_key = String.slice(new_key, 0, min(255, String.length(new_key)))

    file = socket.assigns.current_file

    module =
      Module.update_current_section(file.module, fn section_sch ->
        Sch.rename_key(section_sch, parent_path, old_key, new_key)
      end)

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    socket =
      update(socket, :ui, fn ui ->
        new_key = if new_key == "", do: old_key, else: new_key

        ui
        |> Map.put(:current_path, input_name(parent_path, new_key))
        |> Map.put(:current_edit, nil)
      end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "newIndices" => dst_indices} = payload

    file = socket.assigns.current_file

    paths_refs =
      Enum.map(List.wrap(socket.assigns.ui.current_path), fn p -> {p, Ecto.UUID.generate()} end)

    module =
      Module.update_current_section(file.module, fn section_sch ->
        for {current_path, ref} <- paths_refs, reduce: section_sch do
          acc -> Sch.update(acc, current_path, "$id", ref)
        end
      end)

    module =
      Module.update_current_section(module, fn section_sch ->
        Sch.move(section_sch, src_indices, dst_indices)
      end)

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    socket =
      update(socket, :ui, fn ui ->
        section_sch = Module.current_section(socket.assigns.current_file.module)

        current_paths =
          for ref <- Keyword.values(paths_refs) do
            Sch.find_path(section_sch, fn sch -> Map.get(sch, "$id") == ref end)
          end

        current_paths = Enum.filter(current_paths, fn p -> p != "" end)
        current_paths = if length(current_paths) == 1, do: hd(current_paths), else: current_paths
        # current_paths = Sch.get_paths(section_sch, dst_indices)
        Map.put(ui, :current_path, current_paths)
      end)

    Process.send_after(self(), :update_schema, 1000)
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
          Process.send_after(self(), :update_schema, 1000)

          current_section = Module.current_section(file.module)

          # Referential integrity

          referrers =
            Enum.map(List.wrap(ui.current_path), fn path ->
              if sch = Sch.get(current_section, path) do
                Sch.find_path(current_section, fn sch_ ->
                  if ref = Sch.ref(sch_) do
                    "#" <> ref = ref
                    ref == Sch.anchor(sch)
                  end
                end)
              end
            end)
            |> Enum.reject(fn a -> is_nil(a) || a == "" end)

          if Enum.empty?(referrers) do
            module =
              Module.update_current_section(file.module, fn section_sch ->
                Sch.delete(section_sch, ui.current_path)
              end)

            new_current_paths = Map.keys(Sch.find_parents(ui.current_path))

            assigns
            |> put_in([:current_file], %{file | module: module})
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
          |> put_in([:ui, :current_path], assigns.current_file.module.current_section_key)
          |> put_in([:ui, :current_edit], nil)

        _ ->
          file.module
      end

    Map.take(assigns, [:current_file, :ui])
  end

  @impl true
  def handle_params(%{"file_id" => file_id}, _url, socket) do
    user_file = Persistence.get_user_file(file_id, socket.assigns.current_user)

    {:noreply, assign(socket, :current_file, file_assigns(user_file.file))}
  end

  @impl true
  def handle_info(:update_schema, socket) do
    module = socket.assigns.current_file.module
    module = Module.update_current_section(module, &Sch.sanitize/1)
    file_sch = Module.to_schema(module)

    file = Persistence.update_file(socket.assigns.current_file.id, schema: file_sch)
    module = Module.from_schema(file.schema)

    file =
      file
      |> Map.from_struct()
      |> Map.put(:module, module)
      |> Map.put(:bytes, Persistence.term_size(module))

    socket = assign(socket, :current_file, file)
    {:noreply, socket}
  end

  defp get_sch(current_file, ui) do
    Module.current_section_sch(current_file.module, ui.current_path)
  end

  defp get_parent(current_file, ui) do
    parent_path = Sch.find_parent(ui.current_path).path
    Module.current_section_sch(current_file.module, parent_path)
  end

  defp file_assigns(file) do
    module = Module.from_schema(file.schema)

    file
    |> Map.from_struct()
    |> Map.put(:module, module)
    |> Map.put(:bytes, Persistence.term_size(module))
  end

  defp selected_count(ui, f) do
    length = length(List.wrap(ui.current_path) -- [f.name])
    if length < 1, do: false, else: length
  end

  defp percent(byte_size, :per_mb, quota) do
    quota_byte = quota * (1024 * 1024)
    Float.floor(byte_size / quota_byte * 100, 2)
  end
end
