defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <%= for key <- @sch.order do %>
      <%= if @sch.properties[key].type in [:object, :array] do %>
        <article class="sort-handle">
          <details data-path="<%= input_name(@f, key) %>" phx-hook="expandableSortable" open>
            <summary class="flex">
              <div class="dragover-hl flex items-center w-full h-8 <%= if input_name(@f, key) in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
                <div
                  class="indent h-full"
                  style="padding-left: <%= @ui.current_level * 1.25 %>rem"
                  data-indent="<%= (@ui.current_level + 1) * 1.25 %>rem"
                  onclick="event.preventDefault()">
                </div>

                <%= if @ui.current_edit == input_name(@f, key) do %>
                  <%= render_textarea(assigns, key) %>
                <% else %>
                  <%= render_key(assigns, key) %>

                  <p class="text-xs flex-shrink-0">
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
                <% end %>
              </div>
            </summary>

            <%= for f0 <- inputs_for(@f, key) do %>
              <%= live_component(@socket, __MODULE__, id: input_name(@f, key), sch: @sch.properties[key], ui: %{@ui | current_level: @ui.current_level + 1 }, f: f0) %>
            <% end %>
          </details>
        </article>
      <% else %>
        <article
          data-path="<%= input_name(@f, key) %>"
          class="sort-handle flex items-center h-8 <%= if input_name(@f, key) in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>"
          style="padding-left: <%= @ui.current_level * 1.25 %>rem">

          <%= if @ui.current_edit == input_name(@f, key) do %>
            <%= render_textarea(assigns, key) %>
          <% else %>
            <%= render_key(assigns, key) %>
            <span class="text-sm text-blue-500"><%=  @ui.type_options[@sch.properties[key].type] %></span>

            <%= render_type_options(assigns, key) %>
          <% end %>
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
        <span phx-click="add_prop" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
      <% end %>
    <% end %>
    """
  end

  def render_textarea(assigns, key) do
    ~L"""
    <textarea type="text" class="filtered p-2 w-full h-full self-start text-xs bg-indigo-800 bg-opacity-50 shadow-inner text-white"
      phx-hook="autoFocus"
      phx-blur="update_sch"
      phx-keydown="update_sch"
      phx-key="Enter"
      phx-value-parent_path="<%= @f.name %>"
      phx-value-old_key="<%= key %>"
      ><%= key %></textarea>
    """
  end

  def render_key(assigns, key) do
    ~L"""
    <%= if @ui.current_path == input_name(@f, key) do %>
      <p class="flex items-center text-sm h-full overflow-hidden"
        phx-click="edit_sch"
        phx-value-path="<%= input_name(@f, key) %>"
        onclick="event.preventDefault()">
        <span class="px-1 max-w-xs truncate"><%= key %></span>
        <span class="mx-2">:</span>
      </p>
    <% else %>
      <p class="flex items-center text-sm h-full overflow-hidden"
        onclick="event.preventDefault()">
        <span class="px-1 max-w-xs truncate"><%= key %></span>
        <span class="mx-2">:</span>
      </p>
    <% end %>
    """
  end
end
