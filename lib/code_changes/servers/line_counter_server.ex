defmodule CodeChanges.Servers.LineCounterServer do
  use GenServer
  require Logger

  alias CodeChanges.Github.{Client, PatchAnalyzer}

  @type t :: %__MODULE__{
    status: :idle | :running | :error,
    error_message: String.t() | nil,
    current_sha: String.t() | nil,
    current_author: String.t() | nil,
    commit_date: DateTime.t() | nil,
    last_sha: String.t() | nil,
    unique_code: String.t(),
    repo_url: String.t(),
    github_token: String.t(),
    line_counts: %{integer() => integer()},
    modified_files: [String.t()]
  }

  defstruct status: :idle,
            error_message: nil,
            current_sha: nil,
            current_author: nil,
            commit_date: nil,
            last_sha: nil,
            unique_code: nil,
            repo_url: nil,
            github_token: nil,
            line_counts: %{},
            modified_files: []

  # Client API
  def start_link(opts) do
    unique_code = Keyword.fetch!(opts, :unique_code)
    repo_url = Keyword.fetch!(opts, :repo_url)
    github_token = Keyword.fetch!(opts, :github_token)

    GenServer.start_link(__MODULE__,
      %__MODULE__{
        unique_code: unique_code,
        repo_url: repo_url,
        github_token: github_token
      },
      name: via_tuple(unique_code))
  end

  def process_next_commit(server) do
    GenServer.cast(server, :process_next_commit)
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  # Server Callbacks
  @impl true
  def init(state) do
    {:ok, state, {:continue, :process_first_commit}}
  end

  @impl true
  def handle_continue(:process_first_commit, state) do
    send(self(), :process_commit)
    broadcast_status(state.unique_code, :running)
    {:noreply, %{state | status: :running}}
  end

  @impl true
  def handle_cast(:process_next_commit, state) do
    send(self(), :process_commit)
    broadcast_status(state.unique_code, :running)
    {:noreply, %{state | status: :running}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:process_commit, state) do
    # Extrair owner/repo da URL do GitHub
    repo = case Regex.run(~r/github\.com\/([^\/]+\/[^\/]+)/, state.repo_url) do
      [_, repo] -> repo
      _ -> nil
    end

    case repo do
      nil ->
        error_state = handle_error(state, "URL do repositório inválida")
        {:noreply, error_state}

      repo ->
        # Use "HEAD" if we don't have a last_sha
        commit_ref = state.last_sha || "HEAD"
        case Client.getCommitDetails(repo, state.github_token, commit_ref) do
          {:ok, commit_details} ->
            patches = PatchAnalyzer.analyze_patches(commit_details)

            new_line_counts =
              patches
              |> Enum.reduce(state.line_counts, fn patch, acc ->
                update_line_counts(acc, patch.sizes_and_changes)
              end)

            updated_state = %{state |
              status: :idle,
              current_sha: commit_details.sha,
              current_author: get_in(commit_details, ["commit", "author", "name"]),
              commit_date: parse_github_date(get_in(commit_details, ["commit", "author", "date"])),
              last_sha: commit_details.parent_sha,
              line_counts: new_line_counts,
              modified_files: Enum.map(commit_details.files, & &1.filename)
            }

            broadcast_state_update(updated_state)
            {:noreply, updated_state}

          {:error, reason} ->
            error_state = handle_error(state, "Erro ao buscar commit: #{inspect(reason)}")
            {:noreply, error_state}
        end
    end
  end

  # Private Functions
  defp update_line_counts(existing_counts, new_counts) do
    Enum.reduce(new_counts, existing_counts, fn count, acc ->
      Map.update(acc, count, 1, &(&1 + 1))
    end)
  end

  defp via_tuple(unique_code) do
    {:via, Registry, {CodeChanges.ServerRegistry, unique_code}}
  end

  defp parse_github_date(nil), do: nil
  defp parse_github_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp handle_error(state, message) do
    error_state = %{state | status: :error, error_message: message}
    broadcast_status(state.unique_code, :error, message)
    error_state
  end

  defp broadcast_state_update(state) do
    Phoenix.PubSub.broadcast(
      CodeChanges.PubSub,
      "line_counter:#{state.unique_code}",
      {:state_updated, %{
        status: state.status,
        current_sha: state.current_sha,
        current_author: state.current_author,
        commit_date: state.commit_date,
        line_counts: state.line_counts,
        modified_files: state.modified_files
      }}
    )
  end

  defp broadcast_status(unique_code, status, message \\ nil) do
    Phoenix.PubSub.broadcast(
      CodeChanges.PubSub,
      "line_counter:#{unique_code}",
      {:status_changed, status, message}
    )
  end
end
