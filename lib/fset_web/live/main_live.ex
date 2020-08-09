defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{SchComponent, FileComponent}
  alias Fset.{Accounts, Sch, Persistence, File}

  @impl true
  def mount(params, session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update")

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
       current_edit: nil
     })}
  end

  @impl true
  # def handle_event(event, val, socket) do
  #   updated =
  #     case event do
  #       "add_prop" -> add_prop(val, socket)
  #       "add_item" -> add_item(val, socket)
  #       "select_type" -> select_type(val, socket)
  #       "select_sch" -> select_sch(val, socket)
  #       "edit_sch" ->edit_sch(val, socket)
  #       "update_sch" ->update_sch(val, socket)
  #       "rename_key" ->rename_key(val, socket)
  #       "escape" ->escape(val, socket)
  #       "move" ->move(val, socket)
  #     end

  #   updated_socket =
  #     socket
  #     |> update(:ui, fn u -> updated.ui || u end)
  #     |> update(:current_file, fn c -> updated.current_file || c end)

  #   {:noreply , updated_socket}
  # end

  def handle_event("add_model", %{"model" => model}, socket) do
    file = socket.assigns.current_file
    ui = socket.assigns.ui

    add_model_fun =
      case model do
        "Record" ->
          fn sch -> Sch.put(sch, ui.current_path, Sch.gen_key(), Sch.any(), 0) end

        "Field" ->
          fn sch -> Sch.put(sch, ui.current_path, Sch.gen_key(), Sch.string(), 0) end

        "List" ->
          fn sch -> Sch.put(sch, ui.current_path, Sch.gen_key(), Sch.array(:homo), 0) end

        "Tuple" ->
          fn sch -> Sch.put(sch, ui.current_path, Sch.gen_key(), Sch.array(:hetero), 0) end

        "Union" ->
          union = Sch.any_of([Sch.object(), Sch.array(), Sch.string()])
          fn sch -> Sch.put(sch, ui.current_path, Sch.gen_key(), union, 0) end

        _ ->
          fn a -> a end
      end

    module = File.update_current_section(file.module, add_model_fun)
    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    Process.send_after(self(), :update_schema, 1000)

    {:noreply, socket}
  end

  def handle_event("add_prop", _val, %{assigns: %{ui: ui}} = socket) do
    Process.send_after(self(), :update_schema, 1000)

    {:noreply,
     update(socket, :current_file, &Sch.put(&1, ui.current_path, Sch.gen_key(), Sch.string()))}
  end

  def handle_event("add_item", _val, %{assigns: %{ui: ui}} = socket) do
    Process.send_after(self(), :update_schema, 1000)
    {:noreply, update(socket, :current_file, &Sch.put(&1, ui.current_path, Sch.string()))}
  end

  def handle_event("change_type", %{"type" => type}, socket) do
    file = socket.assigns.current_file
    ui = socket.assigns.ui

    type =
      case type do
        "record" -> "object"
        "list" -> "array"
        "tuple" -> "array"
        "string" -> "string"
        "bool" -> "boolean"
        "number" -> "number"
        "null" -> "null"
        "union" -> "anyOf"
        _ -> "null"
      end

    module =
      File.update_current_section(file.module, fn section_sch ->
        Sch.change_type(section_sch, ui.current_path, type)
      end)

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    Process.send_after(self(), :update_schema, 1000)

    {:noreply, socket}
  end

  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    sch_path =
      case sch_path do
        [] -> socket.assigns.ui.current_path
        [a] -> a
        a -> a
      end

    {:noreply,
     update(socket, :ui, fn ui ->
       ui
       |> Map.put(:current_path, sch_path)
       |> Map.put(:current_edit, nil)
     end)}
  end

  def handle_event("edit_sch", %{"path" => sch_path}, socket) do
    updated_ui =
      if socket.assigns.ui.current_path in File.preserve_keys() do
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
      File.update_current_section(file.module, fn section_sch ->
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
      File.update_current_section(file.module, fn section_sch ->
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

  def handle_event("escape", _, socket) do
    {:noreply,
     update(socket, :ui, fn ui ->
       ui
       |> Map.put(:current_path, socket.assigns.ui.current_path)
       |> Map.put(:current_edit, nil)
     end)}
  end

  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "newIndices" => dst_indices} = payload

    file = socket.assigns.current_file

    module =
      File.update_current_section(file.module, fn section_sch ->
        Sch.move(section_sch, src_indices, dst_indices)
      end)

    socket = update(socket, :current_file, fn _ -> %{file | module: module} end)

    socket =
      update(socket, :ui, fn ui ->
        section_sch = File.current_section(socket.assigns.current_file.module)
        current_paths = Sch.get_paths(section_sch, dst_indices)
        Map.put(ui, :current_path, current_paths)
      end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  def handle_event("module_keyup", val, socket) do
    if socket.assigns.ui.current_path in File.preserve_keys() do
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

          module =
            File.update_current_section(file.module, fn section_sch ->
              Sch.delete(section_sch, ui.current_path)
            end)

          new_current_paths = Map.keys(Sch.find_parent(ui.current_path))

          assigns
          |> put_in([:current_file], %{file | module: module})
          |> put_in([:ui, :current_path], new_current_paths)

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
    file_sch = File.from_module(socket.assigns.current_file.module)
    Persistence.update_file(socket.assigns.current_file.id, schema: file_sch)

    {:noreply, socket}
  end

  defp file_assigns(file_id, user) do
    user_file = Persistence.get_user_file(file_id, user)
    module = File.to_module(user_file.file.schema)

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
