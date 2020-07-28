defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    parent_assigns = Map.take(assigns, [:key, :sch, :parent, :ui, :f])

    {:ok,
     socket
     |> assign(parent_assigns)
     |> update(:ui, fn ui -> Map.put_new(ui, :level, ui.tab) end)
     |> update(:ui, fn ui -> Map.put_new(ui, :parent_path, parent_assigns.f.name) end)}
  end

  @impl true
  def render(%{sch: sch, ui: ui} = assigns) do
    cond do
      Sch.object?(sch) && match?(%{level: _}, ui) -> render_folder(assigns)
      Sch.array?(sch) -> render_folder(assigns)
      Sch.leaf?(sch) -> render_file(assigns)
    end
  end

  defp render_folder(assigns) do
    ~L"""
    <nav class="sort-handle" data-path="<%= @f.name %>">
      <details id="expandableSortable__<%= @f.name %>" phx-hook="expandableSortable" data-indent="<%= (@ui.level + 1) * 1.25 %>rem" open>
        <summary class="flex" >
          <%= render_folder_header(assigns) %>
        </summary>

        <%= render_itself(assigns) %>
      </details>
    </nav>
    """
  end

  defp render_folder_header(%{ui: %{level: _}} = assigns) do
    ~L"""
    <div class="dragover-hl flex items-center w-full h-8 <%= if @f.name in List.flatten([@ui.current_path]), do: 'bg-indigo-700 text-gray-100' %>">
      <%= render_key_type_pair(assigns) %>
    </div>
    """
  end

  # defp render_folder_header(assigns) do
  #   ~L"""
  #   <div class="flex items-center w-full h-8">
  #     <div class="flex justify-between items-center w-full h-full" onclick="event.preventDefault()">
  #       <p class="text-sm text-gray-600" onclick="event.preventDefault()">
  #         <span class="px-1"><%= @key %></span>
  #       </p>
  #       <%= if @ui.current_path == @key do %>
  #         <span phx-click="add_prop" class="mx-2 px-2 bg-gray-800 rounded text-xs cursor-pointer">+ new prop</span>
  #       <% end %>
  #     </div>
  #   </div>
  #   """
  # end

  defp render_itself(%{ui: %{level: l, limit: limit}}) when l == limit, do: {:safe, []}

  defp render_itself(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch, :empty) -> {:safe, []}
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
          parent: @sch,
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
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @f.name},
        f: f0
      ) %>
    <% end %>
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
      <% end %>

      <div
        class="flex-1 flex items-center h-full"
        onclick="event.preventDefault()">
        <%= #render_type_options(assigns) %>
      </div>
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
        {:safe, []}
    end
  end

  defp render_textarea(assigns) do
    ~L"""
    <textarea type="text" id="autoFocus__<%= @ui.current_path %>" class="filtered p-2 min-w-0 h-full self-start text-xs bg-indigo-800 z-10 shadow-inner text-white"
      phx-hook="autoFocus"
      phx-blur="rename_key"
      phx-keydown="rename_key"
      phx-key="Enter"
      phx-value-parent_path="<%= @ui.parent_path %>"
      phx-value-old_key="<%= @key %>"
      ><%= @key %></textarea>
    """
  end

  defp render_key(%{ui: %{current_path: name} = ui, f: %{name: name}} = assigns) do
    ~L"""
    <p class="flex items-center text-sm h-full overflow-hidden"
      phx-click="edit_sch"
      phx-value-path="<%= @f.name %>"
      onclick="event.preventDefault()">
      <%= render_key_(assigns) %>
    </p>
    """
  end

  defp render_key(assigns) do
    ~L"""
    <p class="flex items-center text-sm h-full overflow-hidden"
      onclick="event.preventDefault()">
      <%= render_key_(assigns) %>
    </p>
    """
  end

  defp render_key_(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <span class="text-blue-400 mr-1">record</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch) ->
        ~L"""
        <span class="text-blue-400 mr-1">list</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      true ->
        ~L"""
        <%= render_key_text(assigns) %>
        <span class="mx-2">:</span>
        """
    end
  end

  defp render_key_(assigns) do
    ~L"""
    <%= render_key_text(assigns) %>
    <span class="mx-2">:</span>
    """
  end

  defp render_key_text(assigns) do
    cond do
      Sch.array?(assigns.parent) ->
        ~L"""
        <span class="pl-1 max-w-xs truncate text-gray-600"><%= @key %></span>
        """

      true ->
        ~L"""
        <span class="pl-1 max-w-xs truncate"><%= @key %></span>
        """
    end
  end

  defp render_type(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch) ->
        {:safe, []}

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
          <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">(...)</span>
          <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">(  )</span>
        </p>
        """

      true ->
        ~L"""
        <span class="text-sm text-blue-500"><%=  Map.get(Map.new(type_options()), Sch.type(@sch)) %></span>
        """
    end
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
          <span class="close-marker self-center cursor-pointer text-sm select-none text-blue-500">(...)</span>
          <span class="open-marker self-center cursor-pointer text-sm select-none text-blue-500">(  )</span>
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
