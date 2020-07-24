defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    cond do
      Sch.object?(assigns.sch) && match?(%{level: _}, assigns.ui) -> render_folder(assigns)
      Sch.object?(assigns.sch) -> render_root(assigns)
      Sch.array?(assigns.sch) -> render_folder(assigns)
      Sch.typed?(assigns.sch) -> render_file(assigns)
    end
  end

  defp render_folder(assigns) do
    ~L"""
    <nav class="sort-handle" data-path="<%= @f.name %>">
      <details data-path="<%= @f.name %>" phx-hook="expandableSortable" data-indent="<%= (@ui.level + 1) * 1.25 %>rem" open>
        <summary class="flex w-full">
          <div class="dragover-hl flex items-center w-full h-8 <%= if @f.name in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
            <%= if @ui.level > 0 do %>
              <%= render_key_type_pair(assigns) %>
            <% else %>
              <div class="flex justify-end items-center w-full h-full" onclick="event.preventDefault()">
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

  defp render_itself(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch, :empty) -> ~L""
      Sch.array?(assigns.sch) -> render_array(assigns)
    end
  end

  defp render_object(assigns) do
    ~L"""
    <%= for key <- Sch.order(@sch) do %>
      <%= for f0 <- inputs_for(@f, key) do %>
        <%= live_component(@socket, __MODULE__,
          id: f0.name,
          key: key,
          sch: Sch.prop_sch(@sch, key),
          ui: %{@ui | level: @ui.level + 1, parent_path: @f.name},
          f: f0
        ) %>
      <% end %>
    <% end %>
    """
  end

  defp render_array(assigns) do
    ~L"""
    <%= for f0 <- inputs_for(@f, nil, default: List.wrap(Sch.items(@sch))) do %>
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
      <div phx-hook="expandableSortable" data-group="root" data-path="<%= @f.name %>"
        data-current-paths="<%= Jason.encode!(List.wrap(@ui.current_path)) %>"
        phx-capture-click="select_sch" phx-value-paths="root" class="h-full">

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
          <span class="mr-1 <%= if Sch.type(@sch) == type, do: 'bg-gray-800 text-gray-200 rounded', else: 'text-gray-400 cursor-pointer' %> px-1" phx-click="select_type" phx-value-type="<%= type %>" phx-value-path="<%= @ui.current_path %>"><%= display_type %></span>
        <% end %>
      </div>

      <%= render_add_button(assigns) %>
    <% end %>
    """
  end

  defp render_add_button(assigns) do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <span phx-click="add_prop" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
        """

      Sch.array?(assigns.sch) ->
        ~L"""
        <span phx-click="add_item" class="mx-2 px-2 bg-indigo-500 rounded text-xs cursor-pointer">+</span>
        """

      true ->
        ~L""
    end
  end

  defp render_textarea(assigns) do
    ~L"""
    <textarea type="text" class="filtered p-2 w-full h-full self-start text-xs bg-indigo-800 z-10 shadow-inner text-white"
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

  defp render_type(assigns) do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <p class="text-xs flex-shrink-0">
          <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">{...}</span>
          <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">{  }</span>
        </p>
        """

      Sch.array?(assigns.sch, :empty) ->
        ~L"""
        <span class="text-sm text-blue-500">[any]</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~L"""
        <span class="text-sm text-blue-500 cursor-pointer">[<%= Map.get(Map.new(type_options()), Sch.type(Sch.items(@sch))) %>]</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~L"""
        <p class="text-xs flex-shrink-0">
          <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">[...]</span>
          <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">[  ]</span>
        </p>
        """

      true ->
        ~L"""
        <span class="text-sm text-blue-500"><%=  Map.get(Map.new(type_options()), Sch.type(@sch)) %></span>
        """
    end
  end

  defp type_options do
    [
      {Sch.type(Sch.object()), "obj"},
      {Sch.type(Sch.array()), "arr"},
      {Sch.type(Sch.string()), "str"},
      {Sch.type(Sch.number()), "num"},
      {Sch.type(Sch.boolean()), "bool"},
      {Sch.type(Sch.null()), "null"}
    ]
  end
end
