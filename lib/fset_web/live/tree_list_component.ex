defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
      <%= for key <- @sch.order do %>
        <%= if @sch.properties[key].type in [:object, :array] do %>
          <article class="sort-handle">
            <details data-path="<%= input_name(@f, key) %>" phx-hook="expandableSortable" open>
              <summary class="flex filter" onclick_="event.stopPropagation()">
                <div
                  class="dragover-hl flex w-full px-1 h-8 <%= if @ui.current_path == input_name(@f, key), do: 'bg-indigo-700 text-white' %>"
                  style="padding-left: <%= @ui.current_level * 1.25 %>rem"
                  data-indent="<%= (@ui.current_level + 1) * 1.25 %>rem"
                  >

                  <span class="w-4 px-1 mr-1 close-marker self-center cursor-pointer font-mono text-sm select-none">+</span>
                  <span class="w-4 px-1 mr-1 open-marker self-center cursor-pointer font-mono text-sm select-none">-</span>
                  <div
                    phx-click="select_sch"
                    phx-value-path="<%= input_name(@f, key) %>"
                    class="flex items-center w-full"
                    onclick="event.preventDefault()">

                    <span class="mr-2 px-1 bg-indigo-500 rounded text-xs"><%= if @sch.properties[key].type == :object, do: "{ }", else: "[ ]" %></span>
                    <p class="text-sm" phx-click="edit_sch" phx-value-path="<%= input_name(@f, key) %>">
                      <%= key %>
                    </p>
                    <%= render_type_options(assigns, key) %>
                  </div>
                </div>
              </summary>

              <%= for f0 <- inputs_for(@f, String.to_atom(key)) do %>
                <%= live_component(@socket, __MODULE__, id: input_name(@f, key), sch: @sch.properties[key], ui: %{@ui | current_level: @ui.current_level + 1 }, f: f0) %>
              <% end %>
            </details>
          </article>
        <% else %>
          <article
            phx-click="select_sch"
            data-path="<%= input_name(@f, key) %>"
            phx-value-path="<%= input_name(@f, key) %>"
            class="sort-handle flex items-center h-8 py-1 <%= if @ui.current_path == input_name(@f, key), do: 'bg-indigo-700 text-white' %>"
            style="padding-left: <%= @ui.current_level * 1.25 %>rem">

            <p class="pr-2 text-sm"><%= key %> : </p>
            <span class="text-sm text-blue-500"><%=  @ui.type_options[@sch.properties[key].type] %></span>
            <%= render_type_options(assigns, key) %>
          </article>
        <% end %>
      <% end %>
    """
  end

  def render_type_options(assigns, key) do
    ~L"""
      <%= if @ui.current_path == input_name(@f, key) do %>
        <span class="flex-1"></span>
        <div class="flex items-center h-4 ml-4 text-xs">
          <%= for {type, display_type} <- @ui.type_options do %>
            <span class="mr-1 <%= if @sch.properties[key].type == type, do: 'bg-gray-800 text-gray-200 rounded', else: 'text-gray-400 cursor-pointer' %> px-1" phx-click="select_type" phx-value-type="<%= type %>" phx-value-path="<%= @ui.current_path %>"><%= display_type %></span>
          <% end %>
        </div>

        <%= if @sch.properties[key].type in [:object, :array] do %>
          <span class="flex-1"></span>
          <span phx-click="add_prop" class="px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
        <% end %>
      <% end %>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
