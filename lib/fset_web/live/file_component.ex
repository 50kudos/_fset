defmodule FsetWeb.FileComponent do
  use FsetWeb, :live_component
  alias FsetWeb.TreeListComponent
  alias Fset.{Sch, File}

  @impl true
  def update(assigns, socket) do
    init_ui = Map.merge(assigns.ui, %{tab: 1, parent_path: assigns.f.name})
    file = assigns.file
    section_sch = File.current_section(file.module)

    {:ok,
     socket
     |> assign(:ui, init_ui)
     |> assign(:f, assigns.f)
     |> assign(:body, Sch.get(section_sch, file.module.current_section_key) |> Sch.sanitize())
     |> assign(:name, file.name)
     |> assign(:section, file.module.current_section)}
  end

  @impl true
  def render(assigns) do
    case assigns.section do
      :main -> render_main(assigns)
      :model -> render_model(assigns)
    end
  end

  defp render_model(assigns) do
    ~L"""
    <div id="expandableSortable__<%= @f.name %>" phx-hook="expandableSortable" data-group="body" data-path="<%= @f.name %>"
      data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
      phx-capture-click="select_sch" phx-value-paths="<%= @f.name %>" class="grid grid-cols-fit py-6 h-full row-gap-6" id="expandableSortable__<%= @f.name %>">
      <span class="hidden border-box"></span>
      <%= for key <- Sch.order(@body) do %>
        <%= for f0 <- inputs_for(@f, key) do %>
          <%= live_component(@socket, TreeListComponent,
            id: f0.name,
            key: key,
            sch: Sch.prop_sch(@body, key),
            parent: @body,
            ui: @ui,
            f: f0
          ) %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_main(assigns) do
    ~L"""
    <main>
      <%= live_component(@socket, TreeListComponent,
        id: @f.name,
        key: @f.name,
        sch: @body,
        ui: @ui,
        f: @f
      ) %>
    </main>
    """
  end
end