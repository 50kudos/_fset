defmodule FsetWeb.SchComponent do
  use FsetWeb, :live_component
  alias Fset.Sch

  @impl true
  def render(assigns) do
    ~L"""
    <article class="mt-12">
      <%=# render_header(assigns) %>
      <%=# render_required(assigns) %>

      <h1 class="px-2 text-teal-600 text-2xl"><%= List.last(Sch.split_path(@path)) %></h1>
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
      <dt class="inline-block text-xs text-gray-600">Path :</dt>
      <dd class="inline-block text-gray-500 break-all"><%= if !is_list(@path), do: @path, else: "multi-paths" %></dd>
      <br>
      <dt class="inline-block text-xs text-gray-600">Raw :</dt>
      <dd class="inline-block text-gray-500">
        <%= link "open", to: {:data, "application/json,#{URI.encode_www_form(Jason.encode!(@sch, html_safe: true))}"}, target: "_blank", class: "underline cursor-pointer" %>
      </dd>
    </dl>
    """
  end

  defp render_title(assigns) do
    ~L"""
    <label class="block my-1">
      <p class="px-2 py-1 text-xs text-gray-700"></p>
      <textarea type="text" class="block px-2 py-1 bg-gray-900 shadow w-full"
        id="<%= @path <> ~s(_title) %>"
        phx-blur="update_sch"
        phx-hook="autoResize"
        phx-value-key="title"
        phx-value-path="<%= @path %>"
        rows="2"
        spellcheck="false"
        placeholder="Title"
        ><%= @title %></textarea>
    </label>
    """
  end

  defp render_description(assigns) do
    ~L"""
    <label class="block my-1">
      <p class="px-2 py-1 text-xs text-gray-700"></p>
      <textarea type="text" class="block px-2 py-1 bg-gray-900 shadow w-full"
        id="<%= @path <> ~s(_description) %>"
        phx-blur="update_sch"
        phx-hook="autoResize"
        phx-value-key="description"
        phx-value-path="<%= @path %>"
        rows="2"
        spellcheck="false"
        placeholder="Description"
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
        <%= for prop <- Sch.order(@sch) do %>
          <article class="my-10">
            <h1 class="px-2 text-xl text-yellow-600"><%= prop %></h1>
            <%= render_title(%{assigns | sch: Sch.get(@sch, prop), path: input_name(@path, prop), title: Sch.get(@sch, prop) |> Sch.title() }) %>
            <%= render_description(%{assigns | sch: Sch.get(@sch, prop), path: input_name(@path, prop), description: Sch.get(@sch, prop) |> Sch.description() }) %>
          </article>
          <hr class="border-gray-800">
        <% end %>
      </section>
      <div class="grid grid-cols-2">
        <label class="border border-gray-800">
          <p class="px-2 py-1 text-xs text-gray-600">Max Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxProperties"
            phx-value-path="<%= @path %>"
            value="<%= Sch.max_properties(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="updateSch__maxProperties_<%= @path %>">
        </label>
        <label class="border border-gray-800">
          <p class="px-2 py-1 text-xs text-gray-600">Min Properties</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minProperties"
            phx-value-path="<%= @path %>"
            value="<%= Sch.min_properties(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="updateSch__minProperties_<%= @path %>">
        </label>
      </div>
    """
  end

  def render_array(assigns) do
    ~L"""
    <div class="border border-gray-800">
      <p class="px-2 py-1 text-xs text-gray-600 border-b border-gray-800">Number of items ( N )</p>
      <div class="flex items-center">
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minItems"
            phx-value-path="<%= @path %>"
            value="<%= Sch.min_items(@sch) %>"
            class="flex-1 min-w-0 px-2 py-1 bg-gray-900 text-center shadow"
            id="updateSch__minItem_<%= @path %>">
        <span class="flex-1 text-center text-blue-500">≤</span>
        <span class="flex-1 text-center text-blue-500">N</span>
        <span class="flex-1 text-center text-blue-500">≤</span>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maxItems"
          phx-value-path="<%= @path %>"
          value="<%= Sch.max_items(@sch) %>"
          class="flex-1 min-w-0 px-2 py-1 bg-gray-900 text-center shadow"
          id="updateSch__maxItem_<%= @path %>">
      </div>
    </div>
    """
  end

  defp render_string(assigns) do
    ~L"""
      <div class="grid grid-cols-2">
        <label class="border border-gray-800">
          <p class="px-2 py-1 text-xs text-gray-600">Min Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="minLength"
            phx-value-path="<%= @path %>"
            value="<%= Sch.min_length(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="updateSch__minLength_<%= @path %>">
        </label>
        <label class="border border-gray-800">
          <p class="px-2 py-1 text-xs text-gray-600">Max Length</p>
          <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
            phx-hook="updateSch"
            phx-value-key="maxLength"
            phx-value-path="<%= @path %>"
            value="<%= Sch.max_length(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="updateSch__maxLength_<%= @path %>">
        </label>
        <label class="col-span-2 border border-gray-800">
          <div class="px-2 py-1 text-xs text-gray-600">
            <p>Pattern</p>
            <p>Regex is based on PCRE (Perl Compatible Regular Expressions)</p>
          </div>
          <input type="string"
            phx-hook="updateSch"
            phx-value-key="pattern"
            phx-value-path="<%= @path %>"
            value="<%= Sch.pattern(@sch) %>"
            class="px-2 py-1 bg-gray-900 shadow w-full"
            id="updateSch__pattern_<%= @path %>">
        </label>
      </div>
    """
  end

  defp render_number(assigns) do
    ~L"""
    <div class="grid grid-cols-3">
      <label class="border border-gray-800">
        <p class="px-2 py-1 text-xs text-gray-600">Maximum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="maximum"
          phx-value-path="<%= @path %>"
          value="<%= Sch.maximum(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="updateSch__maximum_<%= @path %>">
      </label>
      <label class="border border-gray-800">
        <p class="px-2 py-1 text-xs text-gray-600">Minimum</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="minimum"
          phx-value-path="<%= @path %>"
          value="<%= Sch.minimum(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="updateSch__minimum_<%= @path %>">
      </label>
      <label class="border border-gray-800">
        <p class="px-2 py-1 text-xs text-gray-600">Multiple Of</p>
        <input type="number" inputmode="numeric" pattern="[0-9]*" min="0"
          phx-hook="updateSch"
          phx-value-key="multipleOf"
          value="<%= Sch.multiple_of(@sch) %>"
          class="px-2 py-1 bg-gray-900 shadow w-full"
          id="updateSch__multipleOf_<%= @path %>">
      </label>
    </div>
    """
  end

  defp render_const(assigns) do
    ~L"""
    <label class="block border border-gray-800">
      <p class="px-2 py-1 text-xs text-gray-600">Json Value</p>
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
      <p class="p-1 text-xs text-gray-600">JSON Examples</p>
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
        <input type="checkbox" phx-click="update_sch" phx-value-key="required" phx-value-path="<%= @path %>" value="<%= checked?(@parent, @ui) %>" class="mr-1" <%= # checked?(@parent, @ui) && "checked" %>>
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
