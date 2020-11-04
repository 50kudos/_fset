defmodule FsetWeb.ModuleComponent do
  use FsetWeb, :live_component
  alias FsetWeb.ModelComponent

  @items_per_chuck 10

  @impl true
  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)

    assigns =
      Map.take(assigns, [:id, :name, :models, :model_names, :ui, :path, :items_per_viewport])

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:items_per_viewport, fn -> Range.new(0, @items_per_chuck - 1) end)
      |> update(:ui, fn ui ->
        ui
        |> Map.put_new(:tab, 1)
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
      {true, %{models: models}} when is_map(models) -> render_main(assigns)
      {false, %{models: models}} when is_map(models) -> render_main(assigns)
      {true, %{models: models}} when is_list(models) -> render_elm_model(assigns)
      {false, %{models: models}} when is_list(models) -> render_model(assigns)
    end
  end

  defp render_elm_model(assigns) do
    ~L"""
    <div id="<%= @path %>" phx-hook="elm" phx-update="ignore">
    </div>
    """
  end

  defp render_model(assigns) do
    ~L"""
    <div id="<%= @path %>" class="grid grid-cols-fit py-6 h-full gap-3 <%= if @ui.model_number, do: 'model_number' %>"
      phx-capture-click="select_sch"
      phx-value-paths="<%= @path %>"
      phx-hook="moveable"
      data-group="body"
      data-indent="1.25rem"
    >
      <%= for {key, sch} <- Enum.slice(@models, 0..10) do %>
        <%= live_component(@socket, ModelComponent,
          id: input_name("", key),
          key: key,
          sch: sch,
          parent: Fset.Sch.New.object(),
          ui: @ui,
          path: input_name("", key)
        ) %>
      <% end %>
    </div>
    """
  end

  defp render_main(assigns) do
    ~L"""
    <main class="grid grid-cols-fit py-6 h-full gap-x-6">
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

  def load_models(assigns, %{"page" => page}) do
    models_count = Enum.count(assigns.current_models_bodies)
    chucks_count = max(1, div(models_count, @items_per_chuck))

    chuck_start = page * @items_per_chuck
    chuck_end = (page + 1) * @items_per_chuck

    {page, items_per_viewport} =
      cond do
        page <= chucks_count -> {page, Range.new(chuck_start, chuck_end - 1)}
        page > chucks_count -> {:done, Range.new(0, -1)}
      end

    assigns = Map.put(%{}, :page, page)
    _assigns = Map.put(assigns, :items_per_viewport, items_per_viewport)
  end
end
