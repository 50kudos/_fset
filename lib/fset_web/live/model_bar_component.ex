defmodule FsetWeb.ModelBarComponent do
  use FsetWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div class="flex items-center h-full space-x-2">
      <%= if selected_count = selected_count(@paths) do %>
        <button phx-click="escape" class="text-gray-600 hover:text-gray-300" title="Deselect">&times;</button>
        <span>selected <%= selected_count %></span>
        <button class="flex-1"></button>
        <button phx-click="delete" class="text-red-500 hover:text-red-600">delete</button>
      <% end %>
    </div>
    """
  end

  defp selected_count(paths) do
    length = length(paths)
    if length < 1, do: false, else: length
  end
end
