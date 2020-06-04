defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
      <%= for key <- @sch.order do %>
        <%= if @sch.properties[key].type in [:object, :array] do %>
          <li>
            <details phx-hook="detailsTag" open>
              <summary class="flex">
                <div
                  class="flex w-full py-1 px-1 h-8 borlder-l <%= if @ui.current_path == input_name(@f, key), do: 'bg-indigo-700 text-white' %>"
                  style="padding-left: <%= @ui.current_level * 1.25 %>rem">

                  <span class="w-4 px-1 mr-1 close-marker cursor-pointer font-mono text-sm select-none">+</span>
                  <span class="w-4 px-1 mr-1 open-marker cursor-pointer font-mono text-sm select-none">-</span>
                  <div
                    phx-click="select_sch"
                    phx-value-path="<%= input_name(@f, key) %>"
                    class="flex items-center w-full"
                    onclick="event.preventDefault()">

                    <span class="mr-2 px-1 bg-indigo-500 rounded text-xs"><%= if @sch.properties[key].type == :object, do: "{ }", else: "[ ]" %></span>
                    <p class="text-sm"><%= key %></p>
                    <%= render_type_options(assigns, key) %>
                  </div>
                </div>
              </summary>

              <ol>
                <%= for f0 <- inputs_for(@f, String.to_atom(key)) do %>
                  <%= live_component(@socket, __MODULE__, id: input_name(@f, key), sch: @sch.properties[key], ui: %{@ui | current_level: @ui.current_level + 1 }, f: f0) %>
                <% end %>
              </ol>
            </details>
          </li>
        <% else %>
          <li
            phx-click="select_sch"
            phx-value-path="<%= input_name(@f, key) %>"
            class="flex items-center h-8 py-1 borlder-l <%= if @ui.current_path == input_name(@f, key), do: 'bg-indigo-700 text-white' %>"
            style="padding-left: <%= @ui.current_level * 1.25 %>rem">

            <p class="pr-2 text-sm"><%= key %> : </p>
            <span class="text-sm text-blue-500"><%=  @ui.type_options[@sch.properties[key].type] %></span>
            <%= render_type_options(assigns, key) %>
          </li>
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
