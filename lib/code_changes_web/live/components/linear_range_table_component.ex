defmodule CodeChangesWeb.LinearRangeTableComponent do
  use CodeChangesWeb, :live_component

  def update(assigns, socket) do
    ranges = [
      {1..5, "1 to 5"},
      {6..10, "6 to 10"},
      {11..15, "11 to 15"},
      {16..20, "16 to 20"}
    ]

    data = group_by_ranges(assigns.line_counts, ranges)
    |> Map.put({:more, "20 or more"}, 
      Enum.sum(for {lines, count} <- assigns.line_counts, lines > 20, do: count))
    
    total = Enum.sum(Map.values(data))
    
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:ranges, ranges)
     |> assign(:grouped_data, data)
     |> assign(:total_count, total)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full text-sm">
        <thead>
          <tr>
            <th class="text-left px-2 py-1 text-gray-600 w-32">Lines</th>
            <th class="text-left px-2 py-1 text-gray-600">Changes</th>
          </tr>
        </thead>
        <tbody>
          <%= for {{range, label}, count} <- sort_ranges(@grouped_data) do %>
            <tr class="hover:bg-gray-50">
              <td class="px-2 py-1 text-gray-800 font-medium whitespace-nowrap"><%= label %></td>
              <td class="px-2 py-1 text-gray-800 relative">
                <div class="absolute inset-0 transition-all duration-500 ease-in-out bg-indigo-50"
                     style={"width: #{format_percentage(count, @total_count)}%"}>
                </div>
                <span class="relative z-10 ml-1"><%= count %></span>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp group_by_ranges(line_counts, ranges) when is_map(line_counts) do
    Enum.reduce(ranges, %{}, fn {range, label}, acc ->
      count = Enum.sum(for {lines, count} <- line_counts, lines in range, do: count)
      Map.put(acc, {range, label}, count)
    end)
  end

  defp sort_ranges(data) do
    Enum.sort_by(data, fn
      {{:more, _}, _} -> 999999  # Make sure "X or more" is always last
      {{range, _}, _} -> range.first
    end)
  end

  defp format_percentage(_count, 0), do: 0
  defp format_percentage(count, total) do
    percentage = count / total * 100
    percentage |> Float.round(1)
  end
end
