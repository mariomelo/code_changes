defmodule CodeChanges.Exports.CSVExporter do
  def generate_csv(line_counts) do
    headers = "Lines of Code,Count,Percentage\n"
    
    total_count = line_counts |> Map.values() |> Enum.sum()
    
    rows =
      line_counts
      |> Enum.sort_by(fn {lines, _count} -> lines end)
      |> Enum.map(fn {lines, count} ->
        percentage = Float.round(count / total_count * 100, 1)
        ~s("#{lines}","#{count}","#{percentage}%"\n)
      end)
      
    [headers | rows]
    |> Enum.join("")
  end
end
