defmodule CodeChanges.Github.PatchAnalyzer do
  alias CodeChanges.Github
  alias CodeChanges.Github.Patch
  alias CodeChanges.FunctionLines.JavaCounter

  @github_context_window 3

  def analyze_patches(commit_details) do
    analyze_commit_changes(commit_details)
  end

  def analyze_commit_changes(commit_details) do
    commit_details.files
    |> Enum.map(fn file ->
      original_file_content = fetch_original_file_content(file.raw_url, commit_details.parent_sha)
      analyze_file_changes(file, original_file_content, commit_details.parent_sha)
    end)
  end

  defp fetch_original_file_content(url, parent_sha) do
    replace_commit_sha(url, parent_sha)
    |> Github.Client.fetch_file_content
  end

  defp replace_commit_sha(url, parent_sha) do
    Regex.replace(~r/[a-f0-9]{40}/, url, parent_sha)
  end

  defp extract_patch_content(patch) do
    if is_nil(patch) do
      []
    else
      Regex.scan(~r/@@ .+ @@/, patch, [])
      |> Enum.map(fn [hunk_header] ->
        String.split(hunk_header, " ")
        |> Enum.at(1)
        |> String.slice(1..-1)
        |> String.split(",", trim: true)
        |> List.to_tuple()
      end)
      |> calculate_lines_changed()
    end
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
    # First, find all function boundaries in the original file
    function_boundaries = find_function_boundaries(file_contents)

    # For each changed range, find which function it belongs to
    changes
    |> Enum.reduce(MapSet.new(), fn %{start_line: start_line, end_line: end_line}, acc ->
      case find_containing_function(start_line, end_line, function_boundaries) do
        nil -> acc
        func_range -> MapSet.put(acc, func_range)
      end
    end)
    |> Enum.to_list()
    |> Enum.map(fn {func_start, func_end} ->
      # Count lines for each unique function
      JavaCounter.count_lines(file_contents, func_start, func_end)
    end)
    |> List.flatten()
  end

  defp find_function_boundaries(file_contents) do
    lines = String.split(file_contents, "\n")
    {boundaries, current_func, brace_count} = 
      Enum.with_index(lines, 1)
      |> Enum.reduce({[], nil, 0}, fn {line, line_num}, {boundaries, current_func, brace_count} ->
        cond do
          # Start of a function
          is_function_start?(line) and is_nil(current_func) ->
            {boundaries, line_num, count_braces(line)}

          # Inside a function
          not is_nil(current_func) ->
            new_brace_count = brace_count + count_braces(line)
            if new_brace_count == 0 do
              # Function ends
              {[{current_func, line_num} | boundaries], nil, 0}
            else
              {boundaries, current_func, new_brace_count}
            end

          true ->
            {boundaries, current_func, brace_count}
        end
      end)

    case current_func do
      nil -> boundaries
      start -> [{start, length(lines)} | boundaries]
    end
  end

  defp is_function_start?(line) do
    line = String.trim(line)
    cond do
      # Constructor (has same name as class)
      Regex.match?(~r/^(?:public|private|protected|\s)*[A-Z]\w+\s*\([^)]*\)\s*\{?/, line) -> true

      # Regular method
      Regex.match?(~r/^(?:public|private|protected|static|\s)*[\w\<\>\[\]]+\s+\w+\s*\([^)]*\)\s*\{?/, line) -> true

      true -> false
    end
  end

  defp count_braces(line) do
    opening = length(Regex.scan(~r/{/, line))
    closing = length(Regex.scan(~r/}/, line))
    opening - closing
  end

  defp find_containing_function(start_line, end_line, function_boundaries) do
    Enum.find(function_boundaries, fn {func_start, func_end} ->
      start_line >= func_start and start_line <= func_end
    end)
  end

  defp analyze_file_changes(file, original_file_content, parent_sha) do
    lines_changed = if file.patch do
      extract_patch_content(file.patch)
    else
      []
    end

    functions_changed = count_function_lines(file.filename, lines_changed, original_file_content)

    %Patch{
      parent_sha: parent_sha,
      filename: file.filename,
      sizes_and_changes: functions_changed,
      file_contents: original_file_content
    }
  end
end
