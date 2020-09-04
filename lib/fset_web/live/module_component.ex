defmodule FsetWeb.ModuleComponent do
  use FsetWeb, :live_component
  alias FsetWeb.ModelComponent
  alias Fset.Sch

  @impl true
  def update(assigns, socket) do
    init_ui = Map.merge(assigns.ui, %{tab: 1, parent_path: assigns.f.name})
    file = assigns.file
    file = Map.update!(file, :schema, fn root -> Sch.sanitize(Sch.get(root, file.id)) end)
    current_section_sch = file.schema

    {:ok,
     socket
     |> assign(:ui, init_ui)
     |> update(:ui, fn ui ->
       model_names =
         for k <- Sch.order(current_section_sch), reduce: %{} do
           acc ->
             model_sch = Sch.prop_sch(current_section_sch, k)
             Map.put(acc, k, Sch.anchor(model_sch))
         end

       Map.put(ui, :model_names, model_names)
     end)
     |> assign(:f, assigns.f)
     |> assign(:body, current_section_sch)
     |> assign(:type, file.type)
     |> assign(:models, Sch.defs_order(current_section_sch))
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
    <div id="moveable__<%= @f.name %>" phx-hook="moveable" data-group="body" data-path="<%= @f.name %>"
      data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
      phx-capture-click="select_sch" phx-value-paths="<%= @f.name %>" class="grid grid-cols-fit py-6 h-full row-gap-6">
      <%= for key <- @models do %>
        <%= for f0 <- inputs_for(@f, key) do %>
          <%= live_component(@socket, ModelComponent,
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
      <%= live_component(@socket, ModelComponent,
        id: @f.name,
        key: @name,
        sch: @body,
        ui: @ui,
        f: @f
      ) %>
    </main>
    """
  end
end
