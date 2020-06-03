defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view
  alias FsetWeb.TreeListComponent
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
      <p>path : <%= @ui.current_path %></p>
      <%= f = form_for :root, "#", [class: "w-full lg:w-1/3"] %>
        <header class="flex items-center my-4">
          <span class="flex-1"></span>
          <span phx-click="add_prop" class="text-lg cursor-pointer">+</span>
        </header>
        <nav class="border min-h-screen stripe-gray text-gray-300">
          <ol>
            <%= live_component @socket, TreeListComponent, id: f.name, sch: get_in(@data, Sch.access_path("root")), ui: @ui, f: f %>
          </ol>
        </nav>
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
    {:noreply, update(socket, :ui, fn ui -> Map.put(ui, :current_path, sch_path) end)}
  end

  def handle_event("escape", _, socket) do
    {:noreply, update(socket, :ui, fn ui -> Map.put(ui, :current_path, "root") end)}
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
