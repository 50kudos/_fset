defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.{TreeListComponent, SchComponent, FileComponent}
  alias Fset.{Accounts, Sch, Persistence}

  @impl true
  def mount(params, session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update")

    current_user = session["current_user_id"] && Accounts.get_user!(session["current_user_id"])
    user_file = params["file_id"] && Persistence.get_user_file(params["file_id"], current_user)

    {:ok,
     socket
     |> assign_new(:current_user, fn -> current_user end)
     |> assign(:file_id, user_file.file.id)
     |> assign(:schema, user_file.file.schema)
     |> assign(:ui, %{
       current_path: "root",
       current_edit: nil
     })}
  end

  @impl true
  def handle_event("add_prop", _val, %{assigns: %{ui: ui}} = socket) do
    Process.send_after(self(), :update_schema, 1000)

    {:noreply, update(socket, :schema, &Sch.put(&1, ui.current_path, gen_key(), Sch.string()))}
  end

  def handle_event("add_item", _val, %{assigns: %{ui: ui}} = socket) do
    Process.send_after(self(), :update_schema, 1000)
    {:noreply, update(socket, :schema, &Sch.put(&1, ui.current_path, Sch.string()))}
  end

  def handle_event("select_type", %{"type" => type, "path" => sch_path}, socket) do
    Process.send_after(self(), :update_schema, 1000)
    {:noreply, update(socket, :schema, &Sch.change_type(&1, sch_path, type))}
  end

  def handle_event("select_sch", %{"paths" => sch_path}, socket) do
    sch_path =
      case sch_path do
        [] -> "root"
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
    {:noreply,
     update(socket, :ui, fn ui ->
       ui
       |> Map.put(:current_path, sch_path)
       |> Map.put(:current_edit, sch_path)
     end)}
  end

  def handle_event("update_sch", params, socket) do
    %{"key" => key, "value" => value} = params
    sch_path = socket.assigns.ui.current_path

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, update(socket, :schema, &Sch.update(&1, sch_path, key, value))}
  end

  def handle_event("rename_key", params, socket) do
    %{"parent_path" => parent_path, "old_key" => old_key, "value" => new_key} = params

    old_key = String.slice(old_key, 0, min(255, String.length(old_key)))
    new_key = String.slice(new_key, 0, min(255, String.length(new_key)))

    socket =
      update(socket, :schema, fn schema ->
        Sch.rename_key(schema, parent_path, old_key, new_key)
      end)

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
       |> Map.put(:current_path, "root")
       |> Map.put(:current_edit, nil)
     end)}
  end

  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "newIndices" => dst_indices} = payload

    socket = update(socket, :schema, fn schema -> Sch.move(schema, src_indices, dst_indices) end)

    socket =
      update(socket, :ui, fn ui ->
        current_paths = Sch.get_paths(socket.assigns.schema, dst_indices)
        Map.put(ui, :current_path, current_paths)
      end)

    Process.send_after(self(), :update_schema, 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_schema, socket) do
    Persistence.update_file(socket.assigns.file_id, socket.assigns.schema)
    {:noreply, socket}
  end

  defp percent(byte_size, :per_mb, quota) do
    quota_byte = quota * (1024 * 1024)
    Float.floor(byte_size / quota_byte * 100, 2)
  end

  defp gen_key() do
    id = DateTime.to_unix(DateTime.now!("Etc/UTC"), :microsecond)
    id = String.slice("#{id}", 6..-1)
    "key_#{to_string(id)}"
  end
end
