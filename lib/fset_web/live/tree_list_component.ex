defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
      <%= for key <- @sch.order do %>
        <%= if @sch.properties[key].type in [:object, :array] do %>
          <article class="sort-handle">
            <details data-path="<%= input_name(@f, key) %>" phx-hook="expandableSortable" open>
              <summary class="flex filter">
                <div class="dragover-hl flex items-center w-full px-1 h-8 <%= if input_name(@f, key) in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
                  <div
                    class="indent h-full"
                    style="padding-left: <%= @ui.current_level * 1.25 %>rem"
                    data-indent="<%= (@ui.current_level + 1) * 1.25 %>rem"
                    onclick="event.preventDefault()">
                  </div>
                  <p class="flex items-center text-sm h-full" phx-click_="edit_sch" phx-value-path="<%= input_name(@f, key) %>" onclick="event.preventDefault()">
                    <span><%= key %></span>
                    <span class="mx-2">:</span>
                  </p>
                  <p class="text-xs">
                    <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">
                      <%= if @sch.properties[key].type == :object, do: "{...}", else: "[...] " %>
                    </span>
                    <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">
                      <%= if @sch.properties[key].type == :object, do: " {  }", else: "[  ] " %>
                    </span>
                  </p>
                  <div
                    class="flex-1 flex items-center h-full"
                    onclick="event.preventDefault()">
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
            data-path="<%= input_name(@f, key) %>"
            class="sort-handle flex items-center h-8 py-1 <%= if input_name(@f, key) in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>"
            style="padding-left: <%= @ui.current_level * 1.25 %>rem">

            <p class="pl-1 text-sm"><span><%= key %></span><span class="mx-2">:</span></p>
            <span class="text-sm text-blue-500"><%=  @ui.type_options[@sch.properties[key].type] %></span>
            <%= render_type_options(assigns, key) %>
          </article>
        <% end %>
      <% end %>
    """
  end

  def render_type_options(assigns, key) do
    ~L"""
      <%= if @ui.current_path == input_name(@f, key) && !is_list(@ui.current_path) do %>
        <span class="flex-1"></span>
        <div class="flex items-center h-4 ml-4 text-xs">
          <%= for {type, display_type} <- @ui.type_options do %>
            <span class="mr-1 <%= if @sch.properties[key].type == type, do: 'bg-gray-800 text-gray-200 rounded', else: 'text-gray-400 cursor-pointer' %> px-1" phx-click="select_type" phx-value-type="<%= type %>" phx-value-path="<%= @ui.current_path %>"><%= display_type %></span>
          <% end %>
        </div>

        <%= if @sch.properties[key].type in [:object, :array] do %>
          <span phx-click="add_prop" class="ml-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
        <% end %>
      <% end %>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
