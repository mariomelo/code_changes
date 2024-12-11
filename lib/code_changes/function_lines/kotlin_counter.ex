defmodule CodeChanges.FunctionLines.KotlinCounter do
  @moduledoc """
  Module for counting lines of Kotlin functions within a given range.
  """

  alias CodeChanges.FunctionLines.BaseCounter

  @doc """
  Counts the number of lines in each Kotlin function that appears within the specified range.
  Excludes function signatures, braces, comments and blank lines from the count.
  """
  def count_lines(code, start_line, end_line) do
    BaseCounter.count_lines(code, start_line, end_line,
      is_function_start?: &is_function_start?/1,
      is_countable_line?: &is_countable_line?/1
    )
  end

  defp is_function_start?(line) do
    line = String.trim(line)

    cond do
      # Single-expression function
      Regex.match?(~r/^(?:private|public|internal|protected|suspend|\s)*fun\s+\w+\s*\([^)]*\)(?:\s*:\s*[\w\<\>\[\]]+)?\s*=/, line) -> true
      # Regular function
      Regex.match?(~r/^(?:private|public|internal|protected|suspend|\s)*fun\s+\w+\s*\([^)]*\)(?:\s*:\s*[\w\<\>\[\]]+)?\s*\{?/, line) -> true
      # Extension function
      Regex.match?(~r/^(?:private|public|internal|protected|\s)*fun\s+[\w\<\>\[\]]+\.\w+\s*\([^)]*\)(?:\s*:\s*[\w\<\>\[\]]+)?\s*\{?/, line) -> true
      # Constructor
      Regex.match?(~r/^(?:private|public|internal|protected|\s)*constructor\s*\([^)]*\)\s*\{?/, line) -> true
      # Property with custom getter/setter
      Regex.match?(~r/^(?:private|public|internal|protected|\s)*(?:var|val)\s+\w+(?:\s*:\s*[\w\<\>\[\]]+)?\s*(?:get|set)\s*\(\)\s*\{/, line) -> true
      # Lambda or anonymous function
      Regex.match?(~r/^\s*\{(?:\s*[^:]+(?::\s*[\w\<\>\[\]]+)?)?\s*->/, line) -> true
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
      String.starts_with?(line, "get()") or      # Getter method
      String.starts_with?(line, "set(") or       # Setter method
      String.starts_with?(line, "fun ") or       # Function declaration
      (String.contains?(line, "->") and not String.contains?(line, "."))  # Lambda declaration without method call
    ) and not String.contains?(line, "@")        # Exclude annotations
  end
end
