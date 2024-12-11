defprotocol CodeChanges.FunctionLines.Counter do
  @doc """
  Counts the number of lines in functions within the specified range for a given language.
  """
  def count_lines(language, code, start_line, end_line)
end

defmodule CodeChanges.FunctionLines.Counter.Helper do
  @doc """
  Returns the language atom based on the file extension from the URL.
  Returns :unsupported for unsupported languages.
  """
  def get_language_from_url(url) do
    extension = url
    |> String.split(".")
    |> List.last()
    |> String.downcase()

    case extension do
      "java" -> :java
      "kt" -> :kotlin
      "kts" -> :kotlin
      _ -> :unsupported
    end
  end
end

defimpl CodeChanges.FunctionLines.Counter, for: Atom do
  alias CodeChanges.FunctionLines.{JavaCounter, KotlinCounter}

  def count_lines(:java, code, start_line, end_line) do
    JavaCounter.count_lines(code, start_line, end_line)
  end

  def count_lines(:kotlin, code, start_line, end_line) do
    KotlinCounter.count_lines(code, start_line, end_line)
  end

  def count_lines(_, _code, _start_line, _end_line) do
    {:error, :unsupported_language}
  end
end
