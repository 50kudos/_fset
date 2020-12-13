defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def render(assigns) do
    ~L"""
    <article class="mt-12">
      <%=# render_header(assigns) %>
      <%=# render_required(assigns) %>

      <h1 class="text-2xl text-indigo-400"><%= List.last(Sch.split_path(@path)) %></h1>
      <%= render_title(assigns) %>
      <%= render_description(assigns) %>
      <%= render_sch(assigns) %>
      <%= render_examples(assigns) %>
    </article>
    """
  end

  @impl true
  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)
    assigns = Map.take(assigns, [:sch, :ui, :path])

    socket =
      socket
      |> assign(assigns)
      |> assign(:ui, assigns.ui)
      |> assign(:title, Sch.title(assigns.sch))
      |> assign(:description, Sch.description(assigns.sch))

    {:ok, socket}
  end

  def render_header(assigns) do
    ~L"""
    <dl class="mb-2">
      <dt class="inline-block text-xs text-gray-400">Path :</dt>
      <dd class="inline-block text-gray-500 break-all"><%= if !is_list(@path), do: @path, else: "multi-paths" %></dd>
      <br>
      <dt class="inline-block text-xs text-gray-400">Raw :</dt>
      <dd class="inline-block text-gray-500">
        <%= link "open", to: {:data, "application/json,#{URI.encode_www_form(Jason.encode!(@sch, html_safe: true))}"}, target: "_blank", class: "underline cursor-pointer" %>
      </dd>
    </dl>
    """
  end

  defp render_title(assigns) do
    ~L"""
    <label class="block my-2 bg-gray-700 bg-opacity-20 text-gray-400 focus-within:text-blue-500">
      <p class="px-2 py-1 text-xs">Title</p>
      <textarea type="text"
        class="block px-2 py-1 text-gray-300 bg-transparent tracking-wide w-full h-full outline-none border-b border-gray-700 focus:border-blue-500"
        id="<%= @path <> ~s(_title) %>"
        phx-blur="update_sch"
        phx-hook="FieldAutoResize"
        phx-value-key="title"
        phx-value-path="<%= @path %>"
        rows="1"
        spellcheck="false"
        ><%= @title %></textarea>
    </label>
    """
  end

  defp render_description(assigns) do
    ~L"""
    <label class="block my-2 bg-gray-700 bg-opacity-20 text-gray-400 focus-within:text-blue-500">
      <p class="px-2 py-1 text-xs">Description</p>
      <textarea type="text"
        class="block px-2 py-1 text-gray-300 bg-transparent tracking-wide w-full h-full outline-none border-b border-gray-700 focus:border-blue-500"
        id="<%= @path <> ~s(_description) %>"
        phx-blur="update_sch"
        phx-hook="FieldAutoResize"
        phx-value-key="description"
        phx-value-path="<%= @path %>"
        rows="1"
        spellcheck="false"
        ><%= @description %></textarea>
    </label>
    """
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
      <section class="">
        <div class="grid grid-cols-2">
          <label class="border border-gray-700">
            <p class="px-2 py-1 text-xs text-gray-400">Max Properties</p>
            <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
              phx-hook="SchUpdate"
              phx-value-key="maxProperties"
              phx-value-path="<%= @path %>"
              value="<%= Sch.max_properties(@sch) %>"
              class="px-2 py-1 bg-gray-900 shadow w-full"
              id="SchUpdate__maxProperties_<%= @path %>">
          </label>
          <label class="border border-gray-700">
            <p class="px-2 py-1 text-xs text-gray-400">Min Properties</p>
            <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
              phx-hook="SchUpdate"
              phx-value-key="minProperties"
              phx-value-path="<%= @path %>"
              value="<%= Sch.min_properties(@sch) %>"
              class="px-2 py-1 bg-gray-900 shadow w-full"
              id="SchUpdate__minProperties_<%= @path %>">
          </label>
        </div>
        <h1 class="mt-12 mb-6 text-gray-400 underline text-lg">Properties</h1>
        <ul>
          <%= for prop <- Sch.order(@sch) do %>
            <li class="mb-8">
              <h1 class="mb-3 text-base">
                <span class="break-words"><%= prop %></span>
                <span class="px-2 rounded text-blue-500 text-sm">
                  <%= FsetWeb.ModelComponent.read_type(Sch.get(@sch, prop), @ui) %>
                </span>
              </h1>
              <%= render_title(%{assigns | sch: Sch.get(@sch, prop), path: input_name(@path, prop), title: Sch.get(@sch, prop) |> Sch.title() }) %>
              <%= render_description(%{assigns | sch: Sch.get(@sch, prop), path: input_name(@path, prop), description: Sch.get(@sch, prop) |> Sch.description() }) %>
            </li>
          <% end %>
        </ul>
      </section>
    """
  end

  def render_array(assigns) do
    ~L"""
    <div class="border border-gray-700">
      <p class="px-2 py-1 text-xs text-gray-400 border-b border-gray-700">Number of items ( N )</p>
      <div class="flex items-center">
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="SchUpdate"
            phx-value-key="minItems"
            phx-value-path="<%= @path %>"
            value="<%= Sch.min_items(@sch) %>"
            class="flex-1 min-w-0 px-2 py-1 bg-gray-900 text-center shadow"
            id="SchUpdate__minItem_<%= @path %>">
        <span class="flex-1 text-center text-blue-500">≤</span>
        <span class="flex-1 text-center text-blue-500">N</span>
        <span class="flex-1 text-center text-blue-500">≤</span>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="SchUpdate"
          phx-value-key="maxItems"
          phx-value-path="<%= @path %>"
          value="<%= Sch.max_items(@sch) %>"
          class="flex-1 min-w-0 px-2 py-1 bg-gray-900 text-center shadow"
          id="SchUpdate__maxItem_<%= @path %>">
      </div>
    </div>
    """
  end

  defp render_string(assigns) do
    ~L"""
      <div class="grid grid-cols-2">
        <label class="border border-gray-700">
          <p class="px-2 py-1 text-xs text-gray-400">Min Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="SchUpdate"
            phx-value-key="minLength"
            phx-value-path="<%= @path %>"
            value="<%= Sch.min_length(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="SchUpdate__minLength_<%= @path %>">
        </label>
        <label class="border border-gray-700">
          <p class="px-2 py-1 text-xs text-gray-400">Max Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="SchUpdate"
            phx-value-key="maxLength"
            phx-value-path="<%= @path %>"
            value="<%= Sch.max_length(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="SchUpdate__maxLength_<%= @path %>">
        </label>
        <label class="col-span-2 border border-gray-700">
          <div class="px-2 py-1 text-xs text-gray-400">
            <p>Pattern</p>
            <p>Regex is based on PCRE (Perl Compatible Regular Expressions)</p>
          </div>
          <input type="string"
            phx-hook="SchUpdate"
            phx-value-key="pattern"
            phx-value-path="<%= @path %>"
            value="<%= Sch.pattern(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="SchUpdate__pattern_<%= @path %>">
        </label>
      </div>
    """
  end

  defp render_number(assigns) do
    ~L"""
    <div class="grid grid-cols-3">
      <label class="border border-gray-700">
        <p class="px-2 py-1 text-xs text-gray-400">Maximum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="SchUpdate"
          phx-value-key="maximum"
          phx-value-path="<%= @path %>"
          value="<%= Sch.maximum(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="SchUpdate__maximum_<%= @path %>">
      </label>
      <label class="border border-gray-700">
        <p class="px-2 py-1 text-xs text-gray-400">Minimum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="SchUpdate"
          phx-value-key="minimum"
          phx-value-path="<%= @path %>"
          value="<%= Sch.minimum(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="SchUpdate__minimum_<%= @path %>">
      </label>
      <label class="border border-gray-700">
        <p class="px-2 py-1 text-xs text-gray-400">Multiple Of</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="SchUpdate"
          phx-value-key="multipleOf"
          value="<%= Sch.multiple_of(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="SchUpdate__multipleOf_<%= @path %>">
      </label>
    </div>
    """
  end

  defp render_const(assigns) do
    ~L"""
    <label class="block border border-gray-700">
      <p class="px-2 py-1 text-xs text-gray-400">Json Value</p>
      <textarea type="text" class="px-2 py-1 block bg-gray-900 shadow w-full" rows="2"
        phx-blur="update_sch"
        phx-value-key="const"
        phx-value-path="<%= @path %>">

        <%= Jason.encode_to_iodata!(Sch.const(@sch)) %>
      </textarea>
    </label>
    """
  end

  defp render_examples(assigns) do
    ~L"""
    <label class="block mt-4 mb-2">
      <p class="p-1 text-xs text-gray-400">JSON Examples</p>
      <pre class="flex flex-col text-xs">
        <%= for example <- Sch.examples(@sch) do %>
          <code id="json_output" style="background: transparent" class="my-2 json" phx-hook="syntaxHighlight"><%= Jason.encode_to_iodata!(example, pretty: true) %></code>
        <% end %>
      </pre>
    </label>
    """
  end

  defp render_required(assigns) do
    ~L"""
    <%= if Sch.object?(@parent) do %>
      <label class="flex items-center">
        <input type="checkbox" phx-click="update_sch" phx-value-key="required" phx-value-path="<%= @path %>" value="<%= checked?(@ui, @parent) %>" class="mr-1" <%= # checked?(@parent) && "checked" %>>
        <p class="p-1 text-xs text-gray-400 select-none">Required</p>
      </label>
    <% end %>
    """
  end

  defp checked?(ui, parent) do
    sch_key(ui) in Sch.required(parent)
  end

  defp sch_key(ui) do
    Sch.find_parent(M.current_path(ui.topic)).child_key
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
