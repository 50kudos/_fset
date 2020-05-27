defmodule FsetWeb.MainLive do
  use FsetWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
      Main
    """
  end
end
