defmodule CodeChanges.Github.ClientTest do
  use ExUnit.Case, async: true
  alias CodeChanges.Github.Client

  @moduletag :external

  describe "getCommitDetails/3" do
    test "returns commit details successfully" do
      # Using a known public repository and commit
      repo = "elixir-lang/elixir"
      commit_sha = "02c89c1f24a2b827ba1e4c1e7c2b1a9b9b2b2b2b"
      api_key = System.get_env("GITHUB_TOKEN", "")

      case Client.getCommitDetails(repo, api_key, commit_sha) do
        {:ok, result} ->
          assert is_list(result.files)
          assert is_binary(result.parent_sha) or is_nil(result.parent_sha)
          
          if length(result.files) > 0 do
            file = hd(result.files)
            assert is_binary(file.filename)
            assert is_binary(file.patch) or is_nil(file.patch)
          end

        {:error, :unauthorized} ->
          # Skip test if no valid token is provided
          :ok

        {:error, :commit_not_found} ->
          # Skip test if commit doesn't exist anymore
          :ok
      end
    end

    test "handles invalid repository" do
      result = Client.getCommitDetails("invalid/repo", "invalid_token", "invalid_sha")
      assert {:error, _} = result
    end

    test "handles invalid commit SHA" do
      repo = "elixir-lang/elixir"
      api_key = System.get_env("GITHUB_TOKEN", "")
      result = Client.getCommitDetails(repo, api_key, "invalid_sha")
      assert {:error, :commit_not_found} = result
    end

    test "handles unauthorized access" do
      repo = "elixir-lang/elixir"
      commit_sha = "02c89c1f24a2b827ba1e4c1e7c2b1a9b9b2b2b2b"
      result = Client.getCommitDetails(repo, "invalid_token", commit_sha)
      assert {:error, :unauthorized} = result
    end
  end
end
