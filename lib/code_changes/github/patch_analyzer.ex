defmodule CodeChanges.Github.PatchAnalyzer do

  alias CodeChanges.Github
  alias CodeChanges.Github.Patch
  alias CodeChanges.FunctionLines.Counter

  @github_context_window 3

  def replace_commit_sha(url, parent_sha) do
    Regex.replace(~r/[a-f0-9]{40}/, url, parent_sha)
  end

  defp fetch_original_file_content(url, parent_sha) do
    replace_commit_sha(url, parent_sha)
    |> Github.Client.fetch_file_content
  end

  defp extract_patch_content(patch) do
    Regex.scan(~r/@@ .+ @@/, patch)
    |> List.flatten()
    |> get_line_numbers()
  end

  defp get_line_numbers(patch_lines) do
    Enum.map(patch_lines, fn line ->
      String.split(line, " ")
      |> Enum.at(1)
      |> String.slice(1..-1)
      |> String.split(",", trim: true)
      |> List.to_tuple()
    end)
    |> calculate_lines_changed()
  end

  defp calculate_lines_changed(patch_lines) do
    Enum.map(patch_lines, fn {start_line, lines_changed} ->
      real_start_line = String.to_integer(start_line) + @github_context_window
      real_lines_changed = String.to_integer(lines_changed) - 2 * @github_context_window
      end_line = real_start_line + real_lines_changed - 1

      %{start_line: real_start_line, end_line: end_line}
    end)
  end

  defp count_function_lines(filename, changes, file_contents) do
    Enum.map(changes, fn change ->
      IO.inspect(change, label: "Change")
      Counter.Helper.get_language_from_url(filename)
      |> Counter.count_lines(file_contents, change.start_line, change.end_line)
    end)
  end

  def analyze_patches(commit_details) do

    commit_details.files
    |> Enum.map(fn file ->
      original_file_content = fetch_original_file_content(file.raw_url, commit_details.parent_sha)
      lines_changed = extract_patch_content(file.patch)

      functions_changed = count_function_lines(file.filename, lines_changed, original_file_content)

      %Patch{
        parent_sha: commit_details.parent_sha,
        filename: file.filename,
        patches: functions_changed,
        file_contents: original_file_content
      }
      |> IO.inspect(label: "Patch")
    end)

  end

end
