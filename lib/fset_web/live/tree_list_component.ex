defmodule FsetWeb.TreeListComponent do
  use FsetWeb, :live_component
  alias Fset.{Sch, Module, Utils}

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
     |> update(:sch, fn sch -> Map.delete(sch, "examples") end)
     |> update(:ui, fn ui -> Map.put_new(ui, :level, ui.tab) end)
     |> update(:ui, fn ui -> Map.put_new(ui, :parent_path, parent_assigns.f.name) end)}
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
    <nav class="sort-handle" data-path="<%= @f.name %>">
      <details phx-hook="openable" id="openable__<%= @f.name %>" <%= if Sch.array?(@sch, :homo), do: "", else: "open" %>>
        <summary class="flex flex-col" >
          <%= render_folder_header(assigns) %>
        </summary>
        <article
          id="moveable__<%= @f.name %>"
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
      <%= if selected?(@f, @ui, :single) do %>
        <p class="absolute m-1 leading-4 text-gray-900 font-mono text-xs">
          <span class="close-marker cursor-pointer select-none">+</span>
          <span class="open-marker cursor-pointer select-none">-</span>
        </p>
      <% end %>
      <%= render_key_type_pair(assigns) %>
    </div>
    """
  end

  # defp render_inline_type(%{sch: sch} = assigns) do
  #   cond do
  #     Sch.object?(sch) ->
  #       ~L"""
  #       <div class="flex items-center ml-1 border border-blue-900 rounded leading-snug">
  #         <%= for {k, sch_} <- Sch.properties(sch) do %>
  #           <p class="px-1 border-r last:border-r-0 border-blue-900">
  #             <span class=""><%= k %></span>
  #             <span class="">:</span>
  #             <span class="text-blue-500"><%=read_type(sch_) %></span>
  #           </p>
  #         <% end %>
  #       </div>
  #       """

  #     Sch.array?(sch, :hetero) ->
  #       ~L"""
  #       <div class="flex items-center ml-1 border border-blue-900 rounded leading-snug">
  #         <%= for sch_ <- Sch.items(sch) do %>
  #           <p class="px-1 border-r last:border-r-0 border-blue-900">
  #             <span class="text-blue-500"><%=read_type(sch_) %></span>
  #           </p>
  #         <% end %>
  #       </div>
  #       """

  #     true ->
  #       ~L""
  #   end
  # end

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

  defp render_union(assigns) do
    ~L"""
    <%= for f0 <- inputs_for(@f, nil, default: Sch.any_of(@sch)) do %>
      <%= live_component(@socket, __MODULE__,
        id: f0.name,
        key: "",
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
    <%# render_doc(assigns) %>
    <div class="flex w-full leading-6 <%= if selected?(@f, @ui), do: 'bg-indigo-700 bg-opacity-25' %>">
      <div
        class="indent"
        style="padding-left: <%= @ui.level * 1.25 %>rem"
        onclick="event.preventDefault()">
      </div>

      <%= if @ui.current_edit == @f.name && is_binary(@key) do %>
        <%= render_textarea(assigns) %>
        <%= render_type(assigns) %>
      <% else %>
        <%= if selected?(@f, @ui, :single) do %>
          <%= render_key(assigns) %>
          <%= render_type_options(assigns) %>
        <% else %>
          <%= render_key(assigns) %>
          <%= render_type(assigns) %>
        <% end %>
      <% end %>

      <div class="flex-1 px-1 text-right" onclick="event.preventDefault()">
        <%= if selected?(@f, @ui, :single) && @ui.current_edit != @f.name do %>
          <%= render_add_button(assigns) %>
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
    <%= if selected?(@f, @ui, :single) do %>
      <details class="relative min-w-0" phx-hook="focusOnOpen" id="change_type_input">
        <summary class="block">
          <div class="break-words rounded cursor-pointer select-none text-gray-500 text-xs">
            <%= render_type(assigns, :no_prevent) %>
          </div>
        </summary>
        <ul class="details-menu absolute mt-1 z-10 bg-gray-300 text-gray-800 border border-gray-900 rounded text-xs">
          <li><input type="text" autofocus list="changeable_types" phx-keyup="change_type" phx-key="Enter" style="min-width: 30vw" ></li>
          <datalist id="changeable_types">
            <%= for type_text <- text_val_types(@ui) do %>
              <option class="px-2 py-1 hover:bg-gray-800 hover:text-gray-300 bg-opacity-75 cursor-pointer border-b border-gray-500 last:border-0"
                value="<%= type_text %>">
                <%= type_text %>
              </option>
            <% end %>
        </datalist>
        </ul>
      </details>
    <% end %>
    """
  end

  defp render_add_button(assigns) do
    cond do
      Sch.object?(assigns.sch) ->
        ~L"""
        <span phx-click="add_model" phx-value-model="Record" class="px-2 bg-indigo-500 rounded cursor-pointer">+</span>
        """

      Sch.array?(assigns.sch) ->
        ~L"""
        <span phx-click="add_model" phx-value-model="Record" class="px-2 bg-indigo-500 rounded cursor-pointer">+</span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span phx-click="add_model" phx-value-model="Record" class="px-2 bg-indigo-500 rounded cursor-pointer">+</span>
        """

      true ->
        ~L""
    end
  end

  defp render_textarea(assigns) do
    ~L"""
    <textarea type="text" id="autoFocus__<%= @ui.current_path %>"
      class="filtered px-2 box-border outline-none mr-2 min-w-0 h-full w-full self-start text-xs leading-6 bg-gray-800 z-10 shadow-inner text-white"
      phx-hook="textArea"
      phx-blur="rename_key"
      phx-keydown="rename_key"
      phx-key="Enter"
      phx-value-parent_path="<%= @ui.parent_path %>"
      phx-value-old_key="<%= @key %>"
      rows="1"
      ><%= @key %></textarea>
    """
  end

  defp render_key(assigns) do
    ~L"""
    <div class="flex items-baseline text-sm"
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
        <span class="text-blue-400 mr-2">record</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~L"""
        <span class="text-blue-400 mr-2">tuple</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~L"""
        <span class="text-blue-400 mr-2">list</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      Sch.any_of?(assigns.sch) ->
        ~L"""
        <span class="text-blue-400 mr-2">union</span>
        <%= render_key_text(assigns) %>
        <span class="mx-2">=</span>
        """

      true ->
        ~L"""
        <span class="text-blue-400 mr-2">field</span>
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
  defp render_key_text(%{ui: %{current_path: name}, f: %{name: name}} = assigns) do
    ~L"""
    <p class="" style="max-width: 12rem"
      phx-click="edit_sch"
      phx-value-path="<%= @f.name %>"
      onclick="event.preventDefault()">
      <%= render_key_text_(assigns) %>
    </p>
    """
  end

  defp render_key_text(assigns) do
    ~L"""
    <p class="" style="max-width: 12rem"
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

      true ->
        ~L"""
        <span class="break-words"><%= Utils.word_break_html(@key) %></span>
        """
    end
  end

  defp render_type(assigns, :no_prevent) do
    ~L"""
    <p class="text-blue-500 text-sm break-words flex-shrink-0">
      <%= render_type_(assigns) %>
    </p>
    """
  end

  defp render_type(assigns) do
    ~L"""
    <p class="text-blue-500 text-sm break-words flex-shrink-0" onclick="event.preventDefault()">
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
        <span class="cursor-pointer">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
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
        <span class="cursor-pointer">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
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

  defp selected?(f, ui), do: f.name in List.flatten([ui.current_path])
  defp selected?(f, ui, :multi), do: selected?(f, ui) && is_list(ui.current_path)
  defp selected?(f, ui, :single), do: selected?(f, ui) && !is_list(ui.current_path)

  defp read_type(sch, ui) when is_map(sch) do
    ref_type = fn sch ->
      Enum.find_value(ui.model_names, fn {k, anchor} ->
        if "#" <> anchor == Sch.ref(sch) do
          Utils.word_break_html(k)
        end
      end)
    end

    cond do
      Sch.object?(sch) -> "record"
      Sch.array?(sch, :homo) -> "list"
      Sch.array?(sch, :hetero) -> "tuple"
      Sch.string?(sch) -> "str"
      Sch.number?(sch) -> "num"
      Sch.boolean?(sch) -> "bool"
      Sch.null?(sch) -> "null"
      Sch.any_of?(sch) -> "union"
      Sch.any?(sch) -> "any"
      Sch.ref?(sch) -> ref_type.(sch)
      Sch.const?(sch) -> const_type(sch)
      true -> "please define what type #{inspect(sch)} is"
    end
  end

  defp text_val_types(ui) do
    Module.changable_types() ++ Map.keys(ui.model_names)
  end

  defp error_class(assigns) do
    for error <- assigns.ui.errors, reduce: [] do
      acc ->
        case error.type do
          :reference ->
            if assigns.f.name in error.payload.path, do: ["text-red-600" | acc], else: acc

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
end
