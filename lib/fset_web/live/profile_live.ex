defmodule FsetWeb.ProfileLive do
  use FsetWeb, :live_view
  alias Fset.Accounts
  alias Fset.Project
  alias Fset.Module

  @impl true
  def mount(params, session, socket) do
    user =
      if params == :not_mounted_at_router do
        Accounts.get_user!(session["current_user_id"])
      else
        Accounts.get_user_by_username(params["username"])
      end

    projects = Project.all(user.id)

    {:ok,
     socket
     |> assign(projects: projects)
     |> assign(username: user.email)
     |> assign(current_user: user)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="w-full">
      <%= render FsetWeb.LayoutView, "_header.html", assigns %>
      <section class="h-screen w-2/3 mx-auto flex flex-col items-center justify-center">
        <ul>
          <%= for project <- @projects do %>
            <li>
              <%= live_redirect project.name, to: Routes.main_path(@socket, :index, @username, project.name) %>
            </li>
          <% end %>
        </ul>
        <div class="w-full flex flex-col items-center space-y-4">
          <button class="w-full md:w-1/2 h-32 border border-gray-800 hover:bg-indigo-800 text-2xl font-hairline rounded" phx-click="create_project">
            Create Project
          </button>
          <button class="w-full md:w-1/2 h-32 border border-gray-800 hover:bg-indigo-800 text-2xl font-hairline rounded border-dashed">
            Import Schema
          </button>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def handle_event("create_project", _val, socket) do
    # encoded = Module.encode(%{})
    uploaded_file = %{
      path:
        Path.expand(
          "../../../test/support/fixtures/sch_samples/camel-yaml-endpoint.json",
          __DIR__
        )
    }

    {:ok, encoded} =
      Project.load(uploaded_file, encoder: fn a -> Module.encode(a, defs_per_file: 50) end)

    files = Module.init_files(encoded)

    {:ok, project} = Project.create_with_user(files, socket.assigns.current_user.id)

    {:noreply,
     push_redirect(socket,
       to: Routes.main_path(socket, :index, socket.assigns.username, project.name)
     )}
  end
end
