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
      <%= f = form_for :root, "#", [class: "flex flex-wrap w-full"] %>
        <header class="flex items-center">
          <span class="flex-1"></span>
        </header>
        <nav class="w-full lg:w-1/3 min-h-screen stripe-gray text-gray-400 overflow-auto">
          <%= live_component @socket, TreeListComponent, id: f.name, key: "root", sch: get_in(@schema, Sch.access_path("root")), ui: @ui, f: f %>
        </nav>
        <section class="w-full lg:w-1/3 p-4 bg-gray-900 text-gray-400 text-sm">
          <%= if @ui.current_path != "root" && !is_list(@ui.current_path) do %>
            <%= live_component @socket, SchComponent, id: @ui.current_path, sch: get_in(@schema, Sch.access_path(@ui.current_path)), ui: @ui %>
          <% end %>
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

  def handle_event("select_sch", %{"path" => sch_path}, socket) do
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
    %{"parent_path" => parent_path, "old_key" => old_key, "value" => new_key} = params

    new_key = if new_key == "", do: old_key, else: new_key

    socket =
      update(socket, :schema, fn schema ->
        src_path = dst_path = parent_path
        sch = get_in(schema, Sch.access_path(parent_path))
        index = Enum.find_index(sch.order, &(&1 == old_key))

        Sch.move(schema, src_path, dst_path, [index], [{new_key, index}])
      end)

    socket =
      update(socket, :ui, fn ui ->
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
    %{"oldIndices" => src_indices, "to" => dst, "newIndices" => dst_indices} = payload

    # Prepare for one-src / one-dst approach for moving items
    map_src = fn %{"from" => src} -> src end
    map_index = fn %{"index" => index} -> index end

    dst_indices_by_sources = Enum.group_by(dst_indices, map_src, map_index)
    src_indices_by_sources = Enum.group_by(src_indices, map_src, map_index)

    socket =
      update(socket, :schema, fn schema ->
        for {src, dst_indices} <- dst_indices_by_sources, reduce: schema do
          acc -> Sch.move(acc, src, dst, src_indices_by_sources[src], dst_indices)
        end
      end)

    socket =
      update(socket, :ui, fn ui ->
        current_paths =
          for {_, dst_indices} <- dst_indices_by_sources, reduce: [] do
            acc -> Sch.get_paths(socket.assigns.schema, dst, dst_indices) ++ acc
          end

        Map.put(ui, :current_path, current_paths)
      end)

    {:noreply, socket}
  end

  defp schema(schema) do
    schema
    |> Sch.put_object("root", "a")
    |> Sch.put_string("root[a]", "b")
  end
end
