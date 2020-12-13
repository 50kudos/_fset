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
        |> Map.put_new(:tab, 1.5)
        |> Map.put_new(:level, 0)
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
      {true, %{models: models}} when is_list(models) -> render_model(assigns)
      {false, %{models: models}} when is_list(models) -> render_model(assigns)
    end
  end

  defp render_model(assigns) do
    ~L"""
    <div id="file_<%= @path %>" class="" phx-hook="ModelEditable">
      <ul id="<%= @path %>" class="grid grid-cols-fit gap-2 pb-6 w-full text-sm <%= if @ui.model_number, do: 'model_number' %>"
        phx-capture-click="select_sch"
        phx-value-paths="<%= @path %>"
        data-group="root"
        data-indent="1.25rem"
        role="tree"
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
    </div>
    """
  end

  defp render_main(%{models: [{main, main_sch}]} = assigns) do
    ~L"""
    <div id="file_<%= @path %>" class="" phx-hook="ModelEditable">
      <ul id="<%= @path %>" class="sort-handle grid grid-cols-fit gap-2 pb-6 w-full text-sm"
        phx-capture-click="select_sch"
        phx-value-paths="<%= @path %>"
        data-group="root"
        data-indent="1.25rem"
      >
        <%= ModelView.render("model.html", %{
          id: @path,
          key: "#{main}",
          sch: main_sch,
          ui: @ui,
          path: "#{main}"
        }) %>
      </ul>
    <div>
    """
  end
end
