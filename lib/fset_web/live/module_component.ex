defmodule FsetWeb.ModuleComponent do
  use FsetWeb, :live_component
  alias FsetWeb.{ModelComponent, ModelView}

  @impl true
  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)
    assigns = Map.take(assigns, [:id, :name, :models, :model_names, :ui, :path])

    socket =
      socket
      |> assign(assigns)
      |> update(:ui, fn ui ->
        ui
        |> Map.put_new(:tab, 1)
        |> Map.put_new(:level, 1)
        |> Map.put_new(:model_number, false)
        |> Map.put_new(:file_id, assigns.id)
        |> Map.put(:model_names, assigns.model_names)
        |> Map.put(:parent_path, assigns.path)
        |> case do
          %{model_number: true} = ui -> %{ui | tab: 3}
          ui -> ui
        end
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    case {connected?(assigns.socket), assigns} do
      {true, %{models: [{:main, _}]}} -> render_main(assigns)
      {false, %{models: [{:main, _}]}} -> render_main(assigns)
      {true, %{models: models}} when is_list(models) -> render_readonly_model(assigns)
      {false, %{models: models}} when is_list(models) -> render_readonly_model(assigns)
    end
  end

  defp render_elm_model(assigns) do
    ~L"""
    <div id="file_<%= @path %>" class="h-screen" phx-hook="elm" phx-update="ignore">
    </div>
    """
  end

  defp render_readonly_model(assigns) do
    ~L"""
    <div id="file_<%= @path %>" class="h-screen">
      <main class="overflow-y-scroll overscroll-y-none h-full relative">
        <ul id="<%= @path %>" class="grid grid-cols-fit pb-6 gap-2 w-full text-sm <%= if @ui.model_number, do: 'model_number' %>"
          phx-capture-click="select_sch"
          phx-value-paths="<%= @path %>"
          phx-hook="moveable"
          data-group="body"
          data-indent="1.25rem"
        >
          <%= for {key, sch} <- @models do %>
            <%= ModelView.render("model.html", %{
              id: input_name("", key),
              key: key,
              sch: sch,
              parent: Fset.Sch.New.object(),
              ui: @ui,
              path: input_name("", key)
            }) %>
          <% end %>
        </ul>
      </main>
    </div>
    """
  end

  defp render_model(assigns) do
    ~L"""
    <div id="file_<%= @path %>" class="h-screen">
      <main id="virtual_scroller" class="overflow-y-scroll overscroll-y-none h-full relative">
        <ul id="<%= @path %>" class="grid grid-cols-fit pb-6 gap-2 w-full <%= if @ui.model_number, do: 'model_number' %>"
          phx-capture-click="select_sch"
          phx-value-paths="<%= @path %>"
          phx-hook="moveable"
          data-group="body"
          data-indent="1.25rem"
        >
          <%= for {key, sch} <- @models do %>
            <%= live_component(@socket, ModelComponent,
              id: input_name("", key),
              key: key,
              sch: sch,
              parent: Fset.Sch.New.object(),
              ui: @ui,
              path: input_name("", key)
            ) %>
          <% end %>
        </ul>
      </main>
    </div>
    """
  end

  defp render_main(assigns) do
    ~L"""
    <ul class="grid grid-cols-fit py-6 h-full gap-x-6">
      <%= live_component(@socket, ModelComponent,
        id: @path,
        key: "#{elem(hd(@models), 0)}",
        sch: elem(hd(@models), 1),
        ui: @ui,
        path: @path
      ) %>
    </ul>
    """
  end

  def load_models(assigns, %{"scrollTop" => scrollTop}) do
  end
end
