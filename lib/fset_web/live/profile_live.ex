defmodule FsetWeb.ProfileLive do
  use FsetWeb, :live_view
  alias Fset.Accounts
  alias Fset.Project

  @impl true
  def mount(params, session, socket) do
    user =
      if params == :not_mounted_at_router do
        Accounts.get_user!(session["current_user_id"])
      else
        Accounts.get_user_by_username!(params["username"])
      end

    projects = Project.all(user.id)
    initial_form = if Enum.count(projects) == 0, do: :create, else: false

    {:ok,
     socket
     |> assign(projects: projects)
     |> assign(project_form: initial_form)
     |> assign(username: user.email)
     |> assign(current_user: user)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="w-full">
      <%= render FsetWeb.LayoutView, "_header.html", assigns %>
      <section class="mt-4 min-h-screen flex flex-wrap container mx-auto">
        <%=# bio(assigns) %>
        <article class="flex-1">
          <header class="w-full flex text-sm">
            <span class="flex-1"></span>
            <%= unless @project_form do %>
              <button class="px-2 text-indigo-200 bg-indigo-700 hover:bg-indigo-800 rounded" phx-click="new_project">
                New Project
              </button>
            <% end %>
          </header>
          <%= if @project_form do %>
            <tab-container>
              <div role="tablist" class="-mb-6 text-center md:text-left md:ml-8">
                <button type="button" role="tab" aria-selected="true" class="px-4 py-2 bg-gray-800 text-gray-400 shadow-xl border-t-2 border-gray-700 border-double">
                  New schema
                </button>
                <button type="button" role="tab" tabindex="-1" class="px-4 py-2 bg-gray-800 text-gray-400 shadow-xl border-t-2 border-gray-700 border-double">
                  Import schema
                </button>
                <button type="button" role="tab" tabindex="-1" class="px-4 py-2 bg-gray-800 text-gray-400 shadow-xl border-t-2 border-gray-700 border-double">
                  Schema from json
                </button>
              </div>
              <div role="tabpanel" class="px-6 pt-10 pb-2 border-4 border-gray-700 border-double rounded-b-lg">
                <h3 class="text-lg">Start fresh</h3>
                <p class="text-gray-500 text-sm">Create a blank schema</p>
                <div class="my-6"><%= render_new_project(:bare_schema, assigns) %></div>
              </div>
              <div role="tabpanel" class="px-6 pt-10 pb-2 border-4 border-gray-700 border-double rounded-b-lg" hidden>
                <h3 class="text-lg">Import existing schema</h3>
                <p class="text-gray-500 text-sm">Converting your schema into our system regarding fset specification</p>
                <div class="my-6"><%= render_new_project(:import_schema, assigns) %></div>
              </div>
              <div role="tabpanel" class="px-6 pt-10 pb-2 border-4 border-gray-700 border-double rounded-b-lg" hidden>
                <h3 class="text-lg">Start with json data, convert into schema</h3>
                <p class="text-gray-500 text-sm">Get started quick by automatically infer schema from json data</p>
                <div class="my-6"><%= render_new_project(:schema_from_data, assigns) %></div>
              </div>
            </tab-container>
          <% end %>
          <ul class="my-4 w-full divide-y divide-gray-900 border border-gray-900 rounded-md text-gray-400 bg-gray-800 text-sm overflow-hidden">
            <%= for project <- @projects do %>
              <li >
                <%= live_patch to: Routes.main_path(@socket, :index, @username, project.name), class: "block px-3 py-1 hover:bg-gray-700" do %>
                  <%= project.name %>
                <% end %>
              </li>
            <% end %>
          </ul>
        </article>
      </section>
    </div>
    """
  end

  def render_new_project(form_type, assigns) do
    ~L"""
    <%= f = form_for @project_form, "#", [class: "w-full", phx_submit: :create_project] %>
      <%= hidden_input f, :type, value: form_type %>
      <label class="block space-y-1 my-2">
        <h1 class="text-sm">Schema name</h1>
        <%= text_input f, :name, class: "px-2 py-1 bg-gray-200 rounded text-gray-900", autofocus: true %>
        <%= error_tag f, :name %>
      </label>
      <%= if form_type in [:import_schema, :schema_from_data] do %>
        <label class="block space-y-1 my-2">
          <h1 class="text-sm">Import url</h1>
          <%= url_input f, :url, class: "w-full px-2 py-1 bg-gray-200 rounded text-gray-900" %>
          <%= error_tag f, :url %>
        </label>
      <% end %>
      <div class="mt-4">
        <%= submit "create", class: "px-2 py-1 rounded-md text-indigo-100 bg-indigo-600 hover:bg-indigo-700" %>
        <button phx-click="cancel_new_project" type="button">cancel</button>
      </div>
    </form>
    """
  end

  defp bio(assigns) do
    ~L"""
    <aside class="w-full md:w-1/3 text-center md:text-left">
      <div class="relative inline-block w-64 h-64 rounded-full border border-gray-600 bg-gray-800">
        <span
          class="absolute text-6xl text-gray-500 tracking-widest transform -translate-x-1/2 -translate-y-1/2"
          style="top: 50%; left: 50%;"
        ><%= String.slice(@username, 0..1) %></span>
        <img src="" alt="" class="block">
      </div>
      <dl class="mt-8">
        <dt class="text-gray-600">Email</dt>
        <dd><%= @username %></dd>
      </dl>
    </aside>
    """
  end

  @impl true
  def handle_event("create_project", params, socket) do
    assigns = socket.assigns

    socket =
      case Project.create(assigns.current_user.id, params["create"]) do
        {:ok, project} ->
          project_page =
            Routes.main_path(socket, :show, assigns.username, project.name, project.main_sch.id)

          push_redirect(socket, to: project_page)

        {:error, changeset} ->
          assign(socket, :project_form, changeset)
      end

    {:noreply, socket}
  end

  def handle_event("cancel_new_project", _val, socket) do
    {:noreply, assign(socket, :project_form, false)}
  end

  def handle_event("new_project", _val, socket) do
    {:noreply, assign(socket, :project_form, :create)}
  end
end
