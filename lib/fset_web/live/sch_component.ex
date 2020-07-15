defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def render(assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Title</p>
        <input type="text" phx-blur="update_sch" phx-value-key="title" value="<%= Map.get(@sch, ~s(title)) %>" class="h-6 p-1 bg-gray-800 shadow w-full">
      </label>

      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Description</p>
        <textarea type="text" phx-blur="update_sch" phx-value-key="description" class="h-6 p-1 bg-gray-800 shadow w-full"><%= Map.get(@sch, "description") %></textarea>
      </label>
      <%= render_sch(assigns) %>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:ui, assigns.ui)
      |> assign(:sch, assigns.sch)

    {:ok, socket}
  end

  defp render_sch(assigns) do
    cond do
      Sch.object?(assigns.sch) -> render_object(assigns)
      Sch.array?(assigns.sch) -> render_array(assigns)
      Sch.string?(assigns.sch) -> render_string(assigns)
      Sch.number?(assigns.sch) -> render_number(assigns)
      Sch.boolean?(assigns.sch) -> ~L""
      Sch.null?(assigns.sch) -> ~L""
    end
  end

  defp render_object(assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxProperties"
            value="<%= Map.get(@sch, ~s(maxProperties), 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minProperties"
            value="<%= Map.get(@sch, ~s(minProperties), 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  def render_array(assigns) do
    ~L"""
    <div class="grid grid-cols-2 gap-1">
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Max Items</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maxItems"
          value="<%= Map.get(@sch, ~s(maxItems), 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Min Items</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minItems"
          value="<%= Map.get(@sch, ~s(minItems), 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
    </div>
    """
  end

  defp render_string(assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxLength"
            value="<%= Map.get(@sch, ~s(maxLength), 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minLength"
            value="<%= Map.get(@sch, ~s(minLength), 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  defp render_number(assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Maximum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maximum"
          value="<%= Map.get(@sch, ~s(maximum), 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Minimum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minimum"
          value="<%= Map.get(@sch, ~s(minimum), 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">MultipleOf</p>
        <input type="range" phx-blur="update_sch" phx-value-key="multipleOf" value="<%= Map.get(@sch, ~s(multipleOf)) %>" min="0">
      </label>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
