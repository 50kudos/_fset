defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component

  @keywords %{
    object: ~w(maxProperties minProperties required)a,
    array: ~w(maxItems minItems uniqueItems)a,
    string: ~w(maxLength minLength pattern)a,
    number: ~w(multipleOf maximum exclusiveMaximum minimum exclusiveMinimum)a
  }

  @impl true
  def render(assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Title</p>
        <input type="text" name="<%= @title %>" id="<%= @title %>" class="h-6 p-1 bg-gray-800 shadow w-full">
      </label>

      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Description</p>
        <textarea type="text" name="<%= @description %>" id="<%= @description %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
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
      |> assign_input_names(assigns.ui, ~w(title description)a)
      |> assign_input_names(assigns.ui, @keywords[assigns.sch.type] || [])

    {:ok, socket}
  end

  defp assign_input_names(socket, ui, keywords) do
    for keyword <- keywords, reduce: socket do
      acc ->
        assign(acc, keyword, input_name(ui.current_path, "#{keyword}"))
    end
  end

  def render_sch(%{type: :object} = assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Properties</p>
          <input type="number" name="<%= @maxProperties %>" id="<%= @maxProperties %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="block mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Properties</p>
          <input type="number" name="<%= @minProperties %>" id="<%= @minProperties %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  def render_sch(%{type: :array} = assigns) do
    ~L"""
    <label class="block mb-2 border border-gray-800 bg-gray-800">
      <p class="p-1 text-xs text-gray-600">Max Items</p>
      <input type="number" name="<%= @maxItems %>" id="<%= @maxItems %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
    </label>
    <label class="block mb-2 border border-gray-800 bg-gray-800">
      <p class="p-1 text-xs text-gray-600">Min Items</p>
      <input type="number" name="<%= @minItems %>" id="<%= @minItems %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
    </label>
    """
  end

  def render_sch(%{type: :string} = assigns) do
    ~L"""
      <div class="grid grid-cols-2 gap-1">
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Max Length</p>
          <input type="number" name="<%= @maxLength %>" id="<%= @maxLength %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
        <label class="mb-2 border border-gray-800 bg-gray-800">
          <p class="p-1 text-xs text-gray-600">Min Length</p>
          <input type="number" name="<%= @minLength %>" id="<%= @minLength %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
        </label>
      </div>
    """
  end

  def render_sch(%{type: :number} = assigns) do
    ~L"""
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Maximum</p>
        <input type="number" name="<%= @maximum %>" id="<%= @maximum %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">Minimum</p>
        <input type="number" name="<%= @minimum %>" id="<%= @minimum %>" class="h-6 p-1 bg-gray-800 shadow w-full"></textarea>
      </label>
      <label class="block mb-2 border border-gray-800 bg-gray-800">
        <p class="p-1 text-xs text-gray-600">MultipleOf</p>
        <input type="range" id="<%= @multipleOf %>" name="<%= @multipleOf %>" min="0" max="10">
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
