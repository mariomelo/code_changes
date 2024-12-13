defmodule CodeChanges.Github.Client do
  @moduledoc """
  Client to interact with the GitHub API.
  """
  @github_api_url "https://api.github.com"

  # Supported file extensions for analysis
  @supported_extensions ~w(.java .kt .kts)

  # Test file patterns
  @test_patterns [
    ~r/\/test\//,           # Standard test directory
    ~r/\/tests\//,          # Alternative test directory
    ~r/Test\.java$/,        # Java test files ending with Test
    ~r/Tests\.java$/,       # Java test files ending with Tests
    ~r/IT\.java$/,         # Integration test files
    ~r/TestCase\.java$/,   # TestCase files
    ~r/Spec\.kt$/,         # Kotlin spec files
    ~r/Test\.kt$/,         # Kotlin test files
    ~r/Tests\.kt$/,        # Kotlin test files
    ~r/IT\.kt$/,          # Kotlin integration test files
    ~r/androidTest\//,     # Android test directory
    ~r/src\/test\//        # Maven/Gradle test directory
  ]

  require Logger

  def getCommitDetails(repo, api_key, commit_sha \\ "HEAD") do
    with {:ok, commit_details} <- parse_commit_details(repo, api_key, commit_sha),
         {:ok, filteredcommit_details} <- filter_commit_files(commit_details) do
      {:ok, filteredcommit_details}
    else
      error -> error
    end
  end

  defp filter_commit_files(commit_details) do
    filtered_files = commit_details.files
                    |> Enum.filter(fn file ->
                      # Get file extension
                      ext = Path.extname(file.filename)
                      # Check if it's a supported extension, file was modified, and not a test file
                      ext in @supported_extensions and 
                      file.status == "modified" and
                      not is_test_file?(file.filename)
                    end)

    # Return updated commit_details with only filtered files
    {:ok, %{commit_details | files: filtered_files}}
  end

  defp is_test_file?(filename) do
    Enum.any?(@test_patterns, fn pattern ->
      Regex.match?(pattern, filename)
    end)
  end

  defp parse_commit_details(repo, api_key, commit_sha) do
    commit_url = "#{@github_api_url}/repos/#{repo}/commits/#{commit_sha}"
    Logger.debug("Fetching commit details from #{commit_url}")
    
    headers = if api_key && api_key != "" do
      [
        {"Authorization", "token #{api_key}"},
        {"Accept", "application/vnd.github.v3+json"}
      ]
    else
      [
        {"Accept", "application/vnd.github.v3+json"}
      ]
    end

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(commit_url, headers),
         {:ok, commit_data} <- Jason.decode(body) do

      Logger.debug("Successfully fetched commit data. Processing files...")
      
      files = commit_data["files"]
             |> Enum.map(fn file ->
               Logger.debug("Processing file: #{file["filename"]} (status: #{file["status"]})")
               %{
                 filename: file["filename"],
                 patch: file["patch"],
                 raw_url: file["raw_url"],
                 status: file["status"]
               }
             end)

      parent_sha = case commit_data["parents"] do
        [first_parent | _] -> 
          Logger.debug("Found parent commit: #{first_parent["sha"]}")
          first_parent["sha"]
        _ -> 
          Logger.debug("No parent commit found")
          nil
      end

      result = %{
        sha: commit_data["sha"],
        commit: %{
          "author" => commit_data["commit"]["author"]
        },
        files: files,
        parent_sha: parent_sha
      }

      Logger.debug("Processed commit details: #{inspect(result, pretty: true)}")
      {:ok, result}
    else
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        Logger.error("Unauthorized access to GitHub API")
        {:error, :unauthorized}

      {:ok, %HTTPoison.Response{status_code: 422}} ->
        Logger.error("Commit not found: #{commit_sha}")
        {:error, :commit_not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error while fetching commit: #{inspect(reason)}")
        {:error, reason}

      error ->
        Logger.error("Unknown error while fetching commit: #{inspect(error)}")
        {:error, :unknown_error}
    end
  end

  def fetch_file_content(url) do
    case HTTPoison.get(url, [{"Accept", "*/*"}], [follow_redirect: true]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :file_not_found}
      response ->
        IO.inspect(response)
        {:error, :file_not_found}
    end
  end
end
