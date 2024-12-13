defmodule CodeChanges.Servers.LineCounterServerTest do
  use ExUnit.Case
  alias CodeChanges.Servers.LineCounterServer

  describe "start_link/1" do
    test "starts the server with correct initial state" do
      unique_code = "test-123"
      repo_url = "user/repo"
      github_token = "token-123"

      {:ok, pid} = LineCounterServer.start_link(
        unique_code: unique_code,
        repo_url: repo_url,
        github_token: github_token
      )

      assert Process.alive?(pid)
      
      state = LineCounterServer.get_state(unique_code)
      assert state.unique_code == unique_code
      assert state.repo_url == repo_url
      assert state.github_token == github_token
      assert state.line_counts == %{}
      assert state.last_sha == nil
      assert state.commit_date == nil
    end

    test "fails to start with missing required options" do
      assert_raise KeyError, fn ->
        LineCounterServer.start_link([])
      end
    end
  end

  describe "process_line_counts/2" do
    test "processes new line counts correctly" do
      unique_code = "test-456"
      {:ok, _pid} = start_counter_server(unique_code)

      # First batch of counts
      LineCounterServer.process_line_counts(unique_code, [1, 2, 2, 3, 3, 3])
      state = LineCounterServer.get_state(unique_code)
      assert state.line_counts == %{1 => 1, 2 => 2, 3 => 3}

      # Second batch of counts
      LineCounterServer.process_line_counts(unique_code, [1, 2, 3])
      state = LineCounterServer.get_state(unique_code)
      assert state.line_counts == %{1 => 2, 2 => 3, 3 => 4}
    end

    test "handles empty list of counts" do
      unique_code = "test-789"
      {:ok, _pid} = start_counter_server(unique_code)

      LineCounterServer.process_line_counts(unique_code, [])
      state = LineCounterServer.get_state(unique_code)
      assert state.line_counts == %{}
    end
  end

  describe "stop/1" do
    test "stops the server" do
      unique_code = "test-stop"
      {:ok, pid} = start_counter_server(unique_code)
      
      assert Process.alive?(pid)
      assert :ok = LineCounterServer.stop(unique_code)
      refute Process.alive?(pid)
    end
  end

  # Helper Functions

  defp start_counter_server(unique_code) do
    LineCounterServer.start_link(
      unique_code: unique_code,
      repo_url: "test/repo",
      github_token: "test-token"
    )
  end
end
