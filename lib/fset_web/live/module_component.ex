defmodule FsetWeb.ModuleComponent do
  use FsetWeb, :live_component
  alias FsetWeb.ModelComponent
  alias Fset.Sch

  @impl true
  def update(assigns, socket) do
    init_ui = Map.merge(assigns.ui, %{tab: 1, parent_path: assigns.path})
    file = assigns.file
    file = Map.update!(file, :schema, fn root -> Sch.sanitize(Sch.get(root, file.id)) end)
    current_section_sch = file.schema

    {:ok,
     socket
     |> assign(:ui, init_ui)
     |> update(:ui, fn ui -> Map.put(ui, :model_names, assigns.model_names) end)
     |> assign(:path, assigns.path)
     |> assign(:body, current_section_sch)
     |> assign(:type, file.type)
     |> assign(:models, Sch.order(current_section_sch))
     |> assign(:name, file.name)}
  end

  @impl true
  def render(assigns) do
    case assigns.type do
      :main -> render_main(assigns)
      :model -> render_model(assigns)
    end
  end

  defp render_model(assigns) do
    ~L"""
    <div id="moveable__<%= @path %>" phx-hook="moveable" data-group="body" data-path="<%= @path %>"
      data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
      phx-capture-click="select_sch" phx-value-paths="<%= @path %>" class="grid grid-cols-fit py-6 h-full gap-4">
      <%= for key <- @models do %>
        <%= live_component(@socket, ModelComponent,
          id: input_name(@path, key),
          key: key,
          sch: Sch.prop_sch(@body, key),
          parent: @body,
          ui: @ui,
          path: input_name(@path, key)
        ) %>
      <% end %>
    </div>
    """
  end

  defp render_main(assigns) do
    ~L"""
    <main id="moveable__<%= @path %>" phx-hook="moveable" data-group="body" data-path="<%= @path %>"
      data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
      phx-capture-click="select_sch" phx-value-paths="<%= @path %>" class="grid grid-cols-fit py-6 h-full row-gap-6">
      <%= live_component(@socket, ModelComponent,
        id: @path,
        key: @name,
        sch: @body,
        ui: @ui,
        path: @path
      ) %>
    </main>
    """
  end
end
