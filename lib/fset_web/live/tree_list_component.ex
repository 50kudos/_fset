defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    case assigns do
      %{sch: %{type: :object}, ui: %{level: _}} ->
        render_folder(assigns)

      %{sch: %{type: :object}} ->
        render_root(assigns)

      %{sch: %{type: :array, items: _}} ->
        render_folder(assigns)

      %{sch: %{type: _}} ->
        render_file(assigns)
    end
  end

  defp render_folder(assigns) do
    ~L"""
    <nav class="sort-handle" data-path="<%= @f.name %>">
      <details data-path="<%= @f.name %>" phx-hook="expandableSortable" data-indent="<%= (@ui.level + 1) * 1.25 %>rem" class="<%= if @ui.level == 0, do: 'min-h-screen' %>" open>
        <summary class="flex w-full">
          <div class="dragover-hl flex items-center w-full h-8 <%= if @f.name in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
            <%= if @ui.level > 0 do %>
              <%= render_key_type_pair(assigns) %>
            <% else %>
              <div class="flex items-center w-full h-full justify-center" onclick="event.preventDefault()">
                <p class="flex-1 text-center text-xs text-gray-500"><%= if !is_list(@ui.current_path), do: @ui.current_path %></p>
                <%= if @ui.current_path == @key do %>
                  <span phx-click="add_prop" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </summary>

        <%= render_itself(assigns) %>
      </details>
    </nav>
    """
  end

  defp render_itself(%{sch: %{type: :object}} = assigns) do
    ~L"""
    <%= for key <- @sch.order do %>
      <%= for f0 <- inputs_for(@f, key) do %>
        <%= live_component(@socket, __MODULE__,
          id: f0.name,
          key: key,
          sch: @sch.properties[key],
          ui: %{@ui | level: @ui.level + 1, parent_path: @f.name},
          f: f0
        ) %>
      <% end %>
    <% end %>
    """
  end

  defp render_itself(%{sch: %{type: :array, items: item}} = assigns) when item == %{} do
    ~L"""
    """
  end

  defp render_itself(%{sch: %{type: :array}} = assigns) do
    ~L"""
    <%= for f0 <- inputs_for(@f, nil, default: List.wrap(@sch.items)) do %>
      <%= live_component(@socket, __MODULE__,
        id: f0.name,
        key: f0.index,
        sch: f0.data,
        ui: %{@ui | level: @ui.level + 1, parent_path: @f.name},
        f: f0
      ) %>
    <% end %>
    """
  end

  defp render_root(assigns) do
    ~L"""
    <nav>
      <div phx-hook="expandableSortable" data-group="root" data-path="<%= @f.name %>">
        <%= render(
          assigns
          |> put_in([:ui, :level], 0)
          |> put_in([:ui, :parent_path], @f.name)
        ) %>
      </div>
    </nav>
    """
  end

  defp render_file(assigns) do
    ~L"""
    <nav class="sort-handle" data-path="<%= @f.name %>">
      <%= render_key_type_pair(assigns) %>
    </nav>
    """
  end

  defp render_key_type_pair(assigns) do
    ~L"""
    <div class="flex items-center w-full h-8 <%= if @f.name in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
      <div
        class="indent h-full"
        style="padding-left: <%= @ui.level * 1.25 %>rem"
        onclick="event.preventDefault()">
      </div>

      <%= if @ui.current_edit == @f.name && is_binary(@key) do %>
        <%= render_textarea(assigns) %>
      <% else %>
        <%= render_key(assigns) %>
        <%= render_type(assigns) %>

        <div
          class="flex-1 flex items-center h-full"
          onclick="event.preventDefault()">
          <%= render_type_options(assigns) %>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_type_options(assigns) do
    ~L"""
    <%= if @ui.current_path == @f.name && !is_list(@ui.current_path) do %>
      <span class="flex-1"></span>
      <div class="flex items-center h-4 ml-4 text-xs">
        <%= for {type, display_type} <- type_options() do %>
          <span class="mr-1 <%= if @sch.type == type, do: 'bg-gray-800 text-gray-200 rounded', else: 'text-gray-400 cursor-pointer' %> px-1" phx-click="select_type" phx-value-type="<%= type %>" phx-value-path="<%= @ui.current_path %>"><%= display_type %></span>
        <% end %>
      </div>

      <%= render_add_button(assigns, @sch.type) %>
    <% end %>
    """
  end

  defp render_add_button(assigns, :object) do
    ~L"""
    <span phx-click="add_prop" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
    """
  end

  defp render_add_button(assigns, :array) do
    ~L"""
    <span phx-click="add_item" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
    """
  end

  defp render_add_button(assigns, _), do: ~L""

  defp render_textarea(assigns) do
    ~L"""
    <textarea type="text" class="filtered p-2 w-full h-full self-start text-xs bg-indigo-800 bg-opacity-50 shadow-inner text-white"
      phx-hook="autoFocus"
      phx-blur="rename_key"
      phx-keydown="rename_key"
      phx-key="Enter"
      phx-value-parent_path="<%= @ui.parent_path %>"
      phx-value-old_key="<%= @key %>"
      ><%= @key %></textarea>
    """
  end

  defp render_key(assigns) do
    ~L"""
    <%= if @ui.current_path == @f.name do %>
      <p class="flex items-center text-sm h-full overflow-hidden"
        phx-click="edit_sch"
        phx-value-path="<%= @f.name %>"
        onclick="event.preventDefault()">
        <span class="px-1 max-w-xs truncate"><%= @key %></span>
        <span class="mx-2">:</span>
      </p>
    <% else %>
      <p class="flex items-center text-sm h-full overflow-hidden"
        onclick="event.preventDefault()">
        <span class="px-1 max-w-xs truncate"><%= @key %></span>
        <span class="mx-2">:</span>
      </p>
    <% end %>
    """
  end

  defp render_type(%{sch: %{type: :object}} = assigns) do
    ~L"""
    <p class="text-xs flex-shrink-0">
      <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">{...}</span>
      <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">{  }</span>
    </p>
    """
  end

  defp render_type(%{sch: %{type: :array, items: item}} = assigns) when item == %{} do
    ~L"""
    <span class="text-sm text-blue-500">[ ]</span>
    """
  end

  defp render_type(%{sch: %{type: :array, items: item}} = assigns) when is_map(item) do
    ~L"""
    <span class="text-sm text-blue-500 cursor-pointer">[<%=  type_options()[@sch.items.type] %>]</span>
    """
  end

  defp render_type(%{sch: %{type: :array, items: items}} = assigns) when is_list(items) do
    ~L"""
    <p class="text-xs flex-shrink-0">
      <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">[...]</span>
      <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">[  ]</span>
    </p>
    """
  end

  defp render_type(assigns) do
    ~L"""
    <span class="text-sm text-blue-500"><%=  type_options()[@sch.type] %></span>
    """
  end

  defp type_options do
    [
      string: "str",
      number: "num",
      boolean: "bool",
      object: "obj",
      array: "arr",
      null: "null"
    ]
  end
end
