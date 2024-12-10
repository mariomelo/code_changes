defmodule CodeChanges.Github.Client do
  @moduledoc """
  Cliente para interagir com a API do GitHub.
  """
  @github_api_url "https://api.github.com"

  @doc """
  Retorna informações sobre o último commit de um repositório, incluindo:
  - Arquivos alterados
  - Nome do autor
  - Mensagem do commit
  
  ## Parâmetros
    - repo: URL do repositório no formato "owner/repo"
    - api_key: Token de acesso à API do GitHub
  
  ## Exemplo
      iex> CodeChanges.Github.Client.getLastCommitInfo("elixir-lang/elixir", "ghp_your_token")
      {:ok, %{
        author: "John Doe",
        files: ["lib/example.ex", "test/example_test.ex"],
        message: "Fix bug in example module"
      }}
  """
  def getLastCommitInfo(repo, api_key) do
    # Primeiro, pegamos o SHA do último commit
    commits_url = "#{@github_api_url}/repos/#{repo}/commits?per_page=1"
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Accept", "application/vnd.github.v3+json"}
    ]

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(commits_url, headers),
         {:ok, [last_commit | _]} <- Jason.decode(body),
         commit_sha <- last_commit["sha"],
         # Agora pegamos os detalhes completos do commit
         commit_url <- "#{@github_api_url}/repos/#{repo}/commits/#{commit_sha}",
         {:ok, %HTTPoison.Response{status_code: 200, body: commit_body}} <- HTTPoison.get(commit_url, headers),
         {:ok, commit_data} <- Jason.decode(commit_body) do
      
      files = commit_data["files"]
             |> Enum.map(fn file -> file["filename"] end)
      
      result = %{
        author: commit_data["commit"]["author"]["name"],
        files: files,
        message: commit_data["commit"]["message"]
      }

      {:ok, result}
    else
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :unauthorized}
      
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :repository_not_found}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      
      _ ->
        {:error, :unknown_error}
    end
  end
end
