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
     |> assign(:data, %{
       properties: %{"root" => data()},
       order: ["root"]
     })
     |> assign(:ui, %{
       current_path: "root",
       current_level: 1,
       type_options: types_options()
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
          <details class="h-full" phx-hook="expandableSortable" data-path="<%= f.name %>" open>
            <summary class="flex filter" onclick="event.preventDefault()">
              <div
                phx-capture-click="select_sch"
                phx-value-path="<%= f.name %>"
                class="dragover-hl flex items-center justify-center h-8 px-1 w-full overflow-scroll"
                data-indent="<%= @ui.current_level * 1.25 %>rem" >

                <p class="flex-1 text-center text-xs text-gray-500"><%= if !is_list(@ui.current_path), do: @ui.current_path %></p>
                <%= if @ui.current_path == f.name && !is_list(@ui.current_path) do %>
                  <span phx-click="add_prop" class="px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
                <% end %>
              </div>
            </summary>
            <%= live_component @socket, TreeListComponent, id: f.name, sch: get_in(@data, Sch.access_path("root")), ui: @ui, f: f %>
          </details>
        </nav>
        <section class="w-full lg:w-1/3 p-4 bg-gray-900 text-gray-400 text-sm">
          <%= if @ui.current_path != "root" && !is_list(@ui.current_path) do %>
            <%= live_component @socket, SchComponent, id: @ui.current_path, sch: get_in(@data, Sch.access_path(@ui.current_path)), ui: @ui %>
          <% end %>
        </section>
      </form>
    """
  end

  @impl true
  def handle_event("add_prop", _val, %{assigns: %{ui: ui}} = socket) do
    {:noreply, update(socket, :data, &Sch.put_string(&1, ui.current_path, Sch.gen_key()))}
  end

  @impl true
  def handle_event("select_type", %{"type" => type, "path" => sch_path}, socket) do
    {:noreply, update(socket, :data, &Sch.change_type(&1, sch_path, type))}
  end

  @impl true
  def handle_event("select_sch", %{"path" => sch_path}, socket) do
    sch_path =
      case sch_path do
        [] -> "root"
        [a] -> a
        a -> a
      end

    {:noreply, update(socket, :ui, fn ui -> Map.put(ui, :current_path, sch_path) end)}
  end

  @impl true
  def handle_event("edit_sch", %{"path" => sch_path}, socket) do
    {:noreply, update(socket, :ui, fn ui -> Map.put(ui, :current_path, sch_path) end)}
  end

  @impl true
  def handle_event("escape", _, socket) do
    {:noreply, update(socket, :ui, fn ui -> Map.put(ui, :current_path, "root") end)}
  end

  @impl true
  def handle_event("move", payload, socket) do
    %{"oldIndices" => src_indices, "to" => dst, "newIndices" => dst_indices} = payload

    map_src = fn %{"from" => src} -> src end
    map_index = fn %{"index" => index} -> index end

    src_indices = Enum.map(src_indices, map_index)
    dst_indices_by_sources = Enum.group_by(dst_indices, map_src, map_index)

    socket =
      update(socket, :data, fn data ->
        for {src, dst_indices} <- dst_indices_by_sources, reduce: data do
          acc -> Sch.move(acc, src, dst, src_indices, dst_indices)
        end
      end)

    socket =
      update(socket, :ui, fn ui ->
        current_paths =
          for {_, dst_indices} <- dst_indices_by_sources, reduce: [] do
            acc -> Sch.get_paths(socket.assigns.data, dst, dst_indices) ++ acc
          end

        Map.put(ui, :current_path, current_paths)
      end)

    {:noreply, socket}
  end

  defp types_options() do
    [
      string: "str",
      number: "num",
      boolean: "bool",
      object: "obj",
      array: "arr",
      null: "null"
    ]
  end

  defp data do
    %{
      type: :object,
      properties: %{
        "a" => %{
          type: :object,
          properties: %{"b" => %{type: :string}},
          order: ["b"]
        }
      },
      order: ["a"]
    }
  end
end
