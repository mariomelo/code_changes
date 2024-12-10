defmodule CodeChanges.Servers.LineCounterServer do
  use GenServer
  require Logger

  @type t :: %__MODULE__{
    last_sha: String.t() | nil,
    unique_code: String.t(),
    repo_url: String.t(),
    github_token: String.t(),
    commit_date: DateTime.t() | nil,
    line_counts: %{integer() => integer()}
  }

  defstruct last_sha: nil,
            unique_code: nil,
            repo_url: nil,
            github_token: nil,
            commit_date: nil,
            line_counts: %{}

  # Client API

  def start_link(opts) do
    unique_code = Keyword.fetch!(opts, :unique_code)
    repo_url = Keyword.fetch!(opts, :repo_url)
    github_token = Keyword.fetch!(opts, :github_token)
    
    GenServer.start_link(__MODULE__, 
      %__MODULE__{
        unique_code: unique_code,
        repo_url: repo_url,
        github_token: github_token,
        line_counts: %{}
      },
      name: via_tuple(unique_code))
  end

  def stop(unique_code) do
    GenServer.stop(via_tuple(unique_code))
  end

  def process_line_counts(unique_code, line_counts) when is_list(line_counts) do
    GenServer.cast(via_tuple(unique_code), {:process_line_counts, line_counts})
  end

  def get_state(unique_code) do
    GenServer.call(via_tuple(unique_code), :get_state)
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:process_line_counts, new_counts}, state) do
    updated_counts = update_line_counts(state.line_counts, new_counts)
    {:noreply, %{state | line_counts: updated_counts}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Private Functions

  defp update_line_counts(existing_counts, new_counts) do
    Enum.reduce(new_counts, existing_counts, fn count, acc ->
      Map.update(acc, count, 1, &(&1 + 1))
    end)
  end

  defp via_tuple(unique_code) do
    {:via, Registry, {CodeChanges.ServerRegistry, {__MODULE__, unique_code}}}
  end
end
