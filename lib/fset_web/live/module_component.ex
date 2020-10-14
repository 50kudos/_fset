defmodule FsetWeb.ModuleComponent do
  use FsetWeb, :live_component
  alias FsetWeb.ModelComponent

  @impl true
  def update(assigns, socket) do
    init_ui = Map.merge(assigns.ui, %{tab: 1, parent_path: assigns.path})

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:ui, init_ui)
      |> update(:ui, fn ui -> Map.put(ui, :model_names, assigns.model_names) end)
    }
  end

  @impl true
  def render(assigns) do
    case assigns do
      %{models: models} when is_map(models) -> render_main(assigns)
      %{models: models} when is_list(models) -> render_model(assigns)
    end
  end

  defp render_model(assigns) do
    ~L"""
    <div id="<%= @path %>" phx-hook="moveable" data-group="body" phx-update="prepend" data-indent="1.25rem"
      phx-capture-click="select_sch" phx-value-paths="<%= @path %>" class="grid grid-cols-fit py-6 h-full gap-4">
      <%= for {key, sch} <- @models do %>
        <%= live_component(@socket, ModelComponent,
          id: input_name(@path, key),
          key: key,
          sch: sch,
          parent: %{"type" => "object", "properties" => %{}},
          ui: @ui,
          path: input_name(@path, key)
        ) %>
      <% end %>
    </div>
    """
  end

  defp render_main(assigns) do
    ~L"""
    <main id="<%= @path %>" phx-hook="moveable" data-group="body" data-indent="1.25rem"
      phx-capture-click="select_sch" phx-value-paths="<%= @path %>" class="grid grid-cols-fit py-6 h-full gap-x-6">
      <%= live_component(@socket, ModelComponent,
        id: @path,
        key: @name,
        sch: @models,
        ui: @ui,
        path: @path
      ) %>
    </main>
    """
  end
end
