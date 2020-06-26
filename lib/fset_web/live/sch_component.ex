defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Title</p>
        <input type="text" phx-blur="update_sch" phx-value-key="title" value="<%= Map.get(@sch, :title) %>" class="h-6 p-1 bg-gray-800 shadow w-full">
      </label>

      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Description</p>
        <textarea type="text" phx-blur="update_sch" phx-value-key="description" class="h-6 p-1 bg-gray-800 shadow w-full"><%= Map.get(@sch, :description) %></textarea>
      </label>
      <%= render_sch(assigns) %>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:ui, assigns.ui)
      |> assign(:type, assigns.sch.type)
      |> assign(:sch, assigns.sch)

    {:ok, socket}
  end

  def render_sch(%{type: :object} = assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxProperties"
            value="<%= Map.get(@sch, :maxProperties, 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minProperties"
            value="<%= Map.get(@sch, :minProperties, 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  def render_sch(%{type: :array} = assigns) do
    ~L"""
    <div class="grid grid-cols-2 gap-1">
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Max Items</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maxItems"
          value="<%= Map.get(@sch, :maxItems, 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Min Items</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minItems"
          value="<%= Map.get(@sch, :minItems, 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
    </div>
    """
  end

  def render_sch(%{type: :string} = assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxLength"
            value="<%= Map.get(@sch, :maxLength, 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minLength"
            value="<%= Map.get(@sch, :minLength, 0) %>"
            class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  def render_sch(%{type: :number} = assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Maximum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maximum"
          value="<%= Map.get(@sch, :maximum, 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Minimum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minimum"
          value="<%= Map.get(@sch, :minimum, 0) %>"
          class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">MultipleOf</p>
        <input type="range" phx-blur="update_sch" phx-value-key="multipleOf" value="<%= Map.get(@sch, :multipleOf) %>" min="0">
      </label>
    """
  end

  def render_sch(%{type: :boolean} = assigns) do
    ~L"""
    """
  end

  def render_sch(%{type: :null} = assigns) do
    ~L"""
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
