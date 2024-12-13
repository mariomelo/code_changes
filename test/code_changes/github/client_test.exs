defmodule CodeChanges.Github.ClientTest do
  use ExUnit.Case, async: true
  alias CodeChanges.Github.Client
  import Mock

  @moduletag :external

  setup do
    # Suppress logging during tests
    Logger.configure(level: :none)
    :ok
  end

  describe "getCommitDetails/3" do
    test "returns commit details successfully" do
      commit_response = %{
        "sha" => "test_sha",
        "commit" => %{
          "author" => %{"name" => "Test Author"}
        },
        "files" => [
          %{
            "filename" => "src/main/java/com/example/MyClass.java", # Non-test file in main source
            "patch" => "@@ -1,3 +1,4 @@\n+# New comment\n def test() do\n   IO.puts(\"test\")\n end",
            "raw_url" => "https://raw.githubusercontent.com/test/test/main/Test.java",
            "status" => "modified"  # Must be "modified"
          }
        ],
        "parents" => [%{"sha" => "parent_sha"}]
      }

      with_mock HTTPoison, [get: fn(_url, _headers) -> 
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(commit_response)}}
      end] do
        {:ok, result} = Client.getCommitDetails("elixir-lang/elixir", "fake_token", "fake_sha")
        
        assert length(result.files) == 1
        file = hd(result.files)
        assert file.filename == "src/main/java/com/example/MyClass.java"
        assert file.patch =~ "@@ -1,3 +1,4 @@"
        assert result.parent_sha == "parent_sha"
      end
    end

    test "handles invalid repository" do
      with_mock HTTPoison, [get: fn(_url, _headers) -> 
        {:error, %HTTPoison.Error{reason: :not_found}}
      end] do
        result = Client.getCommitDetails("invalid/repo", "fake_token", "fake_sha")
        assert {:error, :not_found} = result
      end
    end

    test "handles invalid commit SHA" do
      with_mock HTTPoison, [get: fn(_url, _headers) -> 
        {:error, %HTTPoison.Error{reason: :not_found}}
      end] do
        result = Client.getCommitDetails("elixir-lang/elixir", "fake_token", "invalid_sha")
        assert {:error, :not_found} = result
      end
    end

    test "handles unauthorized access" do
      with_mock HTTPoison, [get: fn(_url, _headers) -> 
        {:ok, %HTTPoison.Response{status_code: 401}}
      end] do
        result = Client.getCommitDetails("elixir-lang/elixir", "fake_token", "fake_sha")
        assert {:error, :unauthorized} = result
      end
    end

    test "filters out test files" do
      commit_response = %{
        "sha" => "test_sha",
        "commit" => %{
          "author" => %{"name" => "Test Author"}
        },
        "files" => [
          %{
            "filename" => "src/test/java/com/example/MyClassTest.java",  # Test file
            "patch" => "@@ -1,3 +1,4 @@\n+# New comment\n def test() do\n   IO.puts(\"test\")\n end",
            "raw_url" => "https://raw.githubusercontent.com/test/test/main/Test.java",
            "status" => "modified"
          },
          %{
            "filename" => "src/main/java/com/example/MyClass.java",  # Non-test file
            "patch" => "@@ -1,3 +1,4 @@\n+# New comment\n def test() do\n   IO.puts(\"test\")\n end",
            "raw_url" => "https://raw.githubusercontent.com/test/test/main/Test.java",
            "status" => "modified"
          }
        ],
        "parents" => [%{"sha" => "parent_sha"}]
      }

      with_mock HTTPoison, [get: fn(_url, _headers) -> 
        {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(commit_response)}}
      end] do
        {:ok, result} = Client.getCommitDetails("elixir-lang/elixir", "fake_token", "fake_sha")
        
        # Should only include the non-test file
        assert length(result.files) == 1
        file = hd(result.files)
        assert file.filename == "src/main/java/com/example/MyClass.java"
      end
    end
  end
end
