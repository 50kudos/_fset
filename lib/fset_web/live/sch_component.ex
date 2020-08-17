defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def render(assigns) do
    ~L"""
    <article>
      <dl class="mb-2">
        <dt class="inline-block text-xs text-gray-600">Path :</dt>
        <dd class="inline-block text-gray-500 break-all"><%= if !is_list(@ui.current_path), do: @ui.current_path, else: "multi-paths" %></dd>
        <br>
        <dt class="inline-block text-xs text-gray-600">Raw :</dt>
        <dd class="inline-block text-gray-500">
          <a href="data:application/json,<%= Jason.encode!(@sch, html_safe: true) %>" target="_blank" class="underline cursor-pointer">open</a>
        </dd>
      </dl>
      <%= render_required(assigns) %>
      <label class="block mb-2 bg-transparent">
        <p class="p-1 text-xs text-gray-600">Title</p>
        <textarea type="text" phx-blur="update_sch" phx-value-key="title" rows="2" class="p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"><%= Sch.title(@sch) %></textarea>
      </label>
      <label class="block mb-2 bg-transparent">
        <p class="p-1 text-xs text-gray-600">Description</p>
        <textarea type="text" phx-blur="update_sch" phx-value-key="description" rows="2" class="p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"><%= Sch.description(@sch) %></textarea>
      </label>
      <%= render_sch(assigns) %>
      <%= render_examples(assigns) %>
    </article>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, Map.take(assigns, [:ui, :sch, :parent, :root?]))

    {:ok, socket}
  end

  defp render_sch(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch) -> render_array(assigns)
      Sch.string?(assigns.sch) -> render_string(assigns)
      Sch.number?(assigns.sch) -> render_number(assigns)
      Sch.boolean?(assigns.sch) -> {:safe, []}
      Sch.null?(assigns.sch) -> {:safe, []}
      Sch.const?(assigns.sch) -> render_const(assigns)
      true -> {:safe, []}
    end
  end

  defp render_object(assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="block mb-2 bg-transparent">
          <p class="p-1 text-xs text-gray-600">Max Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxProperties"
            value="<%= Map.get(@sch, ~s(maxProperties), 0) %>"
            class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
            id="updateSch__maxProperties_<%= @ui.current_path %>">
        </label>
        <label class="block mb-2 bg-transparent">
          <p class="p-1 text-xs text-gray-600">Min Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minProperties"
            value="<%= Map.get(@sch, ~s(minProperties), 0) %>"
            class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
            id="updateSch__minProperties_<%= @ui.current_path %>">
        </label>
      </div>
    """
  end

  def render_array(assigns) do
    ~L"""
    <p class="p-1 text-xs text-gray-600">Number of items ( N )</p>
    <div class="flex mb-2">
      <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minItems"
          value="<%= Map.get(@sch, ~s(minItems), 0) %>"
          class="flex-1 min-w-0 h-6 p-1 bg-transparent text-center shadow"
          id="updateSch__minItem_<%= @ui.current_path %>">
      <span class="flex-1 text-center text-blue-500">≤</span>
      <span class="flex-1 text-center text-blue-500">N</span>
      <span class="flex-1 text-center text-blue-500">≤</span>
      <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
        phx-hook="updateSch"
        phx-value-key="maxItems"
        value="<%= Map.get(@sch, ~s(maxItems), 0) %>"
        class="flex-1 min-w-0 h-6 p-1 bg-transparent text-center shadow"
        id="updateSch__maxItem_<%= @ui.current_path %>">
    </div>

    """
  end

  defp render_string(assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="mb-2 bg-transparent">
          <p class="p-1 text-xs text-gray-600">Max Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxLength"
            value="<%= Map.get(@sch, ~s(maxLength), 0) %>"
            class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
            id="updateSch__maxLength_<%= @ui.current_path %>">
        </label>
        <label class="mb-2 bg-transparent">
          <p class="p-1 text-xs text-gray-600">Min Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minLength"
            value="<%= Map.get(@sch, ~s(minLength), 0) %>"
            class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
            id="updateSch__minLength_<%= @ui.current_path %>">
        </label>
      </div>
    """
  end

  defp render_number(assigns) do
    ~L"""
      <label class="block mb-2 bg-transparent">
        <p class="p-1 text-xs text-gray-600">Maximum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maximum"
          value="<%= Map.get(@sch, ~s(maximum), 0) %>"
          class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
          id="updateSch__maximum_<%= @ui.current_path %>">
      </label>
      <label class="block mb-2 bg-transparent">
        <p class="p-1 text-xs text-gray-600">Minimum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minimum"
          value="<%= Map.get(@sch, ~s(minimum), 0) %>"
          class="h-6 p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full"
          id="updateSch__minimum_<%= @ui.current_path %>">
      </label>
      <label class="block mb-2 bg-transparent">
        <p class="p-1 text-xs text-gray-600">MultipleOf</p>
        <form oninput="result.value=current_multiple_of.value">
          <input id="current_multiple_of" name="current_multiple_of" type="range" phx-blur="update_sch" phx-value-key="multipleOf" value="<%= Map.get(@sch, ~s(multipleOf)) %>" min="<%= Map.get(@sch, ~s(minimum), 0) %>" max="<%= Map.get(@sch, ~s(maximum), 0) %>">
          <output name="result" for="current_multiple_of"><%= Map.get(@sch, ~s(multipleOf)) %></output>
        </form>

      </label>
    """
  end

  defp render_const(assigns) do
    ~L"""
    <label class="block mb-2 bg-transparent">
      <p class="p-1 text-xs text-gray-600">Json Value</p>
      <textarea type="text" class="p-1 border border-gray-800 border-t-0 bg-transparent shadow w-full" rows="2"
        phx-blur="update_sch"
        phx-value-key="const">

        <%= Jason.encode_to_iodata!(Sch.const(@sch)) %>
      </textarea>
    </label>
    """
  end

  defp render_examples(assigns) do
    ~L"""
    <label class="block mt-4 mb-2 bg-transparent">
      <p class="p-1 text-xs text-gray-600">JSON Examples</p>
      <pre class="flex flex-col text-xs">
        <%= for example <- Sch.examples(@sch) do %>
          <code class="m-2"><%= Jason.encode_to_iodata!(example, pretty: true) %></code>
        <% end %>
      </pre>
    </label>
    """
  end

  defp render_required(assigns) do
    ~L"""
    <%= if Sch.object?(@parent) && !@root? do %>
      <label class="flex items-center mb-2 bg-transparent">
        <input type="checkbox" phx-click="update_sch" phx-value-key="required" value="<%= checked?(@parent, @ui) %>" class="mr-1" <%= checked?(@parent, @ui) && "checked" %>>
        <p class="p-1 text-xs text-gray-600 select-none">Required</p>
      </label>
    <% end %>
    """
  end

  defp checked?(parent, ui) do
    sch_key(ui) in Sch.required(parent)
  end

  defp sch_key(ui) do
    Sch.find_parent(ui.current_path).child_key
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
