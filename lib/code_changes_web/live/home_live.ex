defmodule CodeChangesWeb.HomeLive do
  use CodeChangesWeb, :live_view
  alias CodeChanges.Github.Client

  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      github_token: nil,
      repo_url: nil,
      commit_info: nil,
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
        {:noreply, assign(socket, error: "URL do repositório inválida", commit_info: nil)}
      repo ->
        case Client.getLastCommitInfo(repo, token) do
          {:ok, commit_info} ->
            {:noreply, assign(socket, 
              commit_info: commit_info,
              error: nil
            )}
          {:error, :unauthorized} ->
            {:noreply, assign(socket, 
              error: "Token do GitHub inválido",
              commit_info: nil
            )}
          {:error, :repository_not_found} ->
            {:noreply, assign(socket, 
              error: "Repositório não encontrado",
              commit_info: nil
            )}
          {:error, _} ->
            {:noreply, assign(socket, 
              error: "Erro ao buscar informações do repositório",
              commit_info: nil
            )}
        end
    end
  end
end
