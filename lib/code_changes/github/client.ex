defmodule CodeChanges.Github.Client do
  @moduledoc """
  Cliente para interagir com a API do GitHub.
  """
  @github_api_url "https://api.github.com"

  def getCommitDetails(repo, api_key, commit_sha \\ "HEAD") do
    commit_url = "#{@github_api_url}/repos/#{repo}/commits/#{commit_sha}"
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Accept", "application/vnd.github.v3+json"}
    ]

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(commit_url, headers),
         {:ok, commit_data} <- Jason.decode(body) do

      files = commit_data["files"]
             |> Enum.map(fn file ->
               %{
                 filename: file["filename"],
                 patch: file["patch"]
               }
             end)

      parent_sha = case commit_data["parents"] do
        [first_parent | _] -> first_parent["sha"]
        _ -> nil
      end

      result = %{
        files: files,
        parent_sha: parent_sha
      }

      {:ok, result}
    else
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :unauthorized}

      {:ok, %HTTPoison.Response{status_code: 422}} ->
        {:error, :commit_not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      _ ->
        {:error, :unknown_error}
    end
  end
end
