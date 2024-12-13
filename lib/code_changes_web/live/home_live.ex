defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view

  alias CodeChanges.Servers.LineCounterServer

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:repo_url, "https://github.com/mariomelo/code_changes_sample")
     |> assign(:github_token, System.get_env("GITHUB_TOKEN", ""))
     |> assign(:starting_point, "HEAD")
     |> assign(:commit_count, 10)
     |> assign(:commits_processed, 0)
     |> assign(:status, :idle)
     |> assign(:error, nil)
     |> assign(:completion_message, nil)
     |> assign(:current_commit, nil)
     |> assign(:line_counts, %{})}
  end

  def handle_event("analyze", %{"repo" => %{"url" => url, "token" => token, "starting_point" => starting_point, "commit_count" => commit_count}}, socket) do
    unique_code = generate_unique_code()

    case LineCounterServer.start_link(
           unique_code: unique_code,
           repo_url: url,
           github_token: token,
           starting_point: starting_point,
           commit_count: String.to_integer(commit_count)
         ) do
      {:ok, server_pid} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(CodeChanges.PubSub, "line_counter:#{unique_code}")
        end

        {:noreply,
         socket
         |> assign(:repo_url, url)
         |> assign(:github_token, token)
         |> assign(:starting_point, starting_point)
         |> assign(:commit_count, commit_count)
         |> assign(:server_pid, server_pid)
         |> assign(:unique_code, unique_code)
         |> assign(:error, nil)  # Limpa o erro ao começar nova análise
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
    current_commit = if state.current_sha do
      %{
        sha: state.current_sha,
        files: state.modified_files || []
      }
    end

    {:noreply,
     socket
     |> assign(:status, state.status)
     |> assign(:current_commit, current_commit)
     |> assign(:commits_processed, state.commits_processed)
     |> assign(:line_counts, state.line_counts)}
  end

  def handle_info({:status_changed, status, message}, socket) do
    socket =
      socket
      |> assign(:status, status)
      |> assign(:error, if(status == :error, do: message))
      |> assign(:completion_message, if(status == :completed, do: message))

    {:noreply, socket}
  end

  defp generate_unique_code do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
    |> binary_part(0, 16)
  end

  defp get_sorted_counts(line_counts) do
    line_counts
    |> Enum.sort_by(fn {lines, _count} -> lines end)
  end

  defp get_percentage(count, line_counts) do
    total_count = line_counts |> Map.values() |> Enum.sum()
    Float.round(count / total_count * 100, 1)
  end

  defp extract_repo(url) do
    case Regex.run(~r/github\.com\/([^\/]+\/[^\/]+)(?:\.git)?/, url) do
      [_, repo] -> repo
      _ -> "unknown/repo"
    end
  end
end
