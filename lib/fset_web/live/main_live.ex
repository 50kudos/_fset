defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.TreeListComponent
  alias FsetWeb.SchComponent
  alias Fset.Sch

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Fset.PubSub, "sch_update")

    {:ok,
     socket
     |> assign(:schema, schema(Sch.new("root")))
     |> assign(:ui, %{
       current_path: "root",
       current_edit: nil
     })}
  end

  @impl true
  def render(assigns) do
    ~L"""
      <%= f = form_for :root, "#", [class: "w-full"] %>
        <section class="flex flex-col">
          <header class="flex flex-col h-8 p-1 text-sm">

          </header>
          <div class="grid grid-cols-3" style="height: calc(100vh - 4rem)">
            <nav class="overflow-scroll shadow">
              <div class="stripe-gray min-h-full">
                <%= live_component @socket, TreeListComponent, id: f.name, key: "root", sch: Sch.get(@schema, "root"), ui: @ui, f: f %>
              </div>
            </nav>
            <aside class="p-4 text-sm shadow">
              <%= if !is_list(@ui.current_path) do %>
                <%= live_component @socket, SchComponent, id: @ui.current_path, sch: Sch.get(@schema, @ui.current_path), ui: @ui %>
              <% end %>
            </aside>
            <aside class="p-4 text-gray-500 shadow">
              <h5 class="text-lg">Storage</h4>
              <div class="my-4">
                <label for="disk" class="block my-4">
                  <p class="text-sm">Internal (of 500 KB quota):</p>
                  <progress id="disk" max="100" value="<%= percent(Fset.Storage.term_size(@schema), :per_mb, 0.5) %>" class="h-1 w-full"></progress>
                  <p>
                    <span class="text-xs"><%= Fset.Storage.term_size(@schema) %> bytes</span>
                    <span>·</span>
                    <span class="text-xs"><%= percent(Fset.Storage.term_size(@schema), :per_mb, 0.5) %>%</span>
                  </p>
                </label>
              </div>
              <hr class="border-gray-800 border-opacity-50">
              <div class="my-4">
                <p class="text-sm">External:</p>
                <a href="/auth/github" class="inline-block my-2 px-2 py-1 border border-gray-700 rounded self-end text-sm text-gray-500 hover:text-gray-400">Connect Github</a>
              </div>
            </aside>
          </div>

          <footer class="flex flex-col justify-center h-8 text-sm">
            <p class="text-center text-xs text-gray-500"><%= if !is_list(@ui.current_path), do: @ui.current_path %></p>
          </footer>
        </section>
      </form>
    """
  end

  @impl true
  def handle_event("add_prop", _val, %{assigns: %{ui: ui}} = socket) do
    {:noreply, update(socket, :schema, &Sch.put_string(&1, ui.current_path, Sch.gen_key()))}
  end

  def handle_event("add_item", _val, %{assigns: %{ui: ui}} = socket) do
    {:noreply, update(socket, :schema, &Sch.put_string(&1, ui.current_path))}
  end

  def handle_event("select_type", %{"type" => type, "path" => sch_path}, socket) do
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

    {:noreply, update(socket, :schema, &Sch.update(&1, sch_path, key, value))}
  end

  def handle_event("rename_key", params, socket) do
    %{"parent_path" => parent_path, "old_key" => old_key, "value" => new_key} = params

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

    {:noreply, socket}
  end

  defp schema(schema) do
    schema
    |> Sch.put_object("root", "a")
    |> Sch.put_string("root[a]", "b")
  end

  defp percent(byte_size, :per_mb, quota) do
    quota_byte = quota * (1024 * 1024)
    Float.floor(byte_size / quota_byte * 100, 2)
  end
end
