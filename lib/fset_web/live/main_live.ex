defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, ModuleComponent}
  alias Fset.{Accounts, Sch, Persistence, Module}
  alias Fset.Sch.New

  @impl true
  def mount(params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update")
      :timer.send_interval(1000, self(), :tick)
    end

    # File by id
    current_user = session["current_user_id"] && Accounts.get_user!(session["current_user_id"])
    file = file_assigns(params["file_id"], current_user)

    # List of files
    user_files = Fset.Persistence.get_user_files(current_user.id)
    files = Enum.map(user_files, &Map.take(&1.file, [:id, :name]))

    {:ok,
     socket
     |> assign_new(:current_user, fn -> current_user end)
     |> assign(:current_file, file)
     |> assign(:files, files)
     |> assign(:ui, %{
       current_path: file.module.current_section_key,
       current_edit: nil,
       errors: []
     })}
  end

  @impl true
  def handle_event("add_model", %{"model" => model}, socket) do
    file = socket.assigns.current_file
    ui = socket.assigns.ui

    module =
      Module.update_current_section(file.module, Module.add_model_fun(model, ui.current_path))

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
    %{"key" => key, "value" => value} = params
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
        # current_paths = Sch.get_paths(section_sch, dst_indices)
        Map.put(ui, :current_path, current_paths)
      end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
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

            new_current_paths = Map.keys(Sch.find_parent(ui.current_path))

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
    {:noreply,
     update(socket, :current_file, fn _ -> file_assigns(file_id, socket.assigns.current_user) end)}
  end

  @impl true
  def handle_info(:update_schema, socket) do
    module = socket.assigns.current_file.module
    module = Module.update_current_section(module, &Sch.sanitize/1)
    file_sch = Module.to_schema(module)

    Persistence.update_file(socket.assigns.current_file.id, schema: file_sch)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    file = socket.assigns.current_file
    module = Module.update_current_section(file.module, &Sch.sanitize/1)
    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)
    {:noreply, socket}
  end

  defp file_assigns(file_id, user) do
    user_file = Persistence.get_user_file(file_id, user)
    module = Module.from_schema(user_file.file.schema)

    user_file.file
    |> Map.from_struct()
    |> Map.put(:module, module)
    |> Map.put(:bytes, Persistence.term_size(module))
  end

  defp percent(byte_size, :per_mb, quota) do
    quota_byte = quota * (1024 * 1024)
    Float.floor(byte_size / quota_byte * 100, 2)
  end
end
