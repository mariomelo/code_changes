defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view
  alias CodeChanges.Github.Client

  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      github_token: nil,
      repo_url: nil,
      commit_details: nil,
      error: nil
    )}
  end

  def handle_event("submit", %{"github_token" => token, "repo_url" => url}, socket) do
    # Extrair owner/repo da URL do GitHub
    repo = case Regex.run(~r/github\.com\/([^\/]+\/[^\/]+)/, url) do
      [_, repo] -> repo
      _ -> nil
    end

    case repo do
      nil ->
        {:noreply, assign(socket, error: "URL do repositório inválida", commit_details: nil)}
      repo ->
        case Client.getCommitDetails(repo, token) do
          {:ok, commit_details} ->
            {:noreply, assign(socket, 
              commit_details: commit_details,
              error: nil
            )}
          {:error, :unauthorized} ->
            {:noreply, assign(socket, 
              error: "Token do GitHub inválido",
              commit_details: nil
            )}
          {:error, :commit_not_found} ->
            {:noreply, assign(socket, 
              error: "Commit não encontrado",
              commit_details: nil
            )}
          {:error, _} ->
            {:noreply, assign(socket, 
              error: "Erro ao buscar informações do commit",
              commit_details: nil
            )}
        end
    end
  end
end
