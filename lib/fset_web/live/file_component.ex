defmodule FsetWeb.FileComponent do
  use FsetWeb, :live_component
  alias FsetWeb.TreeListComponent
  alias Fset.Sch

  @impl true
  def update(assigns, socket) do
    init_ui = Map.merge(assigns.ui, %{tab: 1, parent_path: assigns.f.name})

    {:ok,
     socket
     |> assign(:ui, init_ui)
     |> assign(:f, assigns.f)
     |> assign(:body, assigns.body)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div id="expandableSortable__root" phx-hook="expandableSortable" data-group="root" data-path="<%= @f.name %>"
      data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
      phx-capture-click="select_sch" phx-value-paths="root" class="grid grid-cols-fit py-8 h-full row-gap-8" id="expandableSortable__<%= @f.name %>">
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
end
