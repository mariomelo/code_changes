defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("submit", params, socket) do
    # TODO: Implement the form submission logic
    {:noreply, socket}
  end
end
