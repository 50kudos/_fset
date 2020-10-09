defmodule FsetWeb.ModelComponent do
  use FsetWeb, :live_component
  alias Fset.{Sch, Utils}
  alias FsetWeb.MainLive, as: M
  import Fset.Main

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("add_field", %{"field" => field}, socket) do
    assigns = socket.assigns
    schema = Sch.new(assigns.key, assigns.sch)

    {_, postsch, new_schema} = add_field(schema, assigns.key, field)

    # Note: if we decide to move renderer to frontend, change the handle_info
    # from calling send_update to push_event with same parameters for client to patch
    # the DOM.
    # broadcast_and_persist!(file, add_path, postsch)
    broadcast_update_sch(assigns.ui.topic, assigns.path, postsch)

    # async_update_schema()
    {:noreply, assign(socket, :sch, Sch.get(new_schema, assigns.key))}
  end

  @impl true
  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)
    assigns = Map.take(assigns, [:key, :sch, :parent, :ui, :path])

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:current_path, M.current_path(assigns.ui))
      |> assign(:current_edit, M.current_edit(assigns.ui))
      |> assign_new(:errors, fn -> assigns.ui.errors end)
      |> update(:sch, fn sch -> Map.delete(sch, "examples") end)
      |> update(:ui, fn ui -> Map.put_new(ui, :level, ui.tab) end)
      |> update(:ui, fn ui -> Map.put_new(ui, :parent_path, assigns.path) end)
    }
  end

  @impl true
  def render(%{sch: sch, ui: ui} = assigns) do
    cond do
      Sch.object?(sch) && match?(%{level: _}, ui) -> render_folder(assigns)
      Sch.array?(sch) -> render_folder(assigns)
      Sch.leaf?(sch) -> render_file(assigns)
      Sch.any_of?(sch) -> render_folder(assigns)
      Sch.any?(sch) -> render_file(assigns)
      Sch.ref?(sch) -> render_file(assigns)
      Sch.const?(sch) -> render_file(assigns)
      true -> raise "Undefine render function for :: #{inspect(sch)}"
    end
  end

  defp render_folder(assigns) do
    ~L"""
    <nav class="sort-handle
      <%= if M.selected?(@path, @current_path), do: 'sortable-selected' %>
      <%= if @ui.level == @ui.tab, do: 'bg-dark-gray rounded py-4 shadow' %>"
      data-path="<%= @path %>">

      <details phx-hook="openable" id="openable__<%= @path %>" <%= if Sch.array?(@sch, :homo), do: "", else: "open" %>>
        <summary class="flex flex-col" >
          <%= render_folder_header(assigns) %>
        </summary>
        <article
          id="moveable__<%= @path %>"
          phx-hook="moveable"
          data-indent="<%= (@ui.level + 1) * 1.25 %>rem">

          <%= render_itself(assigns) %>
        </article>
      </details>
    </nav>
    """
  end

  defp render_folder_header(%{ui: %{level: _}} = assigns) do
    ~L"""
    <div class="relative dragover-hl flex flex-wrap items-start w-full">
      <%= if M.selected?(@path, @current_path, :single) do %>
        <p class="absolute m-1 leading-4 text-gray-900 font-mono text-xs">
          <span class="close-marker cursor-pointer select-none">+</span>
          <span class="open-marker cursor-pointer select-none">-</span>
        </p>
      <% end %>
      <%= render_key_type_pair(assigns) %>
    </div>
    """
  end

  defp render_itself(%{ui: %{level: l, limit: limit}} = assigns) when l == limit, do: ~L""

  defp render_itself(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch, :empty) -> ~L""
      Sch.array?(assigns.sch) -> render_array(assigns)
      Sch.any_of?(assigns.sch) -> render_union(assigns)
      true -> ~L""
    end
  end

  defp render_object(assigns) do
    ~L"""
    <%= for key <- (Sch.order(@sch) ++ Map.keys(Sch.properties(@sch) || %{})) |> Enum.uniq() do %>
      <%= live_component(@socket, __MODULE__,
        id: input_name(@path, key),
        key: key,
        sch: if(is_map(Sch.prop_sch(@sch, key)), do: Sch.prop_sch(@sch, key), else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path, key)
      ) %>
    <% end %>
    """
  end

  defp render_array(assigns) do
    ~L"""
    <%= for {data, i} <- Enum.with_index(List.wrap(Sch.items(@sch))) do %>
      <%= live_component(@socket, __MODULE__,
        id: input_name(@path <> "[]", Integer.to_string(i)),
        key: i,
        sch: if(is_map(data), do: data, else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path <> "[]", Integer.to_string(i))
      ) %>
    <% end %>
    """
  end

  defp render_union(assigns) do
    ~L"""
    <%= for {data, i} <- Enum.with_index(List.wrap(Sch.any_of(@sch))) do %>
      <%= live_component(@socket, __MODULE__,
        id: input_name(@path <> "[]", Integer.to_string(i)),
        key: "",
        sch: if(is_map(data), do: data, else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path <> "[]", Integer.to_string(i))
      ) %>
    <% end %>
    """
  end

  defp render_file(assigns) do
    ~L"""
    <nav class="sort-handle
      <%= if M.selected?(@path, @current_path), do: 'sortable-selected' %>
      <%= if @ui.level == @ui.tab, do: 'bg-dark-gray rounded py-4 shadow' %>"
      data-path="<%= @path %>">

      <%= render_key_type_pair(assigns) %>
    </nav>
    """
  end

  defp render_key_type_pair(assigns) do
    ~L"""
    <%# render_doc(assigns) %>
    <div class="flex w-full leading-6">
      <div
        class="indent"
        style="padding-left: <%= @ui.level * 1.25 %>rem"
        onclick="event.preventDefault()">
      </div>

      <%= if M.selected?(@path, @current_path, :single) do %>
        <%= render_key(assigns) %>
        <%= render_type_options(assigns) %>
      <% else %>
        <%= render_key(assigns) %>
        <%= render_type(assigns) %>
      <% end %>

      <div class="flex-1 px-1 text-right" onclick="event.preventDefault()">
        <div class="<%= if M.selected?(@path, @current_path, :multi), do: 'hidden' %>">
          <%= render_add_button(assigns) %>
        </div>
        <% if M.selected?(@path, @current_path, :single) do %>
        <% else %>
          &nbsp;
        <% end %>
      </div>
    </div>
    <%# render_doc(assigns) %>
    """
  end

  defp render_type_options(assigns) do
    ~L"""
    <details class="relative min-w-0" phx-hook="focusOnOpen" id="change_type_input">
      <summary class="block">
        <div class="break-words rounded cursor-pointer select-none text-gray-500 text-xs">
          <%= render_type(assigns, :no_prevent) %>
        </div>
      </summary>
      <ul class="details-menu absolute mt-1 z-10 bg-gray-300 text-gray-800 border border-gray-900 rounded text-xs">
        <li><input type="text" autofocus list="changeable_types" style="min-width: 30vw"
          phx-keyup="change_type"
          phx-key="Enter"
          phx-value-path="<%= @path %>"></li>
      </ul>
    </details>
    """
  end

  defp render_add_button(assigns) do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <span class="px-2 bg-indigo-500 rounded cursor-pointer"
          phx-click="add_field" phx-value-field="Record"
          phx-value-path="<%= @path %>"
          phx-target="<%= @myself %>">+</span>
        """

      Sch.array?(assigns.sch) ->
        ~L"""
        <span class="px-2 bg-indigo-500 rounded cursor-pointer"
          phx-click="add_field" phx-value-field="Record"
          phx-value-path="<%= @path %>"
          phx-target="<%= @myself %>">+</span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span class="px-2 bg-indigo-500 rounded cursor-pointer"
          phx-click="add_field" phx-value-field="Record"
          phx-value-path="<%= @path %>"
          phx-target="<%= @myself %>">+</span>
        """

      true ->
        ~L""
    end
  end

  defp render_textarea(assigns) do
    ~L"""
    <textarea type="text" id="autoFocus__<%= @path %>"
      class="filtered block px-2 box-border outline-none mr-2 min-w-0 h-full self-start text-xs leading-6 bg-gray-800 z-10 shadow-inner text-white"
      phx-hook="renameable"
      phx-blur="rename_key"
      phx-keydown="rename_key"
      phx-key="Enter"
      phx-value-parent_path="<%= @ui.parent_path %>"
      phx-value-old_key="<%= @key %>"
      rows="1"
      spellcheck="false"
      ><%= @key %></textarea>
    """
  end

  defp render_key(assigns) do
    ~L"""
    <div class="flex items-start text-sm"
      onclick="event.preventDefault()">
      <%= render_key_(assigns) %>
    </div>
    """
  end

  # Top/root level model. Level does not start at 0 but specified tab.
  defp render_key_(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <span class="text-blue-500 mr-2">record</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~L"""
        <span class="text-blue-500 mr-2">tuple</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~L"""
        <span class="text-blue-500 mr-2">list</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span class="text-blue-500 mr-2">union</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      true ->
        ~L"""
        <span class="text-blue-500 mr-2">field</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">:</span>
        """
    end
  end

  defp render_key_(assigns) do
    cond do
      Sch.leaf?(Map.get(assigns, :parent)) ->
        ~L"""
        <%= render_key_text(assigns) %>
        <span class="mx-2">:</span>
        """

      Sch.any_of?(Map.get(assigns, :parent)) ->
        ~L"""
        <%= render_key_text(assigns) %>
        <span class="mx-2 text-base text-gray-600">|</span>
        """

      true ->
        ~L"""
        <%= render_key_text(assigns) %>
        <span class="mx-2">:</span>
        """
    end
  end

  # Current or selected path
  defp render_key_text(%{current_path: name, path: name} = assigns) do
    ~L"""
    <p class="" style="_max-width: <%= if @ui.level == @ui.tab, do: 24, else: 12 %>rem"
      phx-click="edit_sch"
      phx-value-path="<%= @path %>"
      onclick="event.preventDefault()">
      <%= if @current_edit == @path && is_binary(@key) do %>
        <%= render_textarea(assigns) %>
      <% else %>
        <%= render_key_text_(assigns) %>
      <% end %>
    </p>
    """
  end

  defp render_key_text(assigns) do
    ~L"""
    <p class="" style="_max-width: <%= if @ui.level == @ui.tab, do: 24, else: 12 %>rem"
      onclick="event.preventDefault()">
      <%= render_key_text_(assigns) %>
    </p>
    """
  end

  defp render_key_text_(assigns) do
    cond do
      Sch.array?(Map.get(assigns, :parent), :hetero) ->
        ~L"""
        <span class="break-words text-gray-600"><%= @key %></span>
        """

      Sch.array?(Map.get(assigns, :parent), :homo) ->
        ~L"""
        <span class="break-words text-gray-600">└</span>
        """

      assigns.ui.level == assigns.ui.tab ->
        ~L"""
        <span class="break-words text-teal-500"><%= Utils.word_break_html(@key) %></span>
        """

      true ->
        ~L"""
        <span class="break-words opacity-75"><%= Utils.word_break_html(@key) %></span>
        """
    end
  end

  defp render_type(assigns, :no_prevent) do
    ~L"""
    <p class="text-blue-500 text-sm break-words whitespace-no-wrap">
      <%= render_type_(assigns) %>
    </p>
    """
  end

  defp render_type(assigns) do
    ~L"""
    <p class="text-blue-500 text-sm break-words whitespace-no-wrap" onclick="event.preventDefault()">
      <%= render_type_(assigns) %>
    </p>
    """
  end

  # Top/root level model. Level does not start at 0 but specified tab.
  defp render_type_(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch, :empty) ->
        ~L"""
        <span class="">{any}</span>
        """

      Sch.object?(assigns.sch) ->
        ~L"""
        <span class="">{ }</span>
        """

      Sch.array?(assigns.sch, :empty) ->
        ~L"""
        <span class="">[any]</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~L"""
        <span class="cursor-pointer flex">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~L"""
        <span class="self-center cursor-pointer select-none">( )</span>
        """

      Sch.leaf?(assigns.sch) ->
        ~L"""
        <span class=""><%= read_type(@sch, @ui) %></span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span class="self-center cursor-pointer select-none">||</span>
        """

      true ->
        ~L"""
        <span class=""><%= read_type(@sch, @ui) %></span>
        """
    end
  end

  defp render_type_(assigns) do
    cond do
      Sch.object?(assigns.sch, :empty) ->
        ~L"""
        <span class="self-center cursor-pointer text-sm select-none text-blue-500">{any}</span>
        """

      Sch.object?(assigns.sch) ->
        ~L"""
        <span class="self-center cursor-pointer text-sm select-none text-blue-500">{  }</span>
        """

      Sch.array?(assigns.sch, :empty) ->
        ~L"""
        <span class="">[any]</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~L"""
        <span class="cursor-pointer flex">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~L"""
        <span class="self-center cursor-pointer text-sm select-none text-blue-500">(  )</span>
        """

      Sch.leaf?(assigns.sch) ->
        ~L"""
        <span class=""><%= read_type(@sch, @ui) %></span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span class="self-center cursor-pointer select-none">||</span>
        """

      Sch.any?(assigns.sch) ->
        ~L"""
        <span class="self-center cursor-pointer select-none">any</span>
        """

      true ->
        ~L"""
        <span class="<%= error_class(assigns) %>"><%= read_type(@sch, @ui) %></span>
        """
    end
  end

  # defp render_doc(assigns) do
  #   ~L"""
  #   <div class="w-full text-xs text-orange-500 opacity-75 leading-6" style="padding-left: <%= @uiÍ.level * 1.25 %>rem" onclick="event.preventDefault()">
  #     <p><%= Sch.title(@sch) %></p>
  #     <p><%= Sch.description(@sch) %></p>
  #   </div>
  #   """
  # endÍ

  defp read_type(sch, ui) when is_map(sch) do
    cond do
      Sch.object?(sch) -> "record"
      Sch.array?(sch, :homo) -> "list"
      Sch.array?(sch, :hetero) -> "tuple"
      Sch.string?(sch) -> "str"
      Sch.number?(sch) -> "num"
      Sch.integer?(sch) -> "int"
      Sch.boolean?(sch) -> "bool"
      Sch.null?(sch) -> "null"
      Sch.any_of?(sch) -> "union"
      Sch.any?(sch) -> "any"
      Sch.ref?(sch) -> ref_type(sch, ui)
      Sch.const?(sch) -> const_type(sch)
      true -> "please define what type #{inspect(sch)} is"
    end
  end

  defp error_class(assigns) do
    for error <- assigns.errors, reduce: [] do
      acc ->
        case error.type do
          :reference ->
            if assigns.path in error.payload.path, do: ["text-red-600" | acc], else: acc

          _ ->
            acc
        end
    end
    |> Enum.join(" ")
  end

  defp const_type(sch) do
    const = Sch.const(sch)

    if is_map(const) || is_list(const) do
      "value"
    else
      {:safe, "<span class='text-green-700'>#{Jason.encode_to_iodata!(Sch.const(sch))}</span>"}
    end
  end

  defp ref_type(sch, ui) do
    Enum.find_value(ui.model_names, fn {k, anchor} ->
      if "#" <> anchor == Sch.ref(sch) do
        assigns = %{k: k}

        ~L"""
        <span class='text-teal-500'><%= Utils.word_break_html(k) %></span>
        """
      end
    end) || "#invalid_type"
  end
end
