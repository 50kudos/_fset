defmodule FsetWeb.ModelBarComponent do
  use FsetWeb, :live_component
  alias FsetWeb.MainLive, as: M

  @impl true
  def render(assigns) do
    ~L"""
    <%= if selected_count = selected_count(@except) do %>
      <div class="flex items-center h-full space-x-2">
        <button phx-click="escape" class="text-gray-600 hover:text-gray-300" title="Deselect">&times;</button>
        <span>selected <%= selected_count %></span>
        <button class="flex-1"></button>
        <button phx-click="delete" class="text-red-500 hover:text-red-600">delete</button>
      </div>
    <% end %>
    """
  end

  defp selected_count(except) do
    length = length(List.wrap(M.current_path()) -- List.wrap(except))
    if length < 1, do: false, else: length
  end
end
