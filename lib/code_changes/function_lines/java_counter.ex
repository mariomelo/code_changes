defmodule CodeChanges.FunctionLines.JavaCounter do
  @moduledoc """
  Module for counting lines of Java functions within a given range.
  """

  @doc """
  Counts the number of lines in each Java function that appears within the specified range.
  Excludes function signatures, braces, comments and blank lines from the count.
  """
  def count_lines(code, start_line, end_line) do
    lines = String.split(code, "\n")
    |> Enum.with_index(1)

    # Find all functions and their ranges
    functions = find_functions(lines)

    # Filter functions that intersect with the given range
    functions
    |> Enum.filter(fn {func_start, func_end, _} ->
      func_start <= end_line && func_end >= start_line
    end)
    |> Enum.map(fn {func_start, _func_end, func_lines} ->
      # Only count lines within the specified range
      func_lines
      |> Enum.with_index(func_start)
      |> Enum.filter(fn {_, idx} -> idx >= start_line && idx <= end_line end)
      |> Enum.map(fn {line, _} -> line end)
      |> Enum.filter(&is_countable_line?/1)
      |> length()
    end)

  end

  defp find_functions(lines) do
    {functions, current_func, _state} =
      Enum.reduce(lines, {[], nil, %{brace_count: 0, in_comment: false}}, &process_line/2)

    case current_func do
      nil -> functions
      {start, lines, _} -> [{start, start + length(lines), lines} | functions]
    end
    |> Enum.reverse()
  end

  defp process_line({line, line_num}, {functions, current_func, state}) do
    new_state = update_comment_state(line, state)

    cond do
      # Inside a function
      current_func != nil ->
        handle_function_body(line, line_num, functions, current_func, new_state)

      # New function definition
      not new_state.in_comment and is_function_start?(line) ->
        new_state = %{new_state | brace_count: count_braces(line)}
        {functions, {line_num, [], new_state}, new_state}

      true ->
        {functions, current_func, new_state}
    end
  end

  defp update_comment_state(line, state) do
    cond do
      state.in_comment and String.contains?(line, "*/") ->
        %{state | in_comment: false}
      not state.in_comment and String.contains?(line, "/*") and not String.contains?(line, "*/") ->
        %{state | in_comment: true}
      true ->
        state
    end
  end

  defp handle_function_body(line, line_num, functions, {start_line, body_lines, state}, new_state) do
    new_brace_count = state.brace_count + count_braces(line)
    new_state = %{new_state | brace_count: new_brace_count}


    cond do
      # Function ends
      new_brace_count == 0 ->
        {[{start_line, line_num, [line | body_lines]} | functions], nil, new_state}

      # Inside function body
      true ->
        {functions, {start_line, [line | body_lines], new_state}, new_state}
    end
  end

  defp is_function_start?(line) do
    line = String.trim(line)

    cond do
      # Regular method or constructor
      Regex.match?(~r/^(?:public|private|protected|static|\s)*[\w\<\>\[\]]+\s+\w+\s*\([^)]*\)\s*\{?/, line) -> true

      # Anonymous class method
      Regex.match?(~r/^\s*(?:@Override\s*)?(?:public|private|protected|static|\s)*[\w\<\>\[\]]+\s+\w+\s*\([^)]*\)\s*\{?/, line) -> true
      true -> false
    end
  end

  defp count_braces(line) do
    opening = length(Regex.scan(~r/{/, line))
    closing = length(Regex.scan(~r/}/, line))
    opening - closing
  end

  defp is_countable_line?(line) do
    line = String.trim(line)
    not (
      line == "" or                              # Empty line
      String.starts_with?(line, "//") or         # Single line comment
      String.starts_with?(line, "*") or          # Part of multi-line comment
      String.starts_with?(line, "/*") or         # Start of multi-line comment
      String.starts_with?(line, "*/") or         # End of multi-line comment
      String.equivalent?(line, "{") or           # Opening brace only
      String.equivalent?(line, "}")              # Closing brace only
    ) and not String.contains?(line, "@Override")  # Exclude lambda arrows and annotations
  end
end
