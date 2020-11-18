defmodule FsetWeb.ModelNavComponent do
  use FsetWeb, :live_component
  alias FsetWeb.ModelIndexView
  alias Fset.{Utils}

  @impl true
  def render(assigns) do
    ~L"""
    <li class="border border-gray-800 bg-gray-800 bg-opacity-25">
      <span class="pl-2 pt-2 block _sticky top-0 text-indigo-400"><%= @file.name %></span>
      <ul class="pl-2 py-2 text-xs">
        <%= if @file.type == :model do %>
          <%= for {{model_name, _}, i} <- Enum.with_index(@file.models_anchors) do %>
            <li class="sort-handle" id="<%= input_id(%{id: i}, @file.name) %>">
              <a href="#[<%= model_name %>]">
                <span class="text-gray-600 font-mono"><%= "#{i + 1}" %>.</span> <%= Utils.word_break_html(to_string model_name) %>
              </a>
            </li>
          <% end %>
        <% else %>
          <%= for {model_name, _} <- [] do %>
            <li class=""><%= Utils.word_break_html(model_name) %></li>
          <% end %>
        <% end %>
      </ul>
    </li>
    """
  end

  defp model_link(assigns) do
    ~L"""
    <%= live_patch to: Routes.main_path(@socket, :show, @current_user.email, @project_name, @file.id), class: "block" do %>
      <span class="pl-2 block sticky top-0 hover:text-black hover:text-indigo-500 bg-gray-800"><%= @file.name %></span>
    <% end %>
    """
  end
end
