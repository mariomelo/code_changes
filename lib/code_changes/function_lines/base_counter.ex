defmodule CodeChanges.FunctionLines.BaseCounter do
  @moduledoc """
  Base module for counting lines in functions. Provides common functionality for language-specific counters.
  """

  @doc """
  Base implementation for counting lines in functions.
  """
  def count_lines(code, start_line, end_line, opts \\ []) do
    lines = String.split(code, "\n")
    |> Enum.with_index(1)

    # Find all functions and their ranges
    functions = find_functions(lines, opts)

    # Filter functions that intersect with the given range and count their lines
    functions
    |> Enum.filter(fn {func_start, func_end, _} ->
      func_start <= end_line && func_end >= start_line
    end)
    |> Enum.map(fn {_func_start, _func_end, func_lines} ->
      # Count all countable lines in the function
      func_lines
      |> Enum.filter(&(opts[:is_countable_line?].(&1)))
      |> length()
    end)
  end

  defp find_functions(lines, opts) do
    {functions, current_func, _state} =
      Enum.reduce(lines, {[], nil, %{brace_count: 0, in_comment: false}}, &(process_line(&1, &2, opts)))

    case current_func do
      nil -> functions
      {start, lines, _} -> [{start, start + length(lines), lines} | functions]
    end
    |> Enum.reverse()
  end

  defp process_line({line, line_num}, {functions, current_func, state}, opts) do
    new_state = update_comment_state(line, state)

    cond do
      # Inside a function
      current_func != nil ->
        handle_function_body(line, line_num, functions, current_func, new_state)

      # New function definition
      not new_state.in_comment and opts[:is_function_start?].(line) ->
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

  defp count_braces(line) do
    opening = length(Regex.scan(~r/{/, line))
    closing = length(Regex.scan(~r/}/, line))
    opening - closing
  end
end
