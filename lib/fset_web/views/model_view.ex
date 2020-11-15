defmodule FsetWeb.ModelView do
  use FsetWeb, :view
  alias Fset.{Sch, Utils}

  def render("model.html", %{sch: sch, ui: ui} = assigns) do
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
    ~E"""
    <li class="<%= if @ui.level == @ui.tab, do: 'bg-dark-gray rounded py-4 shadow w-full' %>">
      <details <%= if Sch.array?(@sch, :homo), do: "", else: "open" %>>
        <summary>
          <%# render_doc(assigns) %>
          <div class="flex">
            <%= render_key(%{assigns | key: Utils.word_break_html("#{@key}")}) %>
            <%= render_type(assigns) %>
          </div>
          <%=# render_doc(assigns) %>
        </summary>
        <ul>
          <%= render_itself(assigns) %>
        </ul>
      </details>
    </li>
    """
  end

  defp render_file(assigns) do
    ~E"""
    <li class="flex <%= if @ui.level == @ui.tab, do: 'bg-dark-gray rounded py-4 shadow' %>">
      <%# render_doc(assigns) %>
      <%= render_key(%{assigns | key: Utils.word_break_html("#{@key}")}) %>
      <%= render_type(assigns) %>
      <%=# render_doc(assigns) %>
    </li>
    """
  end

  defp render_itself(%{ui: %{level: l, limit: limit}}) when l == limit, do: ~E""

  defp render_itself(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch, :empty) -> ~E""
      Sch.array?(assigns.sch) -> render_array(assigns)
      Sch.any_of?(assigns.sch) -> render_union(assigns)
      true -> ~E""
    end
  end

  defp render_object(assigns) do
    ~E"""
    <%= for key <- (Sch.order(@sch) ++ Map.keys(Sch.properties(@sch) || %{})) |> Enum.uniq() do %>
      <%= render("model.html", %{
        id: input_name(@path, key),
        key: key,
        sch: if(is_map(Sch.prop_sch(@sch, key)), do: Sch.prop_sch(@sch, key), else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path, key)
      }) %>
    <% end %>
    """
  end

  defp render_array(assigns) do
    ~E"""
    <%= for {data, i} <- Enum.with_index(List.wrap(Sch.items(@sch))) do %>
      <%= render("model.html", %{
        id: input_name(@path <> "[]", Integer.to_string(i)),
        key: i,
        sch: if(is_map(data), do: data, else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path <> "[]", Integer.to_string(i))
      }) %>
    <% end %>
    """
  end

  defp render_union(assigns) do
    ~E"""
    <%= for {data, i} <- Enum.with_index(List.wrap(Sch.any_of(@sch))) do %>
      <%= render("model.html", %{
        id: input_name(@path <> "[]", Integer.to_string(i)),
        key: "",
        sch: if(is_map(data), do: data, else: %{}),
        parent: @sch,
        ui: %{@ui | level: @ui.level + 1, parent_path: @path},
        path: input_name(@path <> "[]", Integer.to_string(i))
      }) %>
    <% end %>
    """
  end

  # Top/root level model. Level does not start at 0 but specified tab.
  defp render_key(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch) ->
        ~E"""
        <span class="text-blue-500 mr-2" style="padding-left: <%= @ui.level * 1.25 %>rem">record</span>
        <span class="break-words text-gray-600"><%= @key %></span>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~E"""
        <span class="text-blue-500 mr-2" style="padding-left: <%= @ui.level * 1.25 %>rem">tuple</span>
        <span class="break-words text-gray-600"><%= @key %></span>
        <span class="mx-2">=</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~E"""
        <span class="text-blue-500 mr-2" style="padding-left: <%= @ui.level * 1.25 %>rem">list</span>
        <span class="break-words text-gray-600"><%= @key %></span>
        <span class="mx-2">=</span>
        """

      Sch.any_of?(assigns.sch) ->
        ~E"""
        <span class="text-blue-500 mr-2" style="padding-left: <%= @ui.level * 1.25 %>rem">union</span>
        <span class="break-words text-gray-600"><%= @key %></span>
        <span class="mx-2">=</span>
        """

      true ->
        ~E"""
        <span class="text-blue-500 mr-2" style="padding-left: <%= @ui.level * 1.25 %>rem">field</span>
        <span class="break-words text-gray-600"><%= @key %></span>
        <span class="mx-2">:</span>
        """
    end
  end

  defp render_key(assigns) do
    cond do
      Sch.leaf?(Map.get(assigns, :parent)) ->
        ~E"""
        <span class="break-words text-gray-600" style="padding-left: <%= @ui.level * 1.25 %>rem"><%= @key %></span>
        <span class="mx-2">:</span>
        """

      Sch.any_of?(Map.get(assigns, :parent)) ->
        ~E"""
        <span class="break-words text-gray-600" style="padding-left: <%= @ui.level * 1.25 %>rem"><%= @key %></span>
        <span class="mx-2 text-base text-gray-600">|</span>
        """

      true ->
        ~E"""
        <span class="break-words text-gray-600" style="padding-left: <%= @ui.level * 1.25 %>rem"><%= @key %></span>
        <span class="mx-2">:</span>
        """
    end
  end

  # Top/root level model. Level does not start at 0 but specified tab.
  defp render_type(%{ui: %{level: l, tab: t}} = assigns) when l == t do
    cond do
      Sch.object?(assigns.sch, :empty) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">{any}</span>
        """

      Sch.object?(assigns.sch) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">{ }</span>
        """

      Sch.array?(assigns.sch, :empty) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">[any]</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">( )</span>
        """

      Sch.leaf?(assigns.sch) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch"><%= read_type(@sch, @ui) %></span>
        """

      Sch.any_of?(assigns.sch) ->
        ~E"""
        <span class="text-blue-500" style="min-width: 5ch">||</span>
        """

      true ->
        ~E"""
        <span class=""><%= read_type(@sch, @ui) %></span>
        """
    end
  end

  defp render_type(assigns) do
    cond do
      Sch.object?(assigns.sch, :empty) ->
        ~E"""
        <span class="self-center">{any}</span>
        """

      Sch.object?(assigns.sch) ->
        ~E"""
        <span class="self-center">{  }</span>
        """

      Sch.array?(assigns.sch, :empty) ->
        ~E"""
        <span class="self-center">[any]</span>
        """

      Sch.array?(assigns.sch, :homo) ->
        ~E"""
        <span class="self-center">[<%= read_type(Sch.items(@sch), @ui) %>]</span>
        """

      Sch.array?(assigns.sch, :hetero) ->
        ~E"""
        <span class="self-center">(  )</span>
        """

      Sch.leaf?(assigns.sch) ->
        ~E"""
        <span class="self-center"><%= read_type(@sch, @ui) %></span>
        """

      Sch.any_of?(assigns.sch) ->
        ~E"""
        <span class="self-center">||</span>
        """

      Sch.any?(assigns.sch) ->
        ~E"""
        <span class="self-center">any</span>
        """

      true ->
        ~E"""
        <span class="self-center"><%= read_type(@sch, @ui) %></span>
        """
    end
  end

  # defp render_doc(assigns) do
  #   ~E"""
  #   <div class="mb-2 w-full text-xs text-pink-400 opacity-75 leading-6" style="padding-left: <%= @ui.level * 1.25 %>rem" onclick="event.preventDefault()">
  #     <p><%= Sch.title(@sch) %></p>
  #     <p><%= Sch.description(@sch) %></p>
  #   </div>
  #   """
  # end

  def read_type(sch, ui) when is_map(sch) do
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
        ~E"<span class='text-indigo-400'><%= Utils.word_break_html(k) %></span>"
      end
    end) || "#invalid_type"
  end
end
