defmodule CodeChanges.FunctionLines.JavaCounter do
  @moduledoc """
  Module for counting lines of Java functions within a given range.
  """

  alias CodeChanges.FunctionLines.BaseCounter

  @doc """
  Counts the number of lines in each Java function that appears within the specified range.
  Excludes function signatures, braces, comments and blank lines from the count.
  """
  def count_lines(code, start_line, end_line) do
    BaseCounter.count_lines(code, start_line, end_line,
      is_function_start?: &is_function_start?/1,
      is_countable_line?: &is_countable_line?/1
    )
    |> Enum.filter(&(&1 > 0))  # Remove funções com 0 linhas
  end

  defp is_function_start?(line) do
    line = String.trim(line)

    cond do
      # Constructor (has same name as class)
      Regex.match?(~r/^(?:public|private|protected|\s)*[A-Z]\w+\s*\([^)]*\)\s*\{?/, line) -> true

      # Regular method
      Regex.match?(~r/^(?:public|private|protected|static|\s)*[\w\<\>\[\]]+\s+\w+\s*\([^)]*\)\s*\{?/, line) -> true

      # Anonymous class method (but not lambda or anonymous inner class)
      Regex.match?(~r/^\s*(?:@Override\s*)?(?:public|private|protected|static|\s)*[\w\<\>\[\]]+\s+\w+\s*\([^)]*\)\s*\{?/, line) and
      not (String.contains?(line, "->") or String.contains?(line, "new")) -> true
      
      true -> false
    end
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
      String.equivalent?(line, "}") or           # Closing brace only
      String.starts_with?(line, "@")             # Exclude all annotations
    )
  end
end
