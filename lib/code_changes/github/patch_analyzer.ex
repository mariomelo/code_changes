defmodule CodeChanges.Github.PatchAnalyzer do

  alias CodeChanges.Github
  alias CodeChanges.Github.Patch

  @github_context_window 6


  def replace_commit_sha(url, parent_sha) do
    Regex.replace(~r/[a-f0-9]{40}/, url, parent_sha)
  end

  defp fetch_original_file_content(url, parent_sha) do
    replace_commit_sha(url, parent_sha)
    |>IO.inspect(label: "REQUEST URL")
    |> Github.Client.fetch_file_content
  end

  defp extract_patch_content(patch) do
    Regex.scan(~r/@@ .+ @@/, patch)
    |> List.flatten()
    |> Enum.join("\n")
  end

  def analyze_patches(commit_details) do
    commit_details.files
    |> Enum.map(fn file ->
      %Patch{
        parent_sha: commit_details.parent_sha,
        filename: file.filename,
        patches: extract_patch_content(file.patch),
        file_contents: fetch_original_file_content(file.raw_url, commit_details.parent_sha)
      }
    end)

  end

end
