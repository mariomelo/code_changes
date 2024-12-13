defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view

  alias CodeChanges.Servers.LineCounterServer

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:repo_url, "https://github.com/mariomelo/code_changes_sample")
     |> assign(:github_token, System.get_env("GITHUB_TOKEN", ""))
     |> assign(:starting_point, "HEAD")
     |> assign(:commit_count, "10")
     |> assign(:commits_processed, 0)
     |> assign(:total_commits_processed, 0)
     |> assign(:status, :idle)
     |> assign(:error, nil)
     |> assign(:completion_message, nil)
     |> assign(:current_commit, nil)
     |> assign(:line_counts, %{})
     |> assign(:selected_table_view, "exponential")
     |> assign(:unique_code, generate_unique_code())}
  end

  def handle_event("analyze", %{"repo" => repo}, socket) do
    unique_code = generate_unique_code()

    case LineCounterServer.start_link(
           unique_code: unique_code,
           repo_url: repo["url"],
           github_token: repo["token"],
           starting_point: repo["starting_point"],
           commit_count: String.to_integer(repo["commit_count"])
         ) do
      {:ok, _pid} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(CodeChanges.PubSub, "line_counter:#{unique_code}")
        end

        {:noreply,
         socket
         |> assign(:status, :running)
         |> assign(:error, nil)
         |> assign(:completion_message, nil)
         |> assign(:commit_count, repo["commit_count"])
         |> assign(:starting_point, repo["starting_point"])
         |> assign(:unique_code, unique_code)
         |> assign(:commits_processed, 0)}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(:error, message)
         |> assign(:status, :error)}
    end
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:line_counts, %{})
     |> assign(:total_commits_processed, 0)
     |> assign(:commits_processed, 0)
     |> assign(:starting_point, "HEAD")
     |> assign(:current_commit, nil)
     |> assign(:status, :idle)
     |> assign(:error, nil)
     |> assign(:completion_message, nil)}
  end

  def handle_event("switch_table_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :selected_table_view, view)}
  end

  def handle_info({:state_updated, state}, socket) do
    current_commit = if state.current_sha do
      %{
        sha: state.current_sha,
        files: state.modified_files || []
      }
    end

    # Only accumulate line counts from previous analysis
    updated_line_counts = Enum.reduce(state.line_counts, socket.assigns.line_counts, fn {lines, count}, acc ->
      Map.update(acc, lines, count, &(&1 + count))
    end)

    # Only increment total_commits_processed when commits_processed increases
    new_commits = max(0, state.commits_processed - socket.assigns.commits_processed)

    {:noreply,
     socket
     |> assign(:status, state.status)
     |> assign(:current_commit, current_commit)
     |> assign(:commits_processed, state.commits_processed)
     |> assign(:total_commits_processed, socket.assigns.total_commits_processed + new_commits)
     |> assign(:line_counts, updated_line_counts)}
  end

  def handle_info({:status_changed, status, message}, socket) do
    socket =
      socket
      |> assign(:status, status)
      |> assign(:error, if(status == :error, do: message))
      |> assign(:completion_message, if(status == :completed, do: message))

    if status == :completed do
      # When completed, update the starting point to the last commit
      case socket.assigns.current_commit do
        %{sha: sha} -> 
          socket = assign(socket, :starting_point, sha)
          {:noreply, socket}
        _ -> 
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
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
