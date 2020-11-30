defmodule FsetWeb.ModelView do
  use FsetWeb, :view
  alias Fset.{Sch, Utils}

  def render("model.html", %{sch: sch} = assigns) do
    cond do
      Sch.object?(sch) -> render_folder(assigns)
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
    <li id="<%= @path %>" class="sort-handle <%= if @ui.level == 0, do: 'bg-dark-gray py-4 shadow w-full scroll-mt-4' %>">
      <details <%= if Sch.array?(@sch, :homo), do: "", else: "open" %>>
        <summary>
          <div class="h">
            <%= render_key(%{assigns | key: Utils.word_break_html("#{@key}")}) %>
            <%= render_type(assigns) %>
          </div>
        </summary>
        <ul data-group="<%= keyed_or_indexed(@sch) %>" data-lv="<%= @ui.level %>">
          <%= render_itself(assigns) %>
        </ul>
      </details>
    </li>
    """
  end

  defp render_file(assigns) do
    ~E"""
    <li id="<%= @path %>" class="sort-handle flex <%= if @ui.level == 0, do: 'bg-dark-gray py-4 shadow' %>">
      <%= render_key(%{assigns | key: Utils.word_break_html("#{@key}")}) %>
      <%= render_type(assigns) %>
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

  defp render_key(%{ui: %{level: 0}} = assigns) do
    ~E"""
    <span class="text-blue-500 mr-2" style="padding-left: <%= (@ui.level * 1.25) + @ui.tab %>rem">
      <%= model_type_text(@sch, @ui) %>
    </span>
    <span class="k"><%= @key %></span>
    <span class="mx-2">=</span>
    """
  end

  defp render_key(assigns) do
    cond do
      Sch.any_of?(Map.get(assigns, :parent)) ->
        ~E"""
        <span class="k" style="padding-left: <%= (@ui.level * 1.25) + @ui.tab %>rem"><%= @key %></span>
        <span class="mx-2 text-base text-gray-600">|</span>
        """

      Sch.array?(Map.get(assigns, :parent), :homo) ->
        ~E"""
        <span class="k" style="padding-left: <%= (@ui.level * 1.25) + @ui.tab %>rem"></span>
        <span class="mx-2 text-base text-gray-600">└</span>
        """

      true ->
        ~E"""
        <span class="k" style="padding-left: <%= (@ui.level * 1.25) + @ui.tab %>rem"><%= @key %></span>
        <span class="mx-2">:</span>
        """
    end
  end

  defp render_type(%{ui: %{level: 0}} = assigns) do
    ~E"""
    <p class="t text-pink-500"><%= type_text(@sch, @ui) %></p>
    """
  end

  defp render_type(assigns) do
    ~E"""
    <p class="t text-pink-500 self-center"><%= type_text(@sch, @ui) %></p>
    """
  end

  def model_type_text(sch, _ui) when is_map(sch) do
    cond do
      Sch.object?(sch) -> "record"
      Sch.array?(sch, :homo) -> "list"
      Sch.array?(sch, :hetero) -> "tuple"
      Sch.any_of?(sch) -> "union"
      true -> "field"
    end
  end

  def type_text(sch, ui) when is_map(sch) do
    cond do
      Sch.object?(sch, :empty) -> "{ any }"
      Sch.object?(sch) -> "{ }"
      Sch.array?(sch, :empty) -> "[ any ]"
      Sch.array?(sch, :homo) -> ["[ ", type_text(Sch.items(sch), ui), " ]"]
      Sch.array?(sch, :hetero) -> "( )"
      Sch.string?(sch) -> "string"
      Sch.number?(sch) -> "number"
      Sch.integer?(sch) -> "integer"
      Sch.boolean?(sch) -> "bool"
      Sch.null?(sch) -> "null"
      Sch.any_of?(sch) -> "||"
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
      {:safe, "<span class='text-green-500'>#{Jason.encode_to_iodata!(Sch.const(sch))}</span>"}
    end
  end

  defp ref_type(sch, ui) do
    Enum.find_value(ui.model_names, fn {k, anchor} ->
      if "#" <> anchor == Sch.ref(sch) do
        ~E"<span class='text-indigo-400'><%= Utils.word_break_html(k) %></span>"
      end
    end) || "#invalid_type"
  end

  defp keyed_or_indexed(sch) do
    cond do
      Sch.object?(sch) -> "keyed"
      Sch.array?(sch) -> "indexed"
      Sch.any_of?(sch) -> "indexed"
      true -> raise "Not a container type"
    end
  end
end
