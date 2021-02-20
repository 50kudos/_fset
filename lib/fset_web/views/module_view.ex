defmodule FsetWeb.ModuleView do
  use FsetWeb, :view
  alias FsetWeb.ModelView

  def render("show.html", assigns) do
    case assigns do
      %{models: [{:main, _}]} -> render_main(assigns)
      %{models: models} when is_list(models) -> render_model(assigns)
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
        role="tree"
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
