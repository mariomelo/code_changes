defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view

  alias CodeChanges.Servers.LineCounterServer

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:repo_url, "https://github.com/mariomelo/code_changes_sample")
     |> assign(:github_token, System.get_env("GITHUB_TOKEN", ""))
     |> assign(:status, :idle)
     |> assign(:error, nil)
     |> assign(:current_commit, nil)
     |> assign(:line_counts, %{})}
  end

  def handle_event("validate", %{"repo" => %{"url" => url, "token" => token}}, socket) do
    {:noreply, socket |> assign(:repo_url, url) |> assign(:github_token, token)}
  end

  def handle_event("analyze", %{"repo" => %{"url" => url, "token" => token}}, socket) do
    unique_code = generate_unique_code()

    case LineCounterServer.start_link(
           unique_code: unique_code,
           repo_url: url,
           github_token: token
         ) do
      {:ok, server_pid} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(CodeChanges.PubSub, "line_counter:#{unique_code}")
        end

        {:noreply,
         socket
         |> assign(:server_pid, server_pid)
         |> assign(:unique_code, unique_code)
         |> assign(:status, :running)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:error, "Failed to start analysis: #{inspect(reason)}")
         |> assign(:status, :error)}
    end
  end

  def handle_event("next_commit", _, socket) do
    LineCounterServer.process_next_commit(socket.assigns.server_pid)
    {:noreply, socket |> assign(:status, :running)}
  end

  def handle_info({:state_updated, state}, socket) do
    {:noreply,
     socket
     |> assign(:status, state.status)
     |> assign(:current_commit, %{
       sha: state.current_sha,
       author: state.current_author,
       date: state.commit_date
     })
     |> assign(:line_counts, state.line_counts)}
  end

  def handle_info({:status_changed, status, message}, socket) do
    socket =
      socket
      |> assign(:status, status)
      |> assign(:error, if(status == :error, do: message, else: nil))

    {:noreply, socket}
  end

  defp generate_unique_code do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
    |> binary_part(0, 16)
  end
end
