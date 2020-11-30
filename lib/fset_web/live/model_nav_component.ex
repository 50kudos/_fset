defmodule FsetWeb.ModelNavComponent do
  use FsetWeb, :live_component
  alias Fset.{Utils}

  @impl true
  def render(%{view: :expand} = assigns) do
    ~L"""
    <ul class="overflow-scroll h-full text-sm leading-6" style="transform: translate3d(0,0,0)">
      <%= for file <- @files do %>
        <li class="border border-gray-800 bg-gray-800 bg-opacity-25">
          <%= if file.id in @active_ids do %>
            <%= if file.id == @current_file_id do %>
              <span class="p-2 block _sticky top-0 text-lg font-thin text-pink-100 bg-pink-700 bg-opacity-75 border-b-4 border-pink-600">
                <%= file.name %>
              </span>
            <% else %>
              <%= live_patch to: Routes.main_path(@socket, :show, @current_user.email, @project_name, file.id), class: "block" do %>
                <span class="p-2 block _sticky top-0 text-lg font-thin bg-gray-800 bg-opacity-75 border-t border-b-4 border-gray-800 hover:text-pink-500">
                  <%= file.name %>
                </span>
              <% end %>
            <% end %>
            <%= render_models_anchors(%{file: file}) %>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  def render(%{view: :dropdown} = assigns) do
    ~L"""
    <ul class="overflow-scroll h-full text-sm leading-6" style="transform: translate3d(0,0,0)">
      <details>
        <summary>
          <span class="p-2 block w-full text-left text-lg font-thin text-yellow-100 bg-yellow-700 border-b-4 border-yellow-500 cursor-pointer"
            role="menu"
            data-menu-button
          >
            <%= @current_file_name %>
          </span>
        </summary>
        <details-menu role="menu">
          <div class="divide-y divide-gray-800 border border-b-4 border-gray-800 bg-gray-800 bg-opacity-25">
            <%= for file <- @files do %>
              <%= if file.id != @current_file_id do %>
                <%= live_patch to: Routes.main_path(@socket, :show, @current_user.email, @project_name, file.id),
                  class: "p-2 block text-lg font-thin hover:bg-yellow-800 focus:bg-yellow-800 hover:text-gray-300 focus:text-gray-100",
                  role: "menuitem",
                  "data-menu-button-text": "" do %>
                  <span class="">
                    <%= file.name %>
                  </span>
                <% end %>
              <% end %>
            <% end %>
          </div>
        </details-menu>
      </details>
      <%= render_models_anchors(%{file: Enum.find(@files, & &1.id == @current_file_id)}) %>
    </ul>
    """
  end

  defp render_models_anchors(assigns) do
    ~L"""
    <ul class="text-sm divide-y divide-gray-800 font-light tracking-wide">
      <%= if @file.type == :model do %>
        <%= for {{model_name, _}, i} <- Enum.with_index(@file.models_anchors) do %>
          <li class="flex hover:bg-indigo-700 hover:bg-opacity-75 hover:text-gray-300">
            <!-- <span class="text-gray-600 font-mono mr-1"><%= "#{i + 1}" %>.</span> -->
            <a href="#[<%= model_name %>]" class="w-full p-2 pl-4"><%= Utils.word_break_html(to_string model_name) %></a>
          </li>
        <% end %>
      <% else %>
        <%= for {model_name, _} <- [] do %>
          <li class=""><%= Utils.word_break_html(model_name) %></li>
        <% end %>
      <% end %>
    </ul>
    """
  end
end
